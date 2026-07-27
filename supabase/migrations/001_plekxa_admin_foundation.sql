-- Plekxa Admin foundation
-- Run in Supabase SQL Editor after reviewing against your existing schema.
create extension if not exists pgcrypto;

create table if not exists public.admin_roles (
  id uuid primary key default gen_random_uuid(), name text unique not null,
  description text, is_system boolean not null default false, created_at timestamptz not null default now()
);
create table if not exists public.admin_permissions (
  id uuid primary key default gen_random_uuid(), key text unique not null,
  description text, created_at timestamptz not null default now()
);
create table if not exists public.admin_role_permissions (
  role_id uuid references public.admin_roles(id) on delete cascade,
  permission_id uuid references public.admin_permissions(id) on delete cascade,
  primary key(role_id,permission_id)
);
create table if not exists public.admin_staff (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null, department text, job_title text, status text not null default 'active',
  avatar_url text, last_seen_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.admin_staff_roles (
  user_id uuid references public.admin_staff(user_id) on delete cascade,
  role_id uuid references public.admin_roles(id) on delete cascade,
  primary key(user_id,role_id)
);
create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key, actor_id uuid references auth.users(id),
  action text not null, resource_type text not null, resource_id text, metadata jsonb not null default '{}',
  ip_address inet, created_at timestamptz not null default now()
);

