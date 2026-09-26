-- Plekxa Project Hub v3.6.3 — production-safe consolidated migration
-- 26 September 2026
-- Replaces the failed/uncommitted v3.6.0/v3.6.1 Project Hub attempts.
-- Run this whole file in Supabase SQL Editor. It is intentionally idempotent.

begin;
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 1. PROJECT = ONE PRIMARY ASSET
-- ---------------------------------------------------------------------------
alter table public.projects add column if not exists title text;
alter table public.projects add column if not exists slug text;
alter table public.projects add column if not exists genre text;
alter table public.projects add column if not exists mood text;
alter table public.projects add column if not exists asset_type text default 'other';
alter table public.projects add column if not exists pay_amount numeric(14,2);
alter table public.projects add column if not exists pay_currency char(3) default 'GBP';
alter table public.projects add column if not exists pay_notes text;
alter table public.projects add column if not exists application_opens_at timestamptz;
alter table public.projects add column if not exists application_closes_at timestamptz;
alter table public.projects add column if not exists commission_slots integer not null default 1;
alter table public.projects add column if not exists production_mode text not null default 'open_application';
alter table public.projects add column if not exists reserved_asset_id uuid;
alter table public.projects add column if not exists reserved_asset_code text;
alter table public.projects add column if not exists index_id uuid;
alter table public.projects add column if not exists index_code text;
alter table public.projects add column if not exists source_proposal_id uuid;
alter table public.projects add column if not exists director_creator_id uuid;
alter table public.projects add column if not exists director_user_id uuid;
alter table public.projects add column if not exists director_ownership_percent numeric(7,4);

update public.projects set title=coalesce(nullif(title,''),name,'Untitled Project') where title is null or title='';
-- Production has previously required slug. Backfill it safely for existing records.
update public.projects
set slug=lower(regexp_replace(coalesce(nullif(title,''),nullif(name,''),'project'),'[^a-zA-Z0-9]+','-','g'))||'-'||substr(id::text,1,8)
where slug is null or btrim(slug)='';

-- Database-level safety: every Project gets a slug even if an older API/client omits it.
create or replace function public.plekxa_projects_ensure_slug()
returns trigger language plpgsql set search_path=public as $$
declare v_base text;
begin
 if new.slug is null or btrim(new.slug)='' then
  v_base:=lower(regexp_replace(coalesce(nullif(new.title,''),nullif(new.name,''),'project'),'[^a-zA-Z0-9]+','-','g'));
  v_base:=trim(both '-' from v_base);
  if v_base='' then v_base:='project'; end if;
  new.slug:=left(v_base,100)||'-'||substr(new.id::text,1,8);
 end if;
 return new;
end $$;
drop trigger if exists projects_ensure_slug on public.projects;
create trigger projects_ensure_slug before insert or update of title,name,slug on public.projects
for each row execute function public.plekxa_projects_ensure_slug();

-- Keep schema-cache aware of the repaired Project shape.
notify pgrst, 'reload schema';

-- Replace only our production-mode check, leaving unrelated Project constraints alone.
alter table public.projects drop constraint if exists projects_production_mode_check;
update public.projects set production_mode='open_application'
where production_mode is null or production_mode not in ('open_application','direct_commission','director_led');
alter table public.projects add constraint projects_production_mode_check
check (production_mode in ('open_application','direct_commission','director_led'));

-- ---------------------------------------------------------------------------
-- 2. EXTENSIBLE PROJECT TYPE / GENRE / MOOD DROPDOWNS
-- ---------------------------------------------------------------------------
create table if not exists public.project_taxonomy_options (
 id uuid primary key default gen_random_uuid(),
 category text not null,
 label text not null,
 value text not null,
 active boolean not null default true,
 sort_order integer not null default 0,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(category,value)
);

