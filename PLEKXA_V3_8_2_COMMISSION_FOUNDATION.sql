-- Plekxa v3.8.2 additive, staging-first migration.
-- Run only after schema review and backup. Does not modify existing rows.
begin;
create table if not exists public.creative_commissions (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(trim(title))>0), description text,
 creative_direction text, starts_on date, ends_on date,
 approved_budget numeric(14,2) not null default 0 check(approved_budget>=0),
 currency text not null default 'GBP', production_target integer not null default 0 check(production_target>=0),
 creator_positions integer not null default 0 check(creator_positions>=0),
 lead_staff_id uuid, status text not null default 'draft' check(status in ('draft','recruiting','active','suspended','completed','closed')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 constraint commission_dates_valid check(ends_on is null or starts_on is null or ends_on>=starts_on)
);
create table if not exists public.creative_commission_castings (
 id uuid primary key default gen_random_uuid(), commission_id uuid not null references public.creative_commissions(id) on delete restrict,
 title text not null, role_name text not null, description text, requirements text,
 positions integer not null default 1 check(positions>0), application_deadline timestamptz,
 status text not null default 'draft' check(status in ('draft','published','closed')),
 created_at timestamptz not null default now(), unique(id,commission_id)
);
create table if not exists public.creative_commission_applications (
 id uuid primary key default gen_random_uuid(), casting_id uuid not null references public.creative_commission_castings(id),
 creator_user_id uuid not null references auth.users(id), creator_profile_id uuid references public.creator_profiles(id),
 statement text, portfolio_url text, status text not null default 'submitted' check(status in ('submitted','review','shortlisted','offered','accepted','rejected','withdrawn')),
 created_at timestamptz not null default now(), unique(casting_id,creator_user_id)
);
create table if not exists public.creative_commission_memberships (
 id uuid primary key default gen_random_uuid(), commission_id uuid not null references public.creative_commissions(id),
 creator_user_id uuid not null references auth.users(id), creator_profile_id uuid not null references public.creator_profiles(id),
 contract_id uuid references public.contracts(id), role_name text not null, starts_on date, ends_on date,
 monthly_compensation numeric(14,2) check(monthly_compensation>=0), currency text not null default 'GBP',
 commitments text, status text not null default 'pending' check(status in ('pending','active','suspended','completed','cancelled')),
 created_at timestamptz not null default now(),
 constraint active_membership_requires_contract check(status<>'active' or contract_id is not null)
);
create table if not exists public.creative_commission_assignments (
 id uuid primary key default gen_random_uuid(), membership_id uuid not null references public.creative_commission_memberships(id),
 project_id uuid references public.projects(id), title text not null, instructions text, due_on date,
 status text not null default 'assigned' check(status in ('assigned','submitted','revision_requested','approved','cancelled')),
 created_at timestamptz not null default now()
);
create table if not exists public.creative_commission_commitments (
 id uuid primary key default gen_random_uuid(), commission_id uuid not null references public.creative_commissions(id),
 amount numeric(14,2) not null check(amount>0), description text not null, created_at timestamptz not null default now()
);
alter table public.projects add column if not exists creative_commission_id uuid references public.creative_commissions(id);
create index if not exists idx_commission_projects on public.projects(creative_commission_id);
create index if not exists idx_commission_castings on public.creative_commission_castings(commission_id,status);
create index if not exists idx_commission_memberships on public.creative_commission_memberships(commission_id,creator_user_id);
-- New tables are private by default. API uses service role after staff auth.
alter table public.creative_commissions enable row level security;
alter table public.creative_commission_castings enable row level security;
alter table public.creative_commission_applications enable row level security;
alter table public.creative_commission_memberships enable row level security;
alter table public.creative_commission_assignments enable row level security;
alter table public.creative_commission_commitments enable row level security;
revoke all on public.creative_commissions,public.creative_commission_castings,public.creative_commission_applications,public.creative_commission_memberships,public.creative_commission_assignments,public.creative_commission_commitments from anon,authenticated;
-- Activation requires a countersigned active contract for the same creator.
create or replace function public.plekxa_validate_commission_membership()
returns trigger language plpgsql security definer set search_path=public as $$
declare c public.contracts%rowtype;
begin
 if new.status='active' then
  select * into c from public.contracts where id=new.contract_id;
  if not found or c.status<>'active' or c.creator_user_id is distinct from new.creator_user_id
     or c.creator_id is distinct from new.creator_profile_id then
   raise exception 'Active membership requires a matching, active signed contract';
  end if;
  if not exists(select 1 from public.contract_signatures where contract_id=c.id and party='creator')
    or not exists(select 1 from public.contract_signatures where contract_id=c.id and party='client') then
   raise exception 'Both signatures are required before commission membership activation';
  end if;
 end if;
 return new;
