begin;

-- Project/workspace reference files (beats, samples, briefs, stems, PDFs, etc.).
alter table public.project_files add column if not exists workspace_id uuid references public.creator_project_workspaces(id) on delete cascade;
alter table public.project_files add column if not exists file_role text not null default 'deliverable';
alter table public.project_files add column if not exists creator_visible boolean not null default true;
create index if not exists project_files_workspace_idx on public.project_files(workspace_id,created_at desc);
create index if not exists project_files_project_reference_idx on public.project_files(project_id,file_role,created_at desc);

-- Make creator revenue allocations project into the Creator Studio earnings ledger.
create or replace function public.plekxa_sync_creator_revenue_earning()
returns trigger language plpgsql security definer set search_path=public as $$
declare
  v_profile uuid; v_user uuid; v_asset_title text; v_project uuid; v_status text;
begin
  select ac.creator_id into v_profile from public.asset_contributors ac where ac.id=new.contributor_id;
  if v_profile is null then return new; end if;
  select cp.user_id into v_user from public.creator_profiles cp where cp.id=v_profile;
  if v_user is null then return new; end if;
  select ar.title, ar.project_uuid into v_asset_title,v_project from public.asset_registry ar where ar.id=new.asset_id;
  v_status := case when new.status='paid' then 'paid' when new.status in ('available','approved') then 'available' else 'pending' end;
  insert into public.creator_earnings(creator_id,enterprise_creator_id,source_line_id,project_id,source,project_name,amount,currency,status,earned_at)
  values(v_user,v_profile,new.id,v_project,'Index participation',coalesce(v_asset_title,'Plekxa Asset'),new.amount,new.currency,v_status,coalesce(new.created_at,now()))
  on conflict(source_line_id) do update set amount=excluded.amount,currency=excluded.currency,status=excluded.status,project_name=excluded.project_name;
  return new;
end $$;
drop trigger if exists trg_plekxa_sync_creator_revenue_earning on public.creator_revenue_allocations;
create trigger trg_plekxa_sync_creator_revenue_earning after insert or update on public.creator_revenue_allocations for each row execute function public.plekxa_sync_creator_revenue_earning();

-- Backfill existing allocation rows into Creator Studio.
insert into public.creator_earnings(creator_id,enterprise_creator_id,source_line_id,project_id,source,project_name,amount,currency,status,earned_at)
select cp.user_id,cp.id,cra.id,ar.project_uuid,'Index participation',coalesce(ar.title,'Plekxa Asset'),cra.amount,cra.currency,
 case when cra.status='paid' then 'paid' when cra.status in ('available','approved') then 'available' else 'pending' end,cra.created_at
from public.creator_revenue_allocations cra
join public.asset_contributors ac on ac.id=cra.contributor_id
join public.creator_profiles cp on cp.id=ac.creator_id
join public.asset_registry ar on ar.id=cra.asset_id
where cp.user_id is not null
on conflict(source_line_id) do update set amount=excluded.amount,currency=excluded.currency,status=excluded.status,project_name=excluded.project_name;

notify pgrst, 'reload schema';
commit;