insert into public.project_taxonomy_options(category,label,value,sort_order) values
 ('project_type','Song','song',10),
 ('project_type','Film','film',20),
 ('project_type','Video','video',30),
 ('project_type','Spoken Word / Podcast','spoken_word_podcast',40),
 ('project_type','Other','other',90),
 ('genre','R&B','r_b',10),
 ('genre','Pop','pop',20),
 ('genre','Afrobeats','afrobeats',30),
 ('genre','Hip-Hop / Rap','hip_hop_rap',40),
 ('genre','Gospel / Worship','gospel_worship',50),
 ('genre','Electronic','electronic',60),
 ('genre','Alternative','alternative',70),
 ('genre','Other','other',90),
 ('mood','Intimate','intimate',10),
 ('mood','Chill','chill',20),
 ('mood','Energetic','energetic',30),
 ('mood','Romantic','romantic',40),
 ('mood','Reflective','reflective',50),
 ('mood','Celebratory','celebratory',60),
 ('mood','Uplifting','uplifting',70),
 ('mood','Dark','dark',80),
 ('mood','Other','other',90)
on conflict(category,value) do nothing;

-- ---------------------------------------------------------------------------
-- 3. RESERVED ASSET + GENRE/MOOD INDEX MODEL
-- ---------------------------------------------------------------------------
alter table public.asset_registry add column if not exists genre text;
alter table public.asset_registry add column if not exists mood text;
alter table public.asset_registry add column if not exists project_uuid uuid;
alter table public.asset_registry add column if not exists index_participation_percentage numeric(7,4);
alter table public.asset_registry add column if not exists index_assigned_at timestamptz;

-- Add relationships only when they are not already present.
do $$ begin
 if not exists(select 1 from pg_constraint where conname='projects_reserved_asset_id_fkey') then
  alter table public.projects add constraint projects_reserved_asset_id_fkey
   foreign key(reserved_asset_id) references public.asset_registry(id) on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='projects_index_id_fkey') then
  alter table public.projects add constraint projects_index_id_fkey
   foreign key(index_id) references public.plekxa_indexes(id) on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='projects_source_proposal_id_fkey') then
  alter table public.projects add constraint projects_source_proposal_id_fkey
   foreign key(source_proposal_id) references public.proposals(id) on delete set null;
 end if;
 if not exists(select 1 from pg_constraint where conname='projects_director_creator_id_fkey') then
  alter table public.projects add constraint projects_director_creator_id_fkey
   foreign key(director_creator_id) references public.creator_profiles(id) on delete set null;
 end if;
end $$;
create unique index if not exists projects_reserved_asset_unique
 on public.projects(reserved_asset_id) where reserved_asset_id is not null;

-- Preserve the existing Asset status constraint unless it prevents 'reserved'.
do $$ declare c record; d text; begin
 for c in select oid,conname from pg_constraint
          where conrelid='public.asset_registry'::regclass and contype='c'
 loop
  d:=pg_get_constraintdef(c.oid);
  if d ilike '%status%' and d not ilike '%reserved%' then
   execute format('alter table public.asset_registry drop constraint %I',c.conname);
  end if;
 end loop;
end $$;

alter table public.plekxa_indexes alter column target_asset_count set default 20;
alter table public.plekxa_indexes add column if not exists diversification_model text not null default 'genre_mood';
create sequence if not exists public.plekxa_index_seq start 1;
create sequence if not exists public.plekxa_asset_seq start 1;

-- Bring sequences forward without relying on fragile modulo parsing.
do $$ declare n bigint; begin
 select coalesce(max((regexp_match(internal_identifier,'^AST-([0-9]+)$'))[1]::bigint),0)
 into n from public.asset_registry where internal_identifier ~ '^AST-[0-9]+$';
 if n>0 then perform setval('public.plekxa_asset_seq',n,true); end if;
end $$;

create or replace function public.plekxa_next_asset_code()
returns text language plpgsql security definer set search_path=public as $$
declare v text;
begin
 loop
  v:='AST-'||lpad(nextval('public.plekxa_asset_seq')::text,6,'0');
  exit when not exists(select 1 from public.asset_registry ar where ar.internal_identifier=v);
 end loop;
 return v;
end $$;

