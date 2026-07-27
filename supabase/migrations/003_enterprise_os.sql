-- Plekxa Enterprise OS v1.0 operational schema
create extension if not exists pgcrypto;

create table if not exists public.departments (
 id uuid primary key default gen_random_uuid(), name text not null unique, code text unique,
 lead_user_id uuid references auth.users(id), parent_id uuid references public.departments(id),
 status text not null default 'active', created_at timestamptz not null default now()
);
create table if not exists public.teams (
 id uuid primary key default gen_random_uuid(), name text not null, department_id uuid references public.departments(id),
 lead_user_id uuid references auth.users(id), purpose text, status text not null default 'active', created_at timestamptz not null default now()
);
create table if not exists public.team_members (
 team_id uuid references public.teams(id) on delete cascade, user_id uuid references auth.users(id) on delete cascade,
 role_name text, joined_at timestamptz not null default now(), primary key(team_id,user_id)
);

create table if not exists public.creator_profiles (
 id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id), legal_name text not null,
 stage_name text, email text, phone text, address jsonb not null default '{}', country text, date_of_birth date,
 genres text[] not null default '{}', skills text[] not null default '{}', instruments text[] not null default '{}',
 languages text[] not null default '{}', bio text, portfolio_url text, verification_status text not null default 'pending',
 operational_status text not null default 'active', rating numeric(3,2), metadata jsonb not null default '{}',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.creator_verifications (
 id uuid primary key default gen_random_uuid(), creator_id uuid not null references public.creator_profiles(id) on delete cascade,
 verification_type text not null, document_url text, status text not null default 'pending', reviewed_by uuid references auth.users(id),
 reviewed_at timestamptz, notes text, created_at timestamptz not null default now()
);

