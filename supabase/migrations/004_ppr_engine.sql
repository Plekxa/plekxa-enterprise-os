-- Plekxa Enterprise OS v1.5: Experience, asset and participation-rights engine
create table if not exists public.experiences (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  experience_type text not null,
  target_audience text,
  release_date date,
  description text,
  creative_director_id uuid,
  creator_ppr numeric(5,2) not null default 0 check (creator_ppr between 0 and 100),
  status text not null default 'Draft',
  created_at timestamptz not null default now()
);
create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid references public.experiences(id) on delete set null,
  title text not null,
  asset_type text not null,
  identifier text,
  release_date date,
  theme_description text,
  status text not null default 'Draft',
  created_at timestamptz not null default now()
);
create table if not exists public.asset_contributors (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets(id) on delete cascade,
  creator_id uuid,
  contributor_name text not null,
  contributor_role text not null,
  ppr_split numeric(5,2) not null check (ppr_split between 0 and 100),
  created_at timestamptz not null default now()
);
create table if not exists public.revenue_entries (
  id uuid primary key default gen_random_uuid(),
  experience_id uuid not null references public.experiences(id),
  accounting_period date not null,
  gross_revenue numeric(14,2) not null default 0,
  distribution_cost numeric(14,2) not null default 0,
  tax_withheld numeric(14,2) not null default 0,
  platform_fees numeric(14,2) not null default 0,
  net_distributable numeric(14,2) not null default 0,
  creator_pool numeric(14,2) not null default 0,
  company_pool numeric(14,2) not null default 0,
  status text not null default 'Approved',
  created_at timestamptz not null default now()
);
create table if not exists public.contributor_payout_lines (
  id uuid primary key default gen_random_uuid(),
  revenue_entry_id uuid not null references public.revenue_entries(id) on delete cascade,
  asset_id uuid not null references public.assets(id),
  asset_contributor_id uuid not null references public.asset_contributors(id),
  asset_pool numeric(14,2) not null,
  contributor_split numeric(5,2) not null,
  gross_payable numeric(14,2) not null,
  status text not null default 'Calculated',
  created_at timestamptz not null default now()
);
create or replace function public.validate_asset_contributor_split()
returns trigger language plpgsql as $$
declare total numeric;
begin
 select coalesce(sum(ppr_split),0) into total from public.asset_contributors where asset_id = new.asset_id and id <> new.id;
 if total + new.ppr_split > 100 then raise exception 'Asset contributor PPR cannot exceed 100%%'; end if;
 return new;
end $$;
drop trigger if exists asset_contributor_split_guard on public.asset_contributors;
create trigger asset_contributor_split_guard before insert or update on public.asset_contributors for each row execute function public.validate_asset_contributor_split();
