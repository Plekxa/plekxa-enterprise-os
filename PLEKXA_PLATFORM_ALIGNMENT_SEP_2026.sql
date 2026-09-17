-- Plekxa September 2026 architecture alignment
-- Additive migration: preserves legacy Experience data while removing it from current product workflows.
begin;
create extension if not exists pgcrypto;

create table if not exists public.plekxa_indexes (
 id uuid primary key default gen_random_uuid(), index_code text not null unique, name text not null,
 year int not null, target_asset_count int not null default 20, notes text,
 status text not null default 'planning', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.plekxa_profiles (
 id uuid primary key default gen_random_uuid(), name text not null, slug text not null unique,
 profile_type text, description text, artwork_url text, status text not null default 'active',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.asset_releases (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete restrict,
 profile_id uuid references public.plekxa_profiles(id) on delete set null, platform text not null,
 platform_identifier text, platform_url text, isrc text, upc text, release_date date,
 status text not null default 'planned', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.collections (
 id uuid primary key default gen_random_uuid(), collection_code text not null unique, title text not null, slug text unique,
 collection_type text not null, profile_id uuid references public.plekxa_profiles(id) on delete set null,
 description text, artwork_url text, status text not null default 'draft',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.collection_assets (
 id uuid primary key default gen_random_uuid(), collection_id uuid not null references public.collections(id) on delete cascade,
 asset_id uuid not null references public.asset_registry(id) on delete restrict, position int not null default 1,
 created_at timestamptz not null default now(), unique(collection_id,asset_id)
);
create table if not exists public.index_certificates (
 id uuid primary key default gen_random_uuid(), certificate_code text not null unique,
 asset_id uuid not null references public.asset_registry(id) on delete restrict,
 index_id uuid not null references public.plekxa_indexes(id) on delete restrict,
 creator_name text not null, creator_role text, participation_percentage numeric(7,4) default 0,
 effective_inclusion_date date, status text not null default 'draft', issuer text default 'Plekxa Group Limited',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.asset_objects (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 object_kind text not null, r2_bucket text not null default 'plekxa-masters', r2_key text not null,
 file_name text not null, content_type text, size_bytes bigint, checksum text, is_authoritative boolean not null default true,
 created_at timestamptz not null default now(), unique(r2_bucket,r2_key)
);

alter table public.asset_registry add column if not exists role text;
alter table public.asset_registry add column if not exists mood text;
alter table public.asset_registry add column if not exists index_id uuid references public.plekxa_indexes(id) on delete set null;
alter table public.asset_registry add column if not exists profile_id uuid references public.plekxa_profiles(id) on delete set null;
alter table public.asset_registry add column if not exists r2_master_prefix text;

insert into public.plekxa_profiles(name,slug,profile_type,status) values
 ('Plekxa Vibe','plekxa-vibe','music','active'),('Plekxa Chill','plekxa-chill','music','active'),
 ('Plekxa Party','plekxa-party','music','active'),('Plekxa Worship','plekxa-worship','music','active')
on conflict(slug) do nothing;

-- Website can read only intentionally published catalogue data.
alter table public.plekxa_profiles enable row level security;
alter table public.asset_releases enable row level security;
alter table public.collections enable row level security;
alter table public.collection_assets enable row level security;
drop policy if exists "public read active plekxa profiles" on public.plekxa_profiles;
create policy "public read active plekxa profiles" on public.plekxa_profiles for select using(status='active');
drop policy if exists "public read live releases" on public.asset_releases;
create policy "public read live releases" on public.asset_releases for select using(status='live');
drop policy if exists "public read published collections" on public.collections;
create policy "public read published collections" on public.collections for select using(status='published');
drop policy if exists "public read published collection assets" on public.collection_assets;
create policy "public read published collection assets" on public.collection_assets for select using(exists(select 1 from public.collections c where c.id=collection_id and c.status='published'));

create or replace view public.public_release_catalogue as
select r.id as release_id, a.id as asset_id, a.title, a.description, a.asset_type,
       a.artwork_url, a.isrc as asset_isrc, a.upc as asset_upc,
       r.platform, r.platform_identifier, r.platform_url, r.release_date,
       p.name as profile_name, p.slug as profile_slug
from public.asset_releases r
join public.asset_registry a on a.id=r.asset_id
left join public.plekxa_profiles p on p.id=r.profile_id
where r.status='live' and lower(coalesce(a.status,'')) in ('approved','active','published');
grant select on public.public_release_catalogue to anon, authenticated;
commit;
notify pgrst, 'reload schema';
