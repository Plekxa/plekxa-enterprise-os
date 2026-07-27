-- Plekxa Enterprise OS v1.9: invitation activation and analytics report history
create table if not exists public.analytics_reports (
 id uuid primary key default gen_random_uuid(),
 external_id text unique,
 name text not null,
 department text not null,
 format text not null,
 date_range text,
 created_by uuid,
 created_at timestamptz not null default now()
);
create index if not exists analytics_reports_created_at_idx on public.analytics_reports(created_at desc);
create index if not exists analytics_reports_department_idx on public.analytics_reports(department,created_at desc);