create or replace function public.plekxa_assign_asset_to_index_v2(
 p_asset_id uuid,p_genre text default null,p_mood text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare
 v_index uuid; v_year int:=extract(year from current_date)::int;
 v_code text; v_count int; v_seq bigint;
begin
 perform pg_advisory_xact_lock(20260925);
 select ar.index_id into v_index from public.asset_registry ar where ar.id=p_asset_id for update;
 if v_index is not null then return v_index; end if;

 select i.id into v_index
 from public.plekxa_indexes i
 where i.status in ('planning','active') and i.year=v_year
   and (select count(*) from public.asset_registry ar where ar.index_id=i.id)<20
 order by
   (select count(*) from public.asset_registry ar where ar.index_id=i.id and lower(coalesce(ar.genre,''))=lower(coalesce(p_genre,''))),
   (select count(*) from public.asset_registry ar where ar.index_id=i.id and lower(coalesce(ar.mood,''))=lower(coalesce(p_mood,''))),
   (select count(*) from public.asset_registry ar where ar.index_id=i.id),
   i.created_at
 limit 1 for update;

 if v_index is null then
  v_seq:=nextval('public.plekxa_index_seq');
  loop
   v_code:='IDX-'||v_year||'-'||lpad(v_seq::text,3,'0');
   exit when not exists(select 1 from public.plekxa_indexes i where i.index_code=v_code);
   v_seq:=nextval('public.plekxa_index_seq');
  end loop;
  insert into public.plekxa_indexes(index_code,name,year,target_asset_count,status,diversification_model)
  values(v_code,'Plekxa Index '||v_code,v_year,20,'active','genre_mood') returning id into v_index;
 end if;

 update public.asset_registry
 set index_id=v_index,genre=coalesce(p_genre,genre),mood=coalesce(p_mood,mood),
     role=null,index_participation_percentage=5.0000,index_assigned_at=now()
 where id=p_asset_id;

 select count(*) into v_count from public.asset_registry ar where ar.index_id=v_index;
 if v_count>=20 then
  update public.plekxa_indexes set status='closed',updated_at=now() where id=v_index;
 end if;
 return v_index;
end $$;

create or replace function public.plekxa_reserve_project_asset(p_project_id uuid)
returns table(asset_id uuid,asset_code text,index_id uuid,index_code text)
language plpgsql security definer set search_path=public as $$
declare
 p record; v_asset_id uuid; v_asset_code text; v_index_id uuid; v_index_code text;
begin
 perform pg_advisory_xact_lock(hashtext(p_project_id::text));
 select pr.* into p from public.projects pr where pr.id=p_project_id for update;
 if not found then raise exception 'Project not found'; end if;

 if p.reserved_asset_id is not null then
  select ar.id,ar.internal_identifier,ar.index_id,pi.index_code
  into v_asset_id,v_asset_code,v_index_id,v_index_code
  from public.asset_registry ar
  left join public.plekxa_indexes pi on pi.id=ar.index_id
  where ar.id=p.reserved_asset_id;
 else
  v_asset_code:=public.plekxa_next_asset_code();
  insert into public.asset_registry(title,description,asset_type,internal_identifier,genre,mood,project_uuid,status)
  values(coalesce(nullif(p.title,''),nullif(p.name,''),'Untitled Plekxa Project'),p.description,
         coalesce(p.asset_type,'other'),v_asset_code,p.genre,p.mood,p.id,'reserved')
  returning id into v_asset_id;
  v_index_id:=public.plekxa_assign_asset_to_index_v2(v_asset_id,p.genre,p.mood);
  select pi.index_code into v_index_code from public.plekxa_indexes pi where pi.id=v_index_id;
  update public.projects
  set reserved_asset_id=v_asset_id,reserved_asset_code=v_asset_code,index_id=v_index_id,index_code=v_index_code,updated_at=now()
  where id=p.id;
 end if;

 asset_id:=v_asset_id; asset_code:=v_asset_code; index_id:=v_index_id; index_code:=v_index_code;
 return next;
end $$;

create or replace function public.plekxa_assign_asset_to_index(p_asset_id uuid,p_role text)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_genre text; v_mood text;
begin
 select ar.genre,ar.mood into v_genre,v_mood from public.asset_registry ar where ar.id=p_asset_id;
 return public.plekxa_assign_asset_to_index_v2(p_asset_id,v_genre,v_mood);
end $$;

update public.asset_registry set role=null,index_participation_percentage=5.0000
where index_id is not null;

-- ---------------------------------------------------------------------------
-- 4. DIRECTOR + PRIVATE COMMISSION WORKSPACES
-- ---------------------------------------------------------------------------
alter table public.creator_project_workspaces alter column contract_id drop not null;
alter table public.creator_project_workspaces alter column creator_id drop not null;
alter table public.creator_project_workspaces add column if not exists enterprise_creator_id uuid;
alter table public.creator_project_workspaces add column if not exists application_id uuid;
alter table public.creator_project_workspaces add column if not exists commission_code text;
alter table public.creator_project_workspaces add column if not exists pay_amount numeric(14,2);
alter table public.creator_project_workspaces add column if not exists pay_currency char(3) default 'GBP';
alter table public.creator_project_workspaces add column if not exists payment_schedule jsonb not null default '[]'::jsonb;
alter table public.creator_project_workspaces add column if not exists external_partner_name text;
alter table public.creator_project_workspaces add column if not exists external_partner_email text;
alter table public.creator_project_workspaces add column if not exists managed_internally boolean not null default false;
alter table public.creator_project_workspaces add column if not exists commission_role text not null default 'contributor';
alter table public.creator_project_workspaces add column if not exists director_can_view boolean not null default true;
alter table public.creator_project_workspaces add column if not exists asset_id uuid;
create unique index if not exists creator_workspace_application_unique
 on public.creator_project_workspaces(application_id) where application_id is not null;
create unique index if not exists creator_workspace_commission_code_unique
 on public.creator_project_workspaces(commission_code) where commission_code is not null;

-- ---------------------------------------------------------------------------
-- 5. CANONICAL ASSET CONTRIBUTORS — tolerate the older PPR table shape
-- ---------------------------------------------------------------------------
alter table public.asset_contributors add column if not exists role_name text;
alter table public.asset_contributors add column if not exists publishing_share numeric(7,4) default 0;
alter table public.asset_contributors add column if not exists master_share numeric(7,4) default 0;
alter table public.asset_contributors add column if not exists allocation_status text not null default 'planned';
alter table public.asset_contributors add column if not exists source_workspace_id uuid;
alter table public.asset_contributors add column if not exists updated_at timestamptz not null default now();

-- Backfill legacy names/splits only if those columns actually exist.
do $$ begin
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='asset_contributors' and column_name='contributor_role') then
  execute 'update public.asset_contributors set role_name=coalesce(role_name,contributor_role) where role_name is null';
 end if;
 if exists(select 1 from information_schema.columns where table_schema='public' and table_name='asset_contributors' and column_name='ppr_split') then
  execute 'update public.asset_contributors set master_share=coalesce(nullif(master_share,0),ppr_split) where coalesce(master_share,0)=0';
 end if;
