-- Plekxa Commission, Index, Certificate, Finance & Internal Storage upgrade — September 2026
-- Run AFTER PLEKXA_PLATFORM_ALIGNMENT_SEP_2026.sql, PLEKXA_STUDIO_BUGFIX_SEP_2026.sql and PLEKXA_R2_STORAGE_SEP_2026.sql.
begin;
create extension if not exists pgcrypto;

-- Project commissioning: public pay, timed application windows and multiple commissions.
alter table public.projects add column if not exists title text;
alter table public.projects add column if not exists summary text;
alter table public.projects add column if not exists application_opens_at timestamptz;
alter table public.projects add column if not exists application_closes_at timestamptz;
alter table public.projects add column if not exists commission_slots integer not null default 1;
alter table public.projects add column if not exists pay_amount numeric(14,2);
alter table public.projects add column if not exists pay_currency char(3) default 'GBP';
alter table public.projects add column if not exists pay_notes text;
alter table public.projects add column if not exists index_role text not null default 'niche';
alter table public.projects add column if not exists asset_type text default 'other';
alter table public.projects add column if not exists external_only boolean not null default false;
alter table public.projects add column if not exists default_milestones jsonb not null default '[]'::jsonb;
update public.projects set title=coalesce(title,name) where title is null;

alter table public.creator_project_workspaces alter column contract_id drop not null;
alter table public.creator_project_workspaces alter column creator_id drop not null;
alter table public.creator_project_workspaces add column if not exists application_id uuid;
alter table public.creator_project_workspaces add column if not exists commission_code text;
alter table public.creator_project_workspaces add column if not exists pay_amount numeric(14,2);
alter table public.creator_project_workspaces add column if not exists pay_currency char(3) default 'GBP';
alter table public.creator_project_workspaces add column if not exists payment_schedule jsonb not null default '[]'::jsonb;
alter table public.creator_project_workspaces add column if not exists external_partner_name text;
alter table public.creator_project_workspaces add column if not exists external_partner_email text;
alter table public.creator_project_workspaces add column if not exists managed_internally boolean not null default false;
create unique index if not exists creator_workspace_application_unique on public.creator_project_workspaces(application_id) where application_id is not null;
create unique index if not exists creator_workspace_commission_code_unique on public.creator_project_workspaces(commission_code) where commission_code is not null;

-- Per-commission milestones/deliverables: several accepted people on one project never share private workspaces.
alter table public.project_milestones add column if not exists workspace_id uuid references public.creator_project_workspaces(id) on delete cascade;
alter table public.project_milestones add column if not exists payment_amount numeric(14,2) default 0;
alter table public.project_milestones add column if not exists payment_currency char(3) default 'GBP';
alter table public.project_deliverables add column if not exists workspace_id uuid references public.creator_project_workspaces(id) on delete cascade;
alter table public.project_deliverables add column if not exists review_status text default 'pending';
alter table public.project_deliverables add column if not exists rejected_at timestamptz;
alter table public.project_deliverables add column if not exists rejection_reason text;
alter table public.project_deliverables add column if not exists accepted_asset_id uuid references public.asset_registry(id) on delete set null;

create table if not exists public.commission_messages(
 id uuid primary key default gen_random_uuid(), workspace_id uuid not null references public.creator_project_workspaces(id) on delete cascade,
 sender_user_id uuid references auth.users(id) on delete set null, sender_side text not null check(sender_side in ('creator','enterprise')),
 body text not null, created_at timestamptz not null default now()
);
create index if not exists commission_messages_workspace_idx on public.commission_messages(workspace_id,created_at);

-- Fixed 20-Asset Index economics: 4 flagship @ 8%, 6 supporting @ 6%, 10 niche @ 3.2% = 100%.
alter table public.plekxa_indexes alter column target_asset_count set default 20;
alter table public.plekxa_indexes add column if not exists flagship_capacity integer not null default 4;
alter table public.plekxa_indexes add column if not exists supporting_capacity integer not null default 6;
alter table public.plekxa_indexes add column if not exists niche_capacity integer not null default 10;
alter table public.asset_registry add column if not exists index_participation_percentage numeric(7,4);
alter table public.asset_registry add column if not exists index_assigned_at timestamptz;
alter table public.asset_registry add column if not exists source_workspace_id uuid references public.creator_project_workspaces(id) on delete set null;

create or replace function public.plekxa_role_share(p_role text) returns numeric language sql immutable as $$
 select case lower(trim(coalesce(p_role,''))) when 'flagship' then 8.0000 when 'supporting' then 6.0000 when 'niche' then 3.2000 else null end