create table if not exists public.projects (
 id uuid primary key default gen_random_uuid(), name text not null, slug text unique, project_type text,
 description text, owner_id uuid references auth.users(id), department_id uuid references public.departments(id),
 status text not null default 'planning', priority text not null default 'normal', budget numeric(14,2), currency char(3) default 'USD',
 starts_at date, due_at date, completed_at date, progress integer not null default 0 check(progress between 0 and 100),
 metadata jsonb not null default '{}', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.project_members (
 project_id uuid references public.projects(id) on delete cascade, user_id uuid references auth.users(id) on delete cascade,
 creator_id uuid references public.creator_profiles(id) on delete cascade, role_name text not null, allocation_percent integer,
 joined_at timestamptz not null default now(), primary key(project_id,role_name,user_id,creator_id)
);
create table if not exists public.project_milestones (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 title text not null, description text, owner_id uuid references auth.users(id), due_at date, status text not null default 'not_started',
 position integer not null default 0, completed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.project_deliverables (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 milestone_id uuid references public.project_milestones(id) on delete set null, title text not null, deliverable_type text,
 assignee_user_id uuid references auth.users(id), assignee_creator_id uuid references public.creator_profiles(id),
 status text not null default 'not_started', due_at timestamptz, submitted_at timestamptz, approved_at timestamptz,
 approval_notes text, created_at timestamptz not null default now()
);
create table if not exists public.project_comments (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 author_id uuid references auth.users(id), body text not null, parent_id uuid references public.project_comments(id),
 created_at timestamptz not null default now(), edited_at timestamptz
);
create table if not exists public.project_files (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 deliverable_id uuid references public.project_deliverables(id), file_name text not null, storage_path text not null,
 mime_type text, size_bytes bigint, version integer not null default 1, uploaded_by uuid references auth.users(id), created_at timestamptz not null default now()
);

create table if not exists public.project_opportunities (
 id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade,
 role_name text not null, slots integer not null default 1, requirements jsonb not null default '{}', status text not null default 'draft',
 opens_at timestamptz, closes_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.creator_applications (
 id uuid primary key default gen_random_uuid(), opportunity_id uuid not null references public.project_opportunities(id) on delete cascade,
 creator_id uuid not null references public.creator_profiles(id), answers jsonb not null default '{}', score numeric(5,2),
 status text not null default 'submitted', assigned_reviewer uuid references auth.users(id), submitted_at timestamptz not null default now(),
 decided_at timestamptz, decision_notes text, unique(opportunity_id,creator_id)
);
create table if not exists public.proposals (
 id uuid primary key default gen_random_uuid(), title text not null, proposer_type text, proposer_id uuid,
 category text, summary text, concept jsonb not null default '{}', score numeric(5,2), status text not null default 'draft',
 owner_id uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.contract_templates (
 id uuid primary key default gen_random_uuid(), name text not null, contract_type text not null, version text not null,
 body jsonb not null default '[]', status text not null default 'draft', approved_by uuid references auth.users(id),
 approved_at timestamptz, created_at timestamptz not null default now(), unique(name,version)
);
create table if not exists public.contracts (
 id uuid primary key default gen_random_uuid(), template_id uuid references public.contract_templates(id), project_id uuid references public.projects(id),
 contract_type text not null, title text not null, counterparty_type text not null, counterparty_id uuid,
 status text not null default 'draft', effective_at date, expires_at date, signed_document_url text,
 metadata jsonb not null default '{}', created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.contract_signatories (
 id uuid primary key default gen_random_uuid(), contract_id uuid not null references public.contracts(id) on delete cascade,
 name text not null, email text not null, party_role text, signing_order integer not null default 1,
 status text not null default 'pending', signed_at timestamptz, signature_reference text
);
create table if not exists public.contract_obligations (
 id uuid primary key default gen_random_uuid(), contract_id uuid not null references public.contracts(id) on delete cascade,
 obligation text not null, responsible_party text, due_at date, status text not null default 'open', completed_at timestamptz
);

alter table public.asset_registry add column if not exists project_uuid uuid references public.projects(id);
create table if not exists public.asset_contributors (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 creator_id uuid references public.creator_profiles(id), contributor_name text not null, role_name text not null,
 publishing_share numeric(7,4) default 0, master_share numeric(7,4) default 0, created_at timestamptz not null default now()
);
create table if not exists public.asset_ownership_shares (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 owner_type text not null, owner_id uuid, owner_name text not null, share_percent numeric(7,4) not null,
 share_type text not null, effective_at date not null default current_date, ends_at date, agreement_id uuid references public.contracts(id),
 created_at timestamptz not null default now()
);
create table if not exists public.asset_identifiers (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 identifier_type text not null, identifier_value text not null, territory text, issued_at date, issuer text,
 unique(identifier_type,identifier_value)
);
create table if not exists public.asset_usage (
 id uuid primary key default gen_random_uuid(), asset_id uuid not null references public.asset_registry(id) on delete cascade,
 experience_id uuid references public.experience_records(id), content_item_id uuid references public.content_items(id),
 use_type text not null, share_allocation jsonb not null default '{}', started_at timestamptz not null default now(), ended_at timestamptz,
 notification_sent_at timestamptz, created_at timestamptz not null default now()
);

create table if not exists public.revenue_transactions (
 id uuid primary key default gen_random_uuid(), source text not null, source_reference text, project_id uuid references public.projects(id),
 content_item_id uuid references public.content_items(id), asset_id uuid references public.asset_registry(id),
 gross_amount numeric(14,2) not null, currency char(3) not null default 'USD', transaction_date date not null,
 territory text, metadata jsonb not null default '{}', imported_at timestamptz not null default now()
);
create table if not exists public.payout_batches (
 id uuid primary key default gen_random_uuid(), name text not null, period_start date not null, period_end date not null,
 currency char(3) not null default 'USD', gross_revenue numeric(14,2) not null default 0, distribution_costs numeric(14,2) not null default 0,
 creator_share numeric(14,2) not null default 0, tax_amount numeric(14,2) not null default 0, fees numeric(14,2) not null default 0,
 net_payable numeric(14,2) generated always as (creator_share-tax_amount-fees) stored,
 status text not null default 'draft', submitted_by uuid references auth.users(id), approved_by uuid references auth.users(id),
 approved_at timestamptz, paid_at timestamptz, stripe_reference text, created_at timestamptz not null default now()
);
create table if not exists public.payout_lines (
 id uuid primary key default gen_random_uuid(), batch_id uuid not null references public.payout_batches(id) on delete cascade,
 payee_type text not null, payee_id uuid, payee_name text not null, asset_id uuid references public.asset_registry(id),
 experience_id uuid references public.experience_records(id), gross_share numeric(14,2) not null default 0,
 tax_amount numeric(14,2) not null default 0, fees numeric(14,2) not null default 0,
 net_payable numeric(14,2) generated always as (gross_share-tax_amount-fees) stored, status text not null default 'pending'
);
create table if not exists public.payout_approvals (
 id uuid primary key default gen_random_uuid(), batch_id uuid not null references public.payout_batches(id) on delete cascade,
 approver_id uuid not null references auth.users(id), decision text not null, notes text, decided_at timestamptz not null default now()
);

create table if not exists public.crm_organisations (
 id uuid primary key default gen_random_uuid(), name text not null, organisation_type text not null, website text,
 country text, owner_id uuid references auth.users(id), status text not null default 'lead', metadata jsonb not null default '{}',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.crm_contacts (
 id uuid primary key default gen_random_uuid(), organisation_id uuid references public.crm_organisations(id) on delete set null,
 full_name text not null, email text, phone text, job_title text, relationship_type text,
 owner_id uuid references auth.users(id), status text not null default 'active', created_at timestamptz not null default now()
);
create table if not exists public.crm_opportunities (
 id uuid primary key default gen_random_uuid(), organisation_id uuid references public.crm_organisations(id),
 contact_id uuid references public.crm_contacts(id), name text not null, opportunity_type text, value numeric(14,2), currency char(3) default 'USD',
 stage text not null default 'lead', probability integer default 10, expected_close date, owner_id uuid references auth.users(id),
 next_step text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.crm_activities (
 id uuid primary key default gen_random_uuid(), organisation_id uuid references public.crm_organisations(id), contact_id uuid references public.crm_contacts(id),
 opportunity_id uuid references public.crm_opportunities(id), activity_type text not null, subject text not null, notes text,
 due_at timestamptz, completed_at timestamptz, owner_id uuid references auth.users(id), created_at timestamptz not null default now()
);

create table if not exists public.approval_requests (
 id uuid primary key default gen_random_uuid(), resource_type text not null, resource_id uuid not null, workflow_key text not null,
 requested_by uuid references auth.users(id), status text not null default 'pending', current_step integer not null default 1,
 context jsonb not null default '{}', created_at timestamptz not null default now(), completed_at timestamptz
);
create table if not exists public.approval_decisions (
 id uuid primary key default gen_random_uuid(), request_id uuid not null references public.approval_requests(id) on delete cascade,
 step integer not null, approver_id uuid references auth.users(id), decision text not null, notes text, decided_at timestamptz not null default now()
);

-- Admin read policies. Replace with permission-key policies before production writes.
do $$ declare t text; begin
 foreach t in array array['departments','teams','team_members','creator_profiles','creator_verifications','projects','project_members','project_milestones','project_deliverables','project_comments','project_files','project_opportunities','creator_applications','proposals','contract_templates','contracts','contract_signatories','contract_obligations','asset_contributors','asset_ownership_shares','asset_identifiers','asset_usage','revenue_transactions','payout_batches','payout_lines','payout_approvals','crm_organisations','crm_contacts','crm_opportunities','crm_activities','approval_requests','approval_decisions']
 loop execute format('alter table public.%I enable row level security',t);
      begin execute format('create policy "admin read %s" on public.%I for select using (public.is_admin())',t,t); exception when duplicate_object then null; end;
 end loop;
end $$;

insert into public.departments(name,code,status) values
('Executive','EXEC','active'),('Operations','OPS','active'),('Creator Success','CS','active'),('Audience Experience','AE','active'),
('Production','PROD','active'),('Marketing','MKT','active'),('Finance','FIN','active'),('Legal','LEGAL','active'),('Technology','TECH','active')
on conflict(name) do nothing;