end $$;
update public.asset_contributors set role_name='Contributor' where role_name is null or btrim(role_name)='';

-- Older installs may have asset_id pointing at the retired public.assets table.
-- Replace that FK with a NOT VALID Asset Registry FK: new rows are protected while legacy rows remain readable.
do $$ declare c record; begin
 for c in
  select conname from pg_constraint pc
  join pg_attribute pa on pa.attrelid=pc.conrelid and pa.attnum=any(pc.conkey)
  where pc.conrelid='public.asset_contributors'::regclass and pc.contype='f' and pa.attname='asset_id'
 loop execute format('alter table public.asset_contributors drop constraint %I',c.conname); end loop;
 if not exists(select 1 from pg_constraint where conname='asset_contributors_asset_registry_fkey') then
  alter table public.asset_contributors add constraint asset_contributors_asset_registry_fkey
   foreign key(asset_id) references public.asset_registry(id) on delete cascade not valid;
 end if;
end $$;
create index if not exists asset_contributors_asset_creator_idx on public.asset_contributors(asset_id,creator_id);

create or replace function public.plekxa_validate_asset_ownership(p_asset_id uuid)
returns numeric language plpgsql security definer set search_path=public as $$
declare v_total numeric;
begin
 select coalesce(sum(ac.master_share),0) into v_total
 from public.asset_contributors ac
 where ac.asset_id=p_asset_id and coalesce(ac.allocation_status,'planned')<>'removed';
 if v_total>100.0000 then
  raise exception 'Asset contributor ownership cannot exceed 100%%. Current total: %',v_total;
 end if;
 return v_total;
end $$;

