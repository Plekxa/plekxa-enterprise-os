-- Plekxa shared live-data contract. Safe to rerun.
create extension if not exists pgcrypto;

-- One creator profile per auth account.

alter table public.creator_profiles add column if not exists operational_status text default 'active';
alter table public.creator_profiles add column if not exists phone text;
alter table public.creator_profiles add column if not exists country text;
alter table public.creator_profiles add column if not exists date_of_birth date;
alter table public.creator_profiles add column if not exists instruments text[] default '{}';
alter table public.creator_profiles add column if not exists languages text[] default '{}';
alter table public.creator_profiles add column if not exists verification_status text default 'pending';
alter table public.creator_profiles add column if not exists rating numeric(3,2);

with ranked as (
 select ctid,row_number() over(partition by user_id order by coalesce(updated_at,created_at,now()) desc,ctid desc) as rn
 from public.creator_profiles where user_id is not null
)
delete from public.creator_profiles p using ranked r where p.ctid=r.ctid and r.rn>1;
drop index if exists public.creator_profiles_user_id_unique_idx;
create unique index if not exists creator_profiles_user_id_unique_idx on public.creator_profiles(user_id);

-- Durable Enterprise operational records.
create table if not exists public.enterprise_records(
 id uuid primary key default gen_random_uuid(),
 module text not null,
 status text not null default 'active',
 data jsonb not null default '{}'::jsonb,
 created_by uuid references auth.users(id) on delete set null,
 updated_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists enterprise_records_module_created_idx on public.enterprise_records(module,created_at desc);

-- Database-backed access roles.
create table if not exists public.access_roles(
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 description text not null default '',
 permissions text[] not null default '{}',
 system boolean not null default false,
 master boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
insert into public.access_roles(name,description,permissions,system,master)
values
('Master Admin','Full access to every Enterprise OS area',array['/dashboard','/projects','/applications','/proposals','/creators','/people','/contracts','/assets','/experiences','/content','/newsroom','/marketing','/finance','/careers','/support','/crm','/notifications','/analytics','/activity','/settings','/profile','/search'],true,true),
('Administrator','Operational administration access',array['/dashboard','/projects','/applications','/proposals','/creators','/people','/contracts','/assets','/experiences','/content','/newsroom','/marketing','/finance','/careers','/support','/crm','/notifications','/analytics','/activity','/settings','/profile','/search'],true,false),
('Viewer','Read access to core operations',array['/dashboard','/projects','/applications','/proposals','/creators','/notifications','/profile','/search'],true,false)
on conflict(name) do nothing;

-- Creator settings/preferences.
create table if not exists public.creator_settings(
 user_id uuid primary key references auth.users(id) on delete cascade,
 project_opportunities boolean not null default true,
 application_updates boolean not null default true,
 messages boolean not null default true,
 marketing_emails boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);

-- Ensure shared tables and columns required by current pages exist.
create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(), recipient_id uuid references auth.users(id) on delete cascade,
 type text not null default 'general', title text not null, message text not null,
 is_read boolean not null default false, metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);
alter table public.notifications add column if not exists recipient_id uuid references auth.users(id) on delete cascade;
alter table public.notifications add column if not exists type text default 'general';
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists message text;
alter table public.notifications add column if not exists is_read boolean default false;
alter table public.notifications add column if not exists metadata jsonb default '{}'::jsonb;
alter table public.notifications add column if not exists created_at timestamptz default now();
create index if not exists notifications_recipient_created_idx on public.notifications(recipient_id,created_at desc);

alter table public.creator_applications add column if not exists applicant_name text;
alter table public.creator_applications add column if not exists applicant_email text;
alter table public.creator_applications add column if not exists creator_user_id uuid references auth.users(id) on delete cascade;
alter table public.creator_applications add column if not exists review_notes text;
alter table public.creator_applications add column if not exists rejection_reason text;
alter table public.creator_applications add column if not exists reviewed_at timestamptz;
alter table public.creator_applications add column if not exists updated_at timestamptz default now();

-- Backfill identity snapshots from Auth.
update public.creator_applications a set
 applicant_email=coalesce(a.applicant_email,u.email),
 applicant_name=coalesce(nullif(a.applicant_name,''),nullif(u.raw_user_meta_data->>'full_name',''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
 creator_user_id=coalesce(a.creator_user_id,u.id)
from auth.users u
where (a.creator_user_id=u.id or a.creator_id=u.id)
and (a.applicant_email is null or a.applicant_name is null or a.creator_user_id is null);

-- Trigger helper for updated_at.
create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
do $$ begin
 if not exists(select 1 from pg_trigger where tgname='set_enterprise_records_updated_at') then
  create trigger set_enterprise_records_updated_at before update on public.enterprise_records for each row execute function public.set_updated_at();
 end if;
 if not exists(select 1 from pg_trigger where tgname='set_access_roles_updated_at') then
  create trigger set_access_roles_updated_at before update on public.access_roles for each row execute function public.set_updated_at();
 end if;
 if not exists(select 1 from pg_trigger where tgname='set_creator_settings_updated_at') then
  create trigger set_creator_settings_updated_at before update on public.creator_settings for each row execute function public.set_updated_at();
 end if;
end $$;
alter table public.notifications add column if not exists action_url text;
alter table public.notifications add column if not exists entity_type text;
alter table public.notifications add column if not exists entity_id uuid;