end $$;
drop trigger if exists validate_commission_membership on public.creative_commission_memberships;
create trigger validate_commission_membership before insert or update on public.creative_commission_memberships
for each row execute function public.plekxa_validate_commission_membership();
-- Financial commitments are serialized and rejected if over budget.
create or replace function public.plekxa_commit_commission_budget(p_commission uuid,p_amount numeric,p_description text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_budget numeric; v_spent numeric; v_id uuid;
begin
 if p_amount is null or p_amount<=0 or nullif(trim(p_description),'') is null then raise exception 'Invalid commitment'; end if;
 select approved_budget into v_budget from public.creative_commissions where id=p_commission for update;
 if not found then raise exception 'Commission not found'; end if;
 select coalesce(sum(amount),0) into v_spent from public.creative_commission_commitments where commission_id=p_commission;
 if v_spent+p_amount>v_budget then raise exception 'Commission budget exceeded'; end if;
 insert into public.creative_commission_commitments(commission_id,amount,description) values(p_commission,p_amount,p_description) returning id into v_id;
 return v_id;
end $$;
revoke all on function public.plekxa_commit_commission_budget(uuid,numeric,text) from public,anon,authenticated;
grant execute on function public.plekxa_commit_commission_budget(uuid,numeric,text) to service_role;
-- Transactional status/workspace update; existing status event/notification triggers still fire.
create or replace function public.plekxa_transition_contract(p_contract uuid,p_status text)
returns public.contracts language plpgsql security definer set search_path=public as $$
declare c public.contracts%rowtype; v_user uuid; v_profile uuid;
begin
 select * into c from public.contracts where id=p_contract for update;
 if not found then raise exception 'Contract not found'; end if;
 if c.status=p_status then return c; end if;
 if not ((c.status='active' and p_status in ('completed','cancelled')) or
         (c.status='completed' and p_status='active')) then
   raise exception 'Unsupported contract transition % to %',c.status,p_status;
 end if;
 v_profile:=c.creator_id;
 v_user:=c.creator_user_id;
 if v_user is null and v_profile is not null then
   select user_id into v_user from public.creator_profiles where id=v_profile;
 end if;
 if p_status='active' and (v_user is null or v_profile is null) then raise exception 'Creator identity is incomplete'; end if;
 update public.contracts set status=p_status,updated_at=now() where id=p_contract returning * into c;
 if p_status='active' then
  insert into public.creator_project_workspaces(contract_id,project_id,creator_id,enterprise_creator_id,application_id,title,status)
  values(c.id,c.project_id,v_user,v_profile,c.application_id,c.project_title,'active')
  on conflict(contract_id) do update set status='active',creator_id=excluded.creator_id,enterprise_creator_id=excluded.enterprise_creator_id;
 elsif p_status in ('completed','cancelled') then
  -- Workspace status values differ across legacy deployments; keep the
  -- existing row until its CHECK constraint is confirmed in staging.
  null;
 end if;
 return c;
end $$;
revoke all on function public.plekxa_transition_contract(uuid,text) from public,anon,authenticated;
grant execute on function public.plekxa_transition_contract(uuid,text) to service_role;
commit;
