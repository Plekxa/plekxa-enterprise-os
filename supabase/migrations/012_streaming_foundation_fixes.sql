-- Plekxa Enterprise OS v3.2 targeted fixes for catalogue, contracts, creator delivery review and finance periods
create extension if not exists pgcrypto;

-- Proper experience-to-asset relationship. Do not store comma-separated IDs.
create table if not exists public.experience_assets (
  experience_id uuid not null references public.experiences(id) on delete cascade,
  asset_id uuid not null references public.asset_registry(id) on delete restrict,
  position integer not null default 0 check (position between 0 and 19),
  ownership_share numeric(9,6) not null default 0 check (ownership_share >= 0 and ownership_share <= 100),
  created_at timestamptz not null default now(),
  primary key (experience_id, asset_id)
);
create unique index if not exists experience_assets_position_unique on public.experience_assets(experience_id,position);

alter table if exists public.experiences
  add column if not exists asset_ids uuid[] not null default '{}',
  add column if not exists asset_count integer not null default 0,
  add column if not exists asset_share_percentage numeric(9,6) not null default 0;

-- Store file metadata in Postgres while the binary object lives in Supabase Storage.
create table if not exists public.asset_files (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.asset_registry(id) on delete cascade,
  file_name text not null,
  file_category text not null default 'other' check (file_category in ('master_audio','video','artwork','stems','document','other')),
  storage_path text not null unique,
  public_url text,
  mime_type text,
  size_bytes bigint not null default 0,
  version integer not null default 1,
  created_at timestamptz not null default now()
);
create index if not exists asset_files_asset_idx on public.asset_files(asset_id,created_at desc);

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('asset-media','asset-media',true,1073741824,array[
 'audio/wav','audio/x-wav','audio/mpeg','audio/flac','audio/aiff','audio/x-aiff',
 'video/mp4','video/quicktime','image/jpeg','image/png','image/webp',
 'application/pdf','application/zip','application/x-zip-compressed'
]) on conflict (id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

-- Contracts linked to operational records and a real counterparty.
alter table if exists public.contracts
  add column if not exists contract_number text,
  add column if not exists experience_id uuid references public.experiences(id) on delete set null,
  add column if not exists asset_id uuid references public.asset_registry(id) on delete set null,
  add column if not exists creator_id uuid references public.creator_profiles(id) on delete set null,
  add column if not exists counterparty_name text,
  add column if not exists counterparty_email text,
  add column if not exists currency text default 'GBP',
  add column if not exists total_amount numeric(14,2) default 0,
  add column if not exists notes text;
create unique index if not exists contracts_contract_number_unique on public.contracts(contract_number) where contract_number is not null;

-- Creator deliverable files need a URL that admin and creator workspaces can retrieve.
alter table if exists public.project_files
  add column if not exists public_url text,
  add column if not exists storage_url text;

-- Finance periods are ranges, while accounting_period is retained temporarily for backwards compatibility.
alter table if exists public.revenue_entries
  add column if not exists accounting_period_start date,
  add column if not exists accounting_period_end date;
update public.revenue_entries set accounting_period_start=accounting_period where accounting_period_start is null and accounting_period is not null;
alter table if exists public.revenue_entries drop constraint if exists revenue_entries_period_range_check;
alter table if exists public.revenue_entries add constraint revenue_entries_period_range_check check (
  accounting_period_start is null or accounting_period_end is null or accounting_period_end >= accounting_period_start
);

-- Homepage manager contract used by the corporate website.
alter table if exists public.cms_homepage_sections
  add column if not exists section_key text,
  add column if not exists display_order integer not null default 0,
  add column if not exists status text not null default 'draft',
  add column if not exists updated_at timestamptz not null default now();
create unique index if not exists cms_homepage_sections_section_key_unique on public.cms_homepage_sections(section_key) where section_key is not null;
create index if not exists cms_homepage_sections_public_idx on public.cms_homepage_sections(status,display_order);

-- Guard against more than 20 assets being attached even outside the admin UI.
create or replace function public.enforce_experience_asset_limit()
returns trigger language plpgsql as $$
begin
 if (select count(*) from public.experience_assets where experience_id=new.experience_id) >= 20 then
   raise exception 'An experience can contain no more than 20 assets.';
 end if;
 return new;
end $$;
drop trigger if exists enforce_experience_asset_limit_trigger on public.experience_assets;
create trigger enforce_experience_asset_limit_trigger before insert on public.experience_assets
for each row execute function public.enforce_experience_asset_limit();
