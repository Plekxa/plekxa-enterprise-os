-- Plekxa Corporate CMS v3 (additive; preserves existing Studio and Enterprise data)
create extension if not exists pgcrypto;

alter table if exists public.cms_articles add column if not exists cover_image_url text;
alter table if exists public.cms_articles add column if not exists featured boolean not null default false;
alter table if exists public.cms_articles add column if not exists published_at timestamptz;
alter table if exists public.cms_articles add column if not exists seo_title text;
alter table if exists public.cms_articles add column if not exists seo_description text;
alter table if exists public.cms_jobs add column if not exists hero_image_url text;
alter table if exists public.cms_jobs add column if not exists seo_title text;
alter table if exists public.cms_jobs add column if not exists seo_description text;

create table if not exists public.cms_homepage_sections (
 id uuid primary key default gen_random_uuid(), section_key text not null unique, eyebrow text, title text not null,
 subtitle text, body text, image_url text, video_url text, cta_label text, cta_url text,
 secondary_cta_label text, secondary_cta_url text, display_order integer not null default 0,
 status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_pages (
 id uuid primary key default gen_random_uuid(), title text not null, slug text not null unique, template text,
 eyebrow text, headline text, summary text, body text, hero_image_url text, hero_video_url text,
 seo_title text, seo_description text, status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_navigation (
 id uuid primary key default gen_random_uuid(), label text not null, url text not null, location text not null default 'header',
 parent_key text, display_order integer not null default 0, open_new_tab boolean not null default false,
 status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_media (
 id uuid primary key default gen_random_uuid(), title text not null, media_type text not null default 'image', url text not null,
 alt_text text, caption text, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_leadership (
 id uuid primary key default gen_random_uuid(), name text not null, role text not null, bio text, image_url text, linkedin_url text,
 display_order integer not null default 0, status text not null default 'draft', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_events (
 id uuid primary key default gen_random_uuid(), title text not null, slug text unique, summary text, description text, image_url text,
 location text, starts_at timestamptz, ends_at timestamptz, ticket_url text, status text not null default 'draft',
 created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.cms_settings (
 id uuid primary key default gen_random_uuid(), setting_key text not null unique, value text, group_name text,
 description text, status text not null default 'active', created_at timestamptz not null default now(), updated_at timestamptz not null default now());

alter table public.cms_homepage_sections enable row level security;
alter table public.cms_pages enable row level security;
alter table public.cms_navigation enable row level security;
alter table public.cms_media enable row level security;
alter table public.cms_leadership enable row level security;
alter table public.cms_events enable row level security;
alter table public.cms_settings enable row level security;

-- Public visitors can read only published/active website content.
drop policy if exists "public read published homepage" on public.cms_homepage_sections;
create policy "public read published homepage" on public.cms_homepage_sections for select using (status='published');
drop policy if exists "public read published pages" on public.cms_pages;
create policy "public read published pages" on public.cms_pages for select using (status='published');
drop policy if exists "public read published navigation" on public.cms_navigation;
create policy "public read published navigation" on public.cms_navigation for select using (status='published');
drop policy if exists "public read active media" on public.cms_media;
create policy "public read active media" on public.cms_media for select using (status='active');
drop policy if exists "public read published leadership" on public.cms_leadership;
create policy "public read published leadership" on public.cms_leadership for select using (status='published');
drop policy if exists "public read published events" on public.cms_events;
create policy "public read published events" on public.cms_events for select using (status='published');
drop policy if exists "public read active settings" on public.cms_settings;
create policy "public read active settings" on public.cms_settings for select using (status='active');

insert into public.cms_homepage_sections(section_key,eyebrow,title,subtitle,body,cta_label,cta_url,secondary_cta_label,secondary_cta_url,display_order,status)
values
('hero','Plekxa · Entertainment & Media','More life in every moment.','We create entertainment, media and experiences that help people feel more, connect more and get more out of life.',null,'Discover Plekxa','/company','Explore our world','/products',10,'published'),
('purpose','Our ambition','Helping people live their best lives.',null,'Not by telling people how to live—but by creating more reasons to feel alive.','Read our story','/company',null,null,50,'published')
on conflict(section_key) do nothing;

insert into public.cms_settings(setting_key,value,group_name,description,status) values
('company_name','Plekxa','brand','Public company name','active'),
('company_descriptor','Entertainment & Media','brand','Company descriptor','active'),
('contact_email','hello@plekxa.com','contact','General contact email','active'),
('press_email','press@plekxa.com','contact','Press contact email','active'),
('legal_email','legal@plekxa.com','contact','Legal contact email','active'),
('default_seo_title','Plekxa — Entertainment & Media','seo','Default browser and social title','active'),
('default_seo_description','Plekxa creates entertainment, media and experiences that help people get more out of life.','seo','Default search description','active')
on conflict(setting_key) do nothing;