create table if not exists public.cms_articles (
  id uuid primary key default gen_random_uuid(), title text not null, slug text unique not null,
  excerpt text, body jsonb not null default '[]', cover_image_url text, category text,
  author_name text, status text not null default 'draft', featured boolean not null default false,
  seo_title text, seo_description text, published_at timestamptz, scheduled_for timestamptz,
  created_by uuid references auth.users(id), updated_by uuid references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.cms_jobs (
  id uuid primary key default gen_random_uuid(), title text not null, slug text unique not null,
  department text, location text, employment_type text, summary text, description jsonb not null default '[]',
  requirements jsonb not null default '[]', status text not null default 'draft', closes_at timestamptz,
  application_url text, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.cms_pages (
  id uuid primary key default gen_random_uuid(), page_key text unique not null, title text,
  content jsonb not null default '{}', seo_title text, seo_description text,
  status text not null default 'draft', published_at timestamptz,
  updated_by uuid references auth.users(id), updated_at timestamptz not null default now()
);
create table if not exists public.legal_documents (
  id uuid primary key default gen_random_uuid(), document_key text not null, title text not null,
  version text not null, effective_at timestamptz, content jsonb not null default '[]',
  status text not null default 'draft', requires_reacceptance boolean not null default false,
  approved_by uuid references auth.users(id), published_at timestamptz, created_at timestamptz not null default now(),
  unique(document_key,version)
);

create table if not exists public.content_items (
  id uuid primary key default gen_random_uuid(), title text not null, slug text unique not null,
  content_type text not null, description text, artwork_url text, media_url text, preview_url text,
  status text not null default 'draft', release_at timestamptz, duration_seconds integer,
  genres text[] not null default '{}', moods text[] not null default '{}', themes text[] not null default '{}',
  metadata jsonb not null default '{}', created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.experience_records (
  id uuid primary key default gen_random_uuid(), title text not null, slug text unique not null,
  description text, format text, status text not null default 'draft', artwork_url text,
  release_at timestamptz, created_by uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.experience_content_items (
  experience_id uuid references public.experience_records(id) on delete cascade,
  content_item_id uuid references public.content_items(id) on delete cascade,
  position integer not null default 0, section text, primary key(experience_id,content_item_id)
);
create table if not exists public.asset_registry (
  id uuid primary key default gen_random_uuid(), title text not null, asset_type text not null,
  project_id uuid, content_item_id uuid references public.content_items(id) on delete set null,
  isrc text, upc text, internal_identifier text unique, master_owner text, composition_ownership jsonb not null default '{}',
  contributors jsonb not null default '[]', territories text[] not null default '{}', rights_start date, rights_end date,
  status text not null default 'draft', restrictions text, metadata jsonb not null default '{}',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table if not exists public.admin_notifications (
  id uuid primary key default gen_random_uuid(), title text not null, body text not null,
  audience_type text not null, audience_filter jsonb not null default '{}', channels text[] not null default '{in_app}',
  status text not null default 'draft', scheduled_for timestamptz, sent_at timestamptz,
  created_by uuid references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.support_ticket_notes (
  id uuid primary key default gen_random_uuid(), support_request_id uuid not null,
  author_id uuid references auth.users(id), body text not null, internal boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.marketing_campaigns (
  id uuid primary key default gen_random_uuid(), name text not null, objective text, owner_id uuid references auth.users(id),
  status text not null default 'draft', starts_at timestamptz, ends_at timestamptz, channels text[] not null default '{}',
  audience jsonb not null default '{}', budget numeric(14,2), metadata jsonb not null default '{}', created_at timestamptz not null default now()
);
create table if not exists public.featured_placements (
  id uuid primary key default gen_random_uuid(), product text not null, surface text not null,
  content_type text not null, content_id uuid, headline text, image_url text, cta_label text, cta_url text,
  position integer not null default 0, starts_at timestamptz, ends_at timestamptz, status text not null default 'draft', created_at timestamptz not null default now()
);

insert into public.admin_roles(name,description,is_system) values
('Super Admin','Complete platform access',true),('Executive','Company-wide oversight and approvals',true),
('Operations Admin','Projects, people and operations',true),('Creator Success','Creator and application management',true),
('Project Manager','Projects, milestones and deliverables',true),('Legal','Contracts and rights',true),
('Finance','Revenue and payouts',true),('Marketing','Campaigns and corporate content',true),
('Editorial','Catalogue and newsroom publishing',true),('Support','Support queue and user assistance',true),
('Technical Admin','System configuration and integrations',true),('Auditor','Read-only governance access',true)
on conflict(name) do nothing;

insert into public.admin_permissions(key,description) values
('admin.access','Access admin application'),('staff.manage','Manage staff and roles'),('projects.manage','Manage projects'),
('applications.review','Review applications'),('proposals.review','Review proposals'),('contracts.manage','Manage contracts'),
('assets.manage','Manage rights and assets'),('content.manage','Manage catalogue content'),('content.publish','Publish content'),
('cms.manage','Manage corporate CMS'),('cms.publish','Publish corporate content'),('support.manage','Manage support requests'),
('notifications.send','Send user notifications'),('finance.view','View finance records'),('finance.approve','Approve remittances'),
('settings.manage','Manage platform settings'),('audit.view','View audit logs') on conflict(key) do nothing;

alter table public.admin_roles enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.admin_role_permissions enable row level security;
alter table public.admin_staff enable row level security;
alter table public.admin_staff_roles enable row level security;
alter table public.admin_audit_logs enable row level security;

create or replace function public.is_admin() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.admin_staff where user_id=auth.uid() and status='active');
$$;

create policy "active staff can read admin staff" on public.admin_staff for select using(public.is_admin());
create policy "active staff can read roles" on public.admin_roles for select using(public.is_admin());
create policy "active staff can read permissions" on public.admin_permissions for select using(public.is_admin());
create policy "active staff can read role assignments" on public.admin_staff_roles for select using(public.is_admin());
create policy "active staff can read role permissions" on public.admin_role_permissions for select using(public.is_admin());
create policy "active staff can read audit logs" on public.admin_audit_logs for select using(public.is_admin());

-- Enable RLS for admin-owned operational tables. Add narrower permission policies before production writes.
do $$ declare t text; begin
  foreach t in array array['cms_articles','cms_jobs','cms_pages','legal_documents','content_items','experience_records','experience_content_items','asset_registry','admin_notifications','support_ticket_notes','marketing_campaigns','featured_placements']
  loop execute format('alter table public.%I enable row level security',t);
       execute format('create policy "admin read %s" on public.%I for select using (public.is_admin())',t,t);
  end loop;
end $$;