create or replace function public.plekxa_guard_asset_ownership()
returns trigger language plpgsql set search_path=public as $$
declare v_total numeric;
begin
 if coalesce(new.allocation_status,'planned')='removed' then return new; end if;
 select coalesce(sum(ac.master_share),0) into v_total
 from public.asset_contributors ac
 where ac.asset_id=new.asset_id and ac.id<>new.id and coalesce(ac.allocation_status,'planned')<>'removed';
 if v_total+coalesce(new.master_share,0)>100.0000 then
  raise exception 'Asset contributor ownership cannot exceed 100%%.';
 end if;
 return new;
end $$;
drop trigger if exists asset_master_share_guard on public.asset_contributors;
create trigger asset_master_share_guard
before insert or update of master_share,allocation_status on public.asset_contributors
for each row execute function public.plekxa_guard_asset_ownership();

-- ---------------------------------------------------------------------------
-- 6. PROJECT-HUB MILESTONES / DELIVERABLES / PRIVATE REFERENCE FILES
-- ---------------------------------------------------------------------------
alter table public.project_milestones add column if not exists workspace_id uuid;
alter table public.project_milestones add column if not exists payment_amount numeric(14,2) default 0;
alter table public.project_milestones add column if not exists payment_currency char(3) default 'GBP';
alter table public.project_deliverables add column if not exists workspace_id uuid;
alter table public.project_deliverables add column if not exists review_status text default 'pending';
alter table public.project_deliverables add column if not exists rejected_at timestamptz;
alter table public.project_deliverables add column if not exists rejection_reason text;
alter table public.project_deliverables add column if not exists accepted_asset_id uuid;
alter table public.project_deliverables add column if not exists approval_notes text;
alter table public.project_deliverables add column if not exists assignee_user_id uuid;
alter table public.project_deliverables add column if not exists submitted_at timestamptz;

alter table public.project_files add column if not exists workspace_id uuid;
alter table public.project_files add column if not exists file_role text;
alter table public.project_files add column if not exists creator_visible boolean not null default false;
alter table public.project_files add column if not exists r2_bucket text;
alter table public.project_files add column if not exists r2_key text;
alter table public.project_files add column if not exists storage_provider text;
alter table public.project_files add column if not exists mime_type text;
alter table public.project_files add column if not exists size_bytes bigint;
alter table public.project_files add column if not exists version integer not null default 1;
update public.project_files set creator_visible=false where creator_visible is null;

-- ---------------------------------------------------------------------------
-- 7. PROPOSAL IDENTITY / STATUS COMPATIBILITY
-- ---------------------------------------------------------------------------
alter table public.proposals alter column creator_id drop not null;
do $$ declare c record; begin
 for c in select conname from pg_constraint
  where conrelid='public.proposals'::regclass and contype='c' and pg_get_constraintdef(oid) ilike '%status%'
 loop execute format('alter table public.proposals drop constraint %I',c.conname); end loop;
end $$;
update public.proposals set status=case
 when status is null then 'submitted'
 when lower(status) in ('pending','pending_review','awaiting_review','awaiting review') then 'submitted'
 when lower(status) in ('review','reviewing','in_review','under review') then 'under_review'
 when lower(status) in ('approve','accepted') then 'approved'
 when lower(status) in ('hold','on_hold','on hold') then 'held'
 when lower(status) in ('reject','declined') then 'rejected'
 when lower(status) in ('draft','submitted','under_review','approved','held','rejected') then lower(status)
 else 'submitted' end;
alter table public.proposals add constraint proposals_status_check
 check(status in ('draft','submitted','under_review','approved','held','rejected'));

-- Repair creator FK only when creator_profiles is the intended target.
do $$ declare c record; begin
 for c in select conname from pg_constraint
  where conrelid='public.proposals'::regclass and contype='f' and conname ilike '%creator_id%'
 loop execute format('alter table public.proposals drop constraint %I',c.conname); end loop;
 update public.proposals p set creator_id=cp.id
 from public.creator_profiles cp
 where p.creator_id=cp.user_id
   and not exists(select 1 from public.creator_profiles x where x.id=p.creator_id);
 update public.proposals p set creator_id=null
 where p.creator_id is not null
   and not exists(select 1 from public.creator_profiles cp where cp.id=p.creator_id);
 alter table public.proposals add constraint proposals_creator_id_fkey
  foreign key(creator_id) references public.creator_profiles(id) on delete set null;
end $$;

notify pgrst, 'reload schema';
commit;
