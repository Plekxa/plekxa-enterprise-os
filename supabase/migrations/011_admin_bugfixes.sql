-- Plekxa Enterprise OS targeted fixes
alter table if exists public.asset_registry
  add column if not exists description text,
  add column if not exists iswc text,
  add column if not exists other_identifiers text,
  add column if not exists release_date date,
  add column if not exists artwork_url text,
  add column if not exists contract_confirmed boolean not null default false,
  add column if not exists contributors jsonb not null default '[]'::jsonb;

alter table if exists public.experiences
  add column if not exists description text,
  add column if not exists target_audience text,
  add column if not exists artwork_url text,
  add column if not exists budget numeric,
  add column if not exists director text,
  add column if not exists contributor_pool_percentage numeric not null default 0,
  add column if not exists asset_ids uuid[] not null default '{}',
  add column if not exists asset_count integer not null default 0,
  add column if not exists asset_share_percentage numeric not null default 0;

alter table if exists public.marketing_campaigns
  add column if not exists project_scope text not null default 'experience',
  add column if not exists experience_id uuid references public.experiences(id) on delete set null,
  add column if not exists external_project_name text;

alter table if exists public.notifications
  add column if not exists audience text not null default 'creator';

update public.notifications n
set audience='enterprise'
where exists (
  select 1 from public.staff_members s where s.auth_user_id=n.recipient_id
);

alter table if exists public.crm_contacts
  add column if not exists source text,
  add column if not exists source_record_id uuid,
  add column if not exists message text;

create unique index if not exists crm_contacts_source_record_unique
on public.crm_contacts(source,source_record_id)
where source_record_id is not null;

create or replace function public.sync_support_request_to_crm()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.crm_contacts(full_name,email,phone,relationship_type,status,source,source_record_id,message,created_at)
  values(coalesce(new.name,'Website enquiry'),new.email,new.phone,'website_enquiry','lead','corporate_contact_form',new.id,new.message,coalesce(new.created_at,now()))
  on conflict (source,source_record_id) where source_record_id is not null do update
    set full_name=excluded.full_name,email=excluded.email,phone=excluded.phone,message=excluded.message;
  return new;
end $$;

drop trigger if exists support_requests_to_crm on public.support_requests;
create trigger support_requests_to_crm
after insert or update on public.support_requests
for each row execute function public.sync_support_request_to_crm();
