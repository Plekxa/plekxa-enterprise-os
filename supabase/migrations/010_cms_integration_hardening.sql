-- Plekxa CMS integration hardening (additive and safe to rerun)
-- Ensures public website content can be read while Enterprise continues to edit through service-role APIs.

-- Existing careers workflow uses "open" while earlier corporate code expected "published".
-- Both are now valid public states; no existing records are rewritten.

-- Add useful indexes for public website reads.
create index if not exists cms_articles_publication_idx on public.cms_articles(status, featured desc, published_at desc, created_at desc);
create index if not exists cms_jobs_publication_idx on public.cms_jobs(status, closes_at, created_at desc);
create index if not exists cms_homepage_status_order_idx on public.cms_homepage_sections(status, display_order);
create index if not exists cms_pages_slug_status_idx on public.cms_pages(slug, status);
create index if not exists cms_navigation_location_order_idx on public.cms_navigation(location, status, display_order);
create index if not exists cms_leadership_status_order_idx on public.cms_leadership(status, display_order);
create index if not exists cms_events_status_start_idx on public.cms_events(status, starts_at);

-- Public read policies for the two pre-existing public-content tables.
alter table if exists public.cms_articles enable row level security;
alter table if exists public.cms_jobs enable row level security;

drop policy if exists "public read published articles" on public.cms_articles;
create policy "public read published articles" on public.cms_articles
for select using (
  status = 'published'
  and coalesce(published_at, scheduled_for, created_at) <= now()
);

drop policy if exists "public read open jobs" on public.cms_jobs;
create policy "public read open jobs" on public.cms_jobs
for select using (
  status in ('open','published')
  and (closes_at is null or closes_at >= now())
);