$$;

create or replace function public.plekxa_role_capacity(p_role text) returns integer language sql immutable as $$
 select case lower(trim(coalesce(p_role,''))) when 'flagship' then 4 when 'supporting' then 6 when 'niche' then 10 else null end
$$;

create sequence if not exists public.plekxa_index_seq start 1;
create sequence if not exists public.plekxa_certificate_seq start 1;
create sequence if not exists public.plekxa_commission_seq start 1;

create or replace function public.plekxa_assign_asset_to_index(p_asset_id uuid, p_role text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_index uuid; v_capacity int; v_year int:=extract(year from current_date)::int; v_code text; v_count int;
begin
 p_role:=lower(trim(p_role)); v_capacity:=public.plekxa_role_capacity(p_role);
 if v_capacity is null then raise exception 'Index role must be flagship, supporting or niche'; end if;
 perform pg_advisory_xact_lock(20260917);
 select index_id into v_index from public.asset_registry where id=p_asset_id for update;
 if v_index is not null then return v_index; end if;
 select i.id into v_index from public.plekxa_indexes i
 where i.status in ('planning','active') and i.year=v_year
 and (select count(*) from public.asset_registry a where a.index_id=i.id and lower(a.role)=p_role) < v_capacity
 and (select count(*) from public.asset_registry a where a.index_id=i.id) < 20
 order by i.created_at asc limit 1 for update;
 if v_index is null then
   v_code:='IDX-'||v_year||'-'||lpad(nextval('public.plekxa_index_seq')::text,3,'0');
   insert into public.plekxa_indexes(index_code,name,year,target_asset_count,status) values(v_code,'Plekxa Index '||v_code,v_year,20,'active') returning id into v_index;
 end if;
 update public.asset_registry set index_id=v_index,role=p_role,index_participation_percentage=public.plekxa_role_share(p_role),index_assigned_at=now() where id=p_asset_id;
 select count(*) into v_count from public.asset_registry where index_id=v_index;
 if v_count>=20 then update public.plekxa_indexes set status='closed',updated_at=now() where id=v_index; end if;
 return v_index;
end $$;

-- Certificates are per contributor, generated only after an Asset has an Index.
alter table public.index_certificates add column if not exists contributor_id uuid;
alter table public.index_certificates add column if not exists asset_index_percentage numeric(7,4);
alter table public.index_certificates add column if not exists contributor_asset_percentage numeric(7,4);
alter table public.index_certificates add column if not exists effective_index_percentage numeric(9,6);
alter table public.index_certificates add column if not exists issued_at timestamptz;
alter table public.index_certificates add column if not exists pdf_version integer not null default 1;

create or replace function public.plekxa_issue_index_certificates(p_asset_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare a record; c record; n int:=0; v_code text; v_effective numeric;
begin
 select ar.*,i.id iid into a from public.asset_registry ar join public.plekxa_indexes i on i.id=ar.index_id where ar.id=p_asset_id;
 if not found then raise exception 'Asset must be assigned to an Index before certificates are issued'; end if;
 for c in select id,contributor_name,role_name,master_share from public.asset_contributors where asset_id=p_asset_id loop
   v_effective:=coalesce(a.index_participation_percentage,0)*coalesce(c.master_share,0)/100.0;
   v_code:='CERT-'||extract(year from current_date)::int||'-'||lpad(nextval('public.plekxa_certificate_seq')::text,6,'0');
   insert into public.index_certificates(certificate_code,asset_id,index_id,creator_name,creator_role,participation_percentage,effective_inclusion_date,status,issuer,contributor_id,asset_index_percentage,contributor_asset_percentage,effective_index_percentage,issued_at)
   values(v_code,p_asset_id,a.index_id,c.contributor_name,c.role_name,v_effective,current_date,'issued','Plekxa Group Limited',c.id,a.index_participation_percentage,coalesce(c.master_share,0),v_effective,now()); n:=n+1;
 end loop;
 return n;
end $$;

-- Asset revenue ledger and deterministic Index/creator allocations.
create table if not exists public.asset_revenue_entries(
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete restrict,
 period_start date not null, period_end date not null, source text, gross_revenue numeric(14,2) not null default 0,
 distribution_fees numeric(14,2) not null default 0, collection_fees numeric(14,2) not null default 0,
 banking_fees numeric(14,2) not null default 0, transaction_fees numeric(14,2) not null default 0,
 taxes numeric(14,2) not null default 0, direct_third_party_costs numeric(14,2) not null default 0,
 net_distributable numeric(14,2) generated always as (greatest(0,gross_revenue-distribution_fees-collection_fees-banking_fees-transaction_fees-taxes-direct_third_party_costs)) stored,
 currency char(3) not null default 'GBP', status text not null default 'draft', created_at timestamptz not null default now()
);
create table if not exists public.creator_revenue_allocations(
 id uuid primary key default gen_random_uuid(), revenue_entry_id uuid references public.asset_revenue_entries(id) on delete set null,
 period_start date not null, period_end date not null,
 asset_id uuid not null references public.asset_registry(id) on delete restrict, index_id uuid not null references public.plekxa_indexes(id) on delete restrict,
 contributor_id uuid, creator_name text not null, asset_index_percentage numeric(7,4) not null,
 contributor_asset_percentage numeric(7,4) not null, effective_index_percentage numeric(9,6) not null,
 index_period_revenue numeric(14,2) not null, amount numeric(14,2) not null, currency char(3) not null default 'GBP',
 status text not null default 'calculated', paid_at timestamptz, created_at timestamptz not null default now()
);


create unique index if not exists creator_revenue_period_contributor_unique on public.creator_revenue_allocations(index_id,period_start,period_end,currency,contributor_id);
create or replace function public.plekxa_recalculate_index_period(p_index_id uuid,p_start date,p_end date,p_currency char(3))
returns integer language plpgsql security definer set search_path=public as $$
declare v_total numeric:=0; a record; c record; v_amount numeric; n int:=0;
begin
 select coalesce(sum(r.net_distributable),0) into v_total from public.asset_revenue_entries r join public.asset_registry ar on ar.id=r.asset_id where ar.index_id=p_index_id and r.period_start=p_start and r.period_end=p_end and r.currency=p_currency and r.status in ('approved','allocated','paid');
 delete from public.creator_revenue_allocations where index_id=p_index_id and period_start=p_start and period_end=p_end and currency=p_currency and status='calculated';
 for a in select id,index_participation_percentage from public.asset_registry where index_id=p_index_id loop
   for c in select id,contributor_name,master_share from public.asset_contributors where asset_id=a.id loop
     v_amount:=round(v_total*coalesce(a.index_participation_percentage,0)/100.0*coalesce(c.master_share,0)/100.0,2);
     insert into public.creator_revenue_allocations(revenue_entry_id,period_start,period_end,asset_id,index_id,contributor_id,creator_name,asset_index_percentage,contributor_asset_percentage,effective_index_percentage,index_period_revenue,amount,currency,status)
     values(null,p_start,p_end,a.id,p_index_id,c.id,c.contributor_name,a.index_participation_percentage,c.master_share,a.index_participation_percentage*c.master_share/100.0,v_total,v_amount,p_currency,'calculated');
     n:=n+1;
   end loop;
 end loop;
 return n;
end $$;

create or replace function public.plekxa_revenue_recalculate_trigger() returns trigger language plpgsql security definer set search_path=public as $$
declare v_index uuid;
begin
 if new.status in ('approved','allocated','paid') then
   select index_id into v_index from public.asset_registry where id=new.asset_id;
   if v_index is null then raise exception 'Revenue cannot be approved until the Asset is assigned to an Index'; end if;
   perform public.plekxa_recalculate_index_period(v_index,new.period_start,new.period_end,new.currency);
 end if;
 return new;
end $$;
drop trigger if exists trg_plekxa_revenue_recalculate on public.asset_revenue_entries;
create trigger trg_plekxa_revenue_recalculate after insert or update on public.asset_revenue_entries for each row execute function public.plekxa_revenue_recalculate_trigger();

-- Internal operational R2 storage. This is deliberately separate from authoritative Asset masters.
create table if not exists public.internal_files(
 id uuid primary key default gen_random_uuid(), department text not null, category text, title text not null,
 r2_bucket text not null default 'plekxa-internal', r2_key text not null unique, file_name text not null,
 content_type text, size_bytes bigint, uploaded_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(), archived_at timestamptz
);

-- Audit-safe protections.
create unique index if not exists project_files_r2_path_unique on public.project_files(storage_path) where storage_path is not null;
create index if not exists asset_revenue_period_idx on public.asset_revenue_entries(asset_id,period_start,period_end);
create index if not exists internal_files_department_idx on public.internal_files(department,created_at desc);

commit;
notify pgrst, 'reload schema';
