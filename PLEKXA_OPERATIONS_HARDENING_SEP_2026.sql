-- Plekxa Enterprise OS v3.5.4 — contracts, assignments, audit and marketing source library
-- Run once in Supabase SQL Editor before deploying v3.5.4.
begin;

-- Contracts: make the live Enterprise contract editor compatible with older databases.
alter table if exists public.contracts
  add column if not exists contract_number text,
  add column if not exists contract_type text,
  add column if not exists title text,
  add column if not exists asset_id uuid references public.asset_registry(id) on delete set null,
  add column if not exists creator_id uuid references public.creator_profiles(id) on delete set null,
  add column if not exists counterparty_name text,
  add column if not exists counterparty_email text,
  add column if not exists currency text default 'GBP',
  add column if not exists total_amount numeric(14,2) default 0,
  add column if not exists effective_at date,
  add column if not exists expires_at date,
  add column if not exists signed_document_url text,
  add column if not exists content jsonb not null default '{}'::jsonb,
  add column if not exists notes text,
  add column if not exists sent_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();
update public.contracts set contract_type=coalesce(contract_type,'other') where contract_type is null;
update public.contracts set title=coalesce(title,contract_number,'Contract') where title is null;
create unique index if not exists contracts_contract_number_unique on public.contracts(contract_number) where contract_number is not null;

-- Personnel assignments: one reusable model for projects, commissions, assets, releases,
-- campaigns and other operational records.
create table if not exists public.work_assignments (
  id uuid primary key default gen_random_uuid(),
  resource_type text not null,
  resource_id uuid not null,
  staff_id uuid not null references public.staff_members(id) on delete cascade,
  assignment_role text not null default 'team_member',
  is_lead boolean not null default false,
  notes text,
  assigned_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(resource_type,resource_id,staff_id)
);
create index if not exists work_assignments_resource_idx on public.work_assignments(resource_type,resource_id);
create index if not exists work_assignments_staff_idx on public.work_assignments(staff_id);

-- Add the new operational table to the audit trail.
do $$ begin
  if to_regprocedure('public.plekxa_audit_row_change()') is not null then
    drop trigger if exists plekxa_audit_change on public.work_assignments;
    create trigger plekxa_audit_change after insert or update or delete on public.work_assignments
    for each row execute function public.plekxa_audit_row_change();
  end if;
end $$;

commit;
notify pgrst, 'reload schema';
