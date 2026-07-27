-- Plekxa Enterprise OS v1.7: staff/creator lifecycle and invite reliability
alter table public.staff_members add column if not exists updated_at timestamptz not null default now();
create index if not exists staff_members_status_idx on public.staff_members(status,created_at desc);
create index if not exists staff_members_auth_user_idx on public.staff_members(auth_user_id);
create index if not exists creator_profiles_operational_status_idx on public.creator_profiles(operational_status,created_at desc);

create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at=now(); return new; end $$;
drop trigger if exists staff_members_touch_updated_at on public.staff_members;
create trigger staff_members_touch_updated_at before update on public.staff_members for each row execute function public.touch_updated_at();
