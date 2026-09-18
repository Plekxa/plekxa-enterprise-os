-- Plekxa Enterprise OS v3.4.1 - R2 upload/schema hardening
begin;
create extension if not exists pgcrypto;
create table if not exists public.asset_files (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 file_name text not null, file_category text not null default 'other', storage_path text not null unique, public_url text,
 mime_type text, size_bytes bigint not null default 0, version integer not null default 1, created_at timestamptz not null default now()
);
alter table public.asset_files add column if not exists storage_provider text default 'cloudflare_r2';
alter table public.asset_files add column if not exists r2_bucket text default 'plekxa-masters';
alter table public.asset_files add column if not exists r2_key text;
alter table public.asset_files add column if not exists uploaded_by uuid references auth.users(id) on delete set null;
alter table public.project_files add column if not exists storage_provider text default 'cloudflare_r2';
alter table public.project_files add column if not exists r2_bucket text default 'plekxa-masters';
alter table public.project_files add column if not exists r2_key text;
create table if not exists public.internal_files (id uuid primary key default gen_random_uuid(),department text not null default 'General',category text,title text not null,r2_bucket text not null default 'plekxa-internal',r2_key text not null unique,file_name text not null,content_type text,size_bytes bigint not null default 0,uploaded_by uuid references auth.users(id) on delete set null,created_at timestamptz not null default now(),archived_at timestamptz);
commit;
notify pgrst, 'reload schema';
