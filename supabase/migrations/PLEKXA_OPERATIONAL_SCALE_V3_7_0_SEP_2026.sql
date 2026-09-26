-- Plekxa Enterprise OS v3.7.0 operational scale migration
-- Additive migration: release scheduling/control owned by Marketing.
begin;

create table if not exists public.asset_release_controls (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null unique references public.asset_registry(id) on delete cascade,
  release_date date,
  profile_id uuid references public.plekxa_profiles(id) on delete set null,
  marketing_status text not null default 'new' check (marketing_status in ('new','scheduled','ready','distributed','live','held')),
  marketing_notes text,
  scheduled_by uuid,
  scheduled_at timestamptz,
  distributed_at timestamptz,
  live_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists asset_release_controls_release_date_idx on public.asset_release_controls(release_date);
create index if not exists asset_release_controls_status_idx on public.asset_release_controls(marketing_status);

-- Seed approved/active Assets without overwriting anything already scheduled.
insert into public.asset_release_controls(asset_id, marketing_status)
select ar.id, 'new'
from public.asset_registry ar
where lower(coalesce(ar.status,'')) in ('approved','active')
on conflict (asset_id) do nothing;

-- Keep new approvals visible to Marketing automatically.
create or replace function public.plekxa_sync_asset_release_control()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if lower(coalesce(new.status,'')) in ('approved','active') then
    insert into public.asset_release_controls(asset_id, marketing_status)
    values(new.id,'new') on conflict(asset_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists plekxa_sync_asset_release_control_trg on public.asset_registry;
create trigger plekxa_sync_asset_release_control_trg
after insert or update of status on public.asset_registry
for each row execute function public.plekxa_sync_asset_release_control();

notify pgrst, 'reload schema';
commit;
