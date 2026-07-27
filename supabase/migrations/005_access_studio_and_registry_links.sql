-- Plekxa Enterprise OS v1.6: dynamic access, invitations, Studio ingestion and registry-only experience assets
create table if not exists public.access_roles (
 id uuid primary key default gen_random_uuid(),
 name text not null unique,
 description text,
 permissions jsonb not null default '[]'::jsonb,
 is_system boolean not null default false,
 is_master boolean not null default false,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.staff_members (
 id uuid primary key default gen_random_uuid(),
 auth_user_id uuid unique,
 email text not null unique,
 full_name text not null,
 department text,
 job_title text,
 role_name text not null default 'Viewer',
 status text not null default 'Invited',
 invited_at timestamptz not null default now(),
 accepted_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.experience_assets (
 id uuid primary key default gen_random_uuid(),
 experience_id uuid not null references public.experiences(id) on delete cascade,
 asset_id uuid not null references public.assets(id) on delete restrict,
 routed_ppr numeric(7,4) not null default 0,
 created_at timestamptz not null default now(),
 unique(experience_id,asset_id)
);
create table if not exists public.studio_submissions (
 id uuid primary key default gen_random_uuid(),
 external_id text,
 submission_type text not null,
 title text not null,
 submitter_name text,
 submitter_email text not null,
 creator_profile_id uuid,
 source text not null default 'plekxa-studio',
 status text not null default 'Submitted',
 payload jsonb not null default '{}'::jsonb,
 reviewed_by uuid,
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 unique(source,external_id)
);
create index if not exists studio_submissions_status_idx on public.studio_submissions(status,created_at desc);
create index if not exists experience_assets_experience_idx on public.experience_assets(experience_id);
create or replace function public.enforce_registered_experience_asset() returns trigger language plpgsql as $$
declare asset_status text;
begin
 select status into asset_status from public.assets where id=new.asset_id;
 if asset_status not in ('Approved','Active') then raise exception 'Only Approved or Active registry assets can be added to an experience'; end if;
 return new;
end $$;
drop trigger if exists experience_asset_registry_guard on public.experience_assets;
create trigger experience_asset_registry_guard before insert or update on public.experience_assets for each row execute function public.enforce_registered_experience_asset();
