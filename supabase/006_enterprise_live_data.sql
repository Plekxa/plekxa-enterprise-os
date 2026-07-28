create extension if not exists pgcrypto;
create table if not exists public.enterprise_records(
 id uuid primary key default gen_random_uuid(),
 module text not null,
 status text not null default 'active',
 data jsonb not null default '{}',
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists enterprise_records_module_idx on public.enterprise_records(module,created_at desc);
create index if not exists enterprise_records_status_idx on public.enterprise_records(module,status);
alter table public.projects add column if not exists title text;
alter table public.projects add column if not exists name text;
alter table public.projects add column if not exists type text;
alter table public.projects add column if not exists owner text;
alter table public.projects add column if not exists department text;
alter table public.projects add column if not exists start_date date;
alter table public.projects add column if not exists deadline date;
alter table public.projects add column if not exists budget numeric(14,2);
alter table public.projects add column if not exists objective text;
alter table public.projects add column if not exists status text default 'planning';
alter table public.projects add column if not exists created_at timestamptz default now();
alter table public.projects add column if not exists updated_at timestamptz default now();
update public.projects set title=coalesce(title,name,'Untitled project'),name=coalesce(name,title,'Untitled project') where title is null or name is null;
-- RLS stays enabled for browser safety; Enterprise APIs use the server-only service role.
alter table public.enterprise_records enable row level security;
