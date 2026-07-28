-- Plekxa Studio + Enterprise OS identity and communication repair.
-- Run once in the shared Supabase project. It is designed to be rerunnable.
create extension if not exists pgcrypto;

-- Portal profile fields used by Studio.
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade,
  email text,
  full_name text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists professional_name text;
alter table public.profiles add column if not exists creator_type text;
alter table public.profiles add column if not exists bio text;
alter table public.profiles add column if not exists location text;
alter table public.profiles add column if not exists availability text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists portfolio_url text;
alter table public.profiles add column if not exists skills text[] default '{}';
alter table public.profiles add column if not exists genres text[] default '{}';
alter table public.profiles add column if not exists created_at timestamptz default now();
alter table public.profiles add column if not exists updated_at timestamptz default now();

-- Remove duplicate portal rows before adding the identity constraint.
with ranked as (
  select ctid, row_number() over (partition by id order by updated_at desc nulls last, created_at desc nulls last, ctid desc) as rn
  from public.profiles where id is not null
)
delete from public.profiles p using ranked r where p.ctid=r.ctid and r.rn>1;
create unique index if not exists profiles_id_unique on public.profiles(id) where id is not null;

-- Enterprise creator identity fields used by Admin.
alter table public.creator_profiles add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.creator_profiles add column if not exists legal_name text;
alter table public.creator_profiles add column if not exists stage_name text;
alter table public.creator_profiles add column if not exists email text;
alter table public.creator_profiles add column if not exists genres text[] default '{}';
alter table public.creator_profiles add column if not exists skills text[] default '{}';
alter table public.creator_profiles add column if not exists bio text;
alter table public.creator_profiles add column if not exists portfolio_url text;
alter table public.creator_profiles add column if not exists metadata jsonb default '{}';
alter table public.creator_profiles add column if not exists created_at timestamptz default now();
alter table public.creator_profiles add column if not exists updated_at timestamptz default now();

with ranked as (
  select ctid, row_number() over (partition by user_id order by updated_at desc nulls last, created_at desc nulls last, ctid desc) as rn
  from public.creator_profiles where user_id is not null
)
delete from public.creator_profiles p using ranked r where p.ctid=r.ctid and r.rn>1;
create unique index if not exists creator_profiles_user_id_unique on public.creator_profiles(user_id) where user_id is not null;

-- Backfill portal profiles from Auth without overwriting completed profile data.
insert into public.profiles (id,email,full_name,creator_type,created_at,updated_at)
select u.id,u.email,
  coalesce(nullif(u.raw_user_meta_data->>'full_name',''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
  nullif(u.raw_user_meta_data->>'creator_type',''),u.created_at,now()
from auth.users u
where not exists (select 1 from public.profiles p where p.id=u.id);

update public.profiles p set
  email=coalesce(nullif(p.email,''),u.email),
  full_name=coalesce(nullif(p.full_name,''),nullif(u.raw_user_meta_data->>'full_name',''),nullif(u.raw_user_meta_data->>'name',''),split_part(u.email,'@',1)),
  creator_type=coalesce(nullif(p.creator_type,''),nullif(u.raw_user_meta_data->>'creator_type','')),
  updated_at=now()
from auth.users u where p.id=u.id;

-- Backfill Enterprise creator records from the portal profile.
insert into public.creator_profiles(user_id,legal_name,stage_name,email,genres,skills,bio,portfolio_url,metadata,created_at,updated_at)
select p.id,p.full_name,p.professional_name,p.email,coalesce(p.genres,'{}'),coalesce(p.skills,'{}'),p.bio,p.portfolio_url,
 jsonb_strip_nulls(jsonb_build_object('creator_type',p.creator_type,'location',p.location,'availability',p.availability,'avatar_url',p.avatar_url,'source','plekxa-studio')),
 coalesce(p.created_at,now()),now()
from public.profiles p
where p.id is not null and not exists (select 1 from public.creator_profiles c where c.user_id=p.id);

-- Applications retain a submission-time identity snapshot as an additional fallback.
alter table public.creator_applications add column if not exists applicant_name text;
alter table public.creator_applications add column if not exists applicant_email text;
alter table public.creator_applications add column if not exists review_notes text;
alter table public.creator_applications add column if not exists rejection_reason text;
alter table public.creator_applications add column if not exists updated_at timestamptz default now();
update public.creator_applications a set
 applicant_name=coalesce(a.applicant_name,p.full_name,c.legal_name,c.stage_name,u.raw_user_meta_data->>'full_name',u.raw_user_meta_data->>'name'),
 applicant_email=coalesce(a.applicant_email,p.email,c.email,u.email)
from auth.users u
left join public.profiles p on p.id=u.id
left join public.creator_profiles c on c.user_id=u.id
where a.creator_user_id=u.id;

-- Proposals and notifications shared by Studio and Admin.
alter table public.proposals add column if not exists creator_user_id uuid references auth.users(id) on delete cascade;
alter table public.proposals add column if not exists creator_id uuid;
alter table public.proposals add column if not exists title text;
alter table public.proposals add column if not exists summary text;
alter table public.proposals add column if not exists description text;
alter table public.proposals add column if not exists department text;
alter table public.proposals add column if not exists format text;
alter table public.proposals add column if not exists estimated_timeline text;
alter table public.proposals add column if not exists estimated_budget numeric(14,2);
alter table public.proposals add column if not exists portfolio_url text;
alter table public.proposals add column if not exists status text default 'submitted';
alter table public.proposals add column if not exists review_notes text;
alter table public.proposals add column if not exists submitted_at timestamptz;
alter table public.proposals add column if not exists reviewed_at timestamptz;
alter table public.proposals add column if not exists created_at timestamptz default now();
alter table public.proposals add column if not exists updated_at timestamptz default now();

create table if not exists public.notifications(
 id uuid primary key default gen_random_uuid(),
 recipient_id uuid not null references auth.users(id) on delete cascade,
 type text not null default 'general', title text not null, message text not null,
 action_url text, entity_type text, entity_id uuid, metadata jsonb not null default '{}',
 is_read boolean not null default false, read_at timestamptz, created_at timestamptz not null default now()
);
create index if not exists notifications_recipient_idx on public.notifications(recipient_id,is_read,created_at desc);
create index if not exists proposals_creator_user_idx on public.proposals(creator_user_id,created_at desc);
create index if not exists applications_creator_user_idx on public.creator_applications(creator_user_id,applied_at desc);
