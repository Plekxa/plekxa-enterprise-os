-- Plekxa CMS v3.0.3 schema compatibility fix
-- Safe to run more than once. Preserves the original Enterprise cms_pages fields.

create extension if not exists pgcrypto;

-- The Enterprise database may already have cms_pages with page_key/content instead of slug/body.
-- Add the newer website-CMS columns without removing or renaming the original columns.
alter table if exists public.cms_pages add column if not exists slug text;
alter table if exists public.cms_pages add column if not exists template text;
alter table if exists public.cms_pages add column if not exists eyebrow text;
alter table if exists public.cms_pages add column if not exists headline text;
alter table if exists public.cms_pages add column if not exists summary text;
alter table if exists public.cms_pages add column if not exists body text;
alter table if exists public.cms_pages add column if not exists hero_image_url text;
alter table if exists public.cms_pages add column if not exists hero_video_url text;
alter table if exists public.cms_pages add column if not exists created_at timestamptz not null default now();

-- Preserve existing pages by deriving their public slug from page_key.
update public.cms_pages
set slug = regexp_replace(lower(trim(page_key)), '[^a-z0-9]+', '-', 'g')
where slug is null
  and page_key is not null;

-- Remove accidental leading/trailing hyphens from generated slugs.
update public.cms_pages
set slug = trim(both '-' from slug)
where slug is not null;

-- Only enforce uniqueness after existing records have been backfilled.
create unique index if not exists cms_pages_slug_unique_idx
  on public.cms_pages(slug)
  where slug is not null;

-- Helpful public-read indexes.
create index if not exists cms_articles_publication_idx
  on public.cms_articles(status, featured desc, published_at desc, created_at desc);
create index if not exists cms_jobs_publication_idx
  on public.cms_jobs(status, closes_at, created_at desc);
create index if not exists cms_homepage_status_order_idx
  on public.cms_homepage_sections(status, display_order);
create index if not exists cms_pages_slug_status_idx
  on public.cms_pages(slug, status);
create index if not exists cms_navigation_location_order_idx
  on public.cms_navigation(location, status, display_order);
create index if not exists cms_leadership_status_order_idx
  on public.cms_leadership(status, display_order);
create index if not exists cms_events_status_start_idx
  on public.cms_events(status, starts_at);

-- Public read policies for existing public-content tables.
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
