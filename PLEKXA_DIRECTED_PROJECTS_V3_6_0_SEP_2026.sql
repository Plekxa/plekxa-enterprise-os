-- Plekxa v3.6.0 — directed single-Asset projects
-- Run after the last successful production migrations. Do NOT run the superseded v3.5.9 migration separately.
begin;
create extension if not exists pgcrypto;

-- Project-first Asset reservation / genre-mood Index model (idempotent core)
alter table public.projects add column if not exists genre text;
alter table public.projects add column if not exists mood text;
alter table public.projects add column if not exists reserved_asset_id uuid;
alter table public.projects add column if not exists source_proposal_id uuid references public.proposals(id) on delete set null;
alter table public.projects add column if not exists index_id uuid references public.plekxa_indexes(id) on delete set null;
alter table public.projects add column if not exists reserved_asset_code text;
alter table public.projects add column if not exists index_code text;
alter table public.projects add column if not exists director_creator_id uuid references public.creator_profiles(id) on delete set null;
alter table public.projects add column if not exists director_user_id uuid references auth.users(id) on delete set null;
alter table public.projects add column if not exists director_ownership_percent numeric(7,4);
alter table public.projects add column if not exists production_mode text not null default 'open_application';

alter table public.asset_registry add column if not exists genre text;
alter table public.asset_registry add column if not exists mood text;
alter table public.asset_registry add column if not exists project_uuid uuid;
alter table public.asset_registry add column if not exists index_participation_percentage numeric(7,4);
alter table public.asset_registry add column if not exists index_assigned_at timestamptz;

-- A project produces one primary Asset. Existing Collections remain many-Asset groupings.
do $$ begin
 if not exists(select 1 from pg_constraint where conname='projects_reserved_asset_id_fkey') then
  alter table public.projects add constraint projects_reserved_asset_id_fkey foreign key(reserved_asset_id) references public.asset_registry(id) on delete set null;
 end if;
end $$;
create unique index if not exists projects_reserved_asset_unique on public.projects(reserved_asset_id) where reserved_asset_id is not null;

-- Director/contributor workspace metadata.
alter table public.creator_project_workspaces add column if not exists commission_role text not null default 'contributor';
alter table public.creator_project_workspaces add column if not exists director_can_view boolean not null default true;
alter table public.creator_project_workspaces add column if not exists asset_id uuid references public.asset_registry(id) on delete set null;

-- Contributor allocations can be planned before the Asset is completed.
alter table public.asset_contributors add column if not exists allocation_status text not null default 'planned';
alter table public.asset_contributors add column if not exists source_workspace_id uuid references public.creator_project_workspaces(id) on delete set null;
alter table public.asset_contributors add column if not exists updated_at timestamptz not null default now();
create index if not exists asset_contributors_asset_creator_idx on public.asset_contributors(asset_id,creator_id);

-- Reserved is a valid Asset lifecycle state.
do $$ declare c record; begin
 for c in select conname from pg_constraint where conrelid='public.asset_registry'::regclass and contype='c' and pg_get_constraintdef(oid) ilike '%status%' loop
   execute format('alter table public.asset_registry drop constraint %I',c.conname);
 end loop;
end $$;
alter table public.asset_registry add constraint asset_registry_status_check
 check (status in ('reserved','production','draft','pending','rights_review','accepted','approved','active','restricted','published','archived','rejected'));

-- New Index principle: 20 equal Asset positions (5% each), diversified by genre and mood.
alter table public.plekxa_indexes alter column target_asset_count set default 20;
alter table public.plekxa_indexes add column if not exists diversification_model text not null default 'genre_mood';
create sequence if not exists public.plekxa_index_seq start 1;
create sequence if not exists public.plekxa_asset_seq start 1;
do $$ declare n bigint; begin select coalesce(max(nullif(regexp_replace(index_code,'[^0-9]','','g'),'')::bigint % 1000),0) into n from public.plekxa_indexes where year=extract(year from current_date)::int; if n>0 then perform setval('public.plekxa_index_seq',n,true); end if; end $$;

do $$ declare n bigint; begin
 select coalesce(max(nullif(regexp_replace(internal_identifier,'[^0-9]','','g'),'')::bigint),0) into n
 from public.asset_registry where internal_identifier ~ '^AST-[0-9]+$';
 if n>0 then perform setval('public.plekxa_asset_seq',n,true); end if;
end $$;

create or replace function public.plekxa_next_asset_code() returns text language plpgsql security definer set search_path=public as $$
declare v text; begin loop v:='AST-'||lpad(nextval('public.plekxa_asset_seq')::text,6,'0'); exit when not exists(select 1 from public.asset_registry where internal_identifier=v); end loop; return v; end $$;

create or replace function public.plekxa_assign_asset_to_index_v2(p_asset_id uuid,p_genre text default null,p_mood text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_index uuid; v_year int:=extract(year from current_date)::int; v_code text; v_count int;
begin
 perform pg_advisory_xact_lock(20260925);
 select index_id into v_index from public.asset_registry where id=p_asset_id for update;
 if v_index is not null then return v_index; end if;
 select i.id into v_index from public.plekxa_indexes i
 where i.status in ('planning','active') and i.year=v_year and (select count(*) from public.asset_registry a where a.index_id=i.id)<20
 order by (select count(*) from public.asset_registry a where a.index_id=i.id and lower(coalesce(a.genre,''))=lower(coalesce(p_genre,''))),
          (select count(*) from public.asset_registry a where a.index_id=i.id and lower(coalesce(a.mood,''))=lower(coalesce(p_mood,''))),
          (select count(*) from public.asset_registry a where a.index_id=i.id),i.created_at limit 1 for update;
 if v_index is null then
   v_code:='IDX-'||v_year||'-'||lpad(nextval('public.plekxa_index_seq')::text,3,'0');
   insert into public.plekxa_indexes(index_code,name,year,target_asset_count,status,diversification_model)
   values(v_code,'Plekxa Index '||v_code,v_year,20,'active','genre_mood') returning id into v_index;
 end if;
 update public.asset_registry set index_id=v_index,genre=coalesce(p_genre,genre),mood=coalesce(p_mood,mood),role=null,index_participation_percentage=5.0000,index_assigned_at=now() where id=p_asset_id;
 select count(*) into v_count from public.asset_registry where index_id=v_index;
 if v_count>=20 then update public.plekxa_indexes set status='closed',updated_at=now() where id=v_index; end if;
 return v_index;
end $$;

create or replace function public.plekxa_reserve_project_asset(p_project_id uuid)
returns table(asset_id uuid,asset_code text,index_id uuid,index_code text) language plpgsql security definer set search_path=public as $$
declare p record; a_id uuid; a_code text; i_id uuid; i_code text;
begin
 perform pg_advisory_xact_lock(hashtext(p_project_id::text)); select * into p from public.projects where id=p_project_id for update;
 if not found then raise exception 'Project not found'; end if;
 if p.reserved_asset_id is not null then select a.id,a.internal_identifier,a.index_id,i.index_code into a_id,a_code,i_id,i_code from public.asset_registry a left join public.plekxa_indexes i on i.id=a.index_id where a.id=p.reserved_asset_id; return query select a_id,a_code,i_id,i_code; return; end if;
 a_code:=public.plekxa_next_asset_code();
 insert into public.asset_registry(title,description,asset_type,internal_identifier,genre,mood,project_uuid,status)
 values(coalesce(p.title,p.name,'Untitled Plekxa Project'),p.description,coalesce(p.asset_type,'other'),a_code,p.genre,p.mood,p.id,'reserved') returning id into a_id;
 i_id:=public.plekxa_assign_asset_to_index_v2(a_id,p.genre,p.mood); select i.index_code into i_code from public.plekxa_indexes i where i.id=i_id;
 update public.projects set reserved_asset_id=a_id,reserved_asset_code=a_code,index_id=i_id,index_code=i_code,updated_at=now() where id=p.id;
 return query select a_id,a_code,i_id,i_code;
end $$;

-- New equal-position Index model applies to current memberships; historical issued certificates remain audit records.
update public.asset_registry set role=null,index_participation_percentage=5.0000 where index_id is not null;

-- Keep proposal status and creator identity consistent between Studio and Enterprise.
do $$ declare c record; begin
 for c in select conname from pg_constraint where conrelid='public.proposals'::regclass and contype='c' and pg_get_constraintdef(oid) ilike '%status%' loop execute format('alter table public.proposals drop constraint %I',c.conname); end loop;
end $$;
update public.proposals set status=case when status is null then 'submitted' when lower(status) in ('pending','pending_review','awaiting_review','awaiting review') then 'submitted' when lower(status) in ('review','reviewing','in_review','under review') then 'under_review' when lower(status) in ('approve','accepted') then 'approved' when lower(status) in ('hold','on_hold','on hold') then 'held' when lower(status) in ('reject','declined') then 'rejected' when lower(status) in ('draft','submitted','under_review','approved','held','rejected') then lower(status) else 'submitted' end;
alter table public.proposals add constraint proposals_status_check check(status in ('draft','submitted','under_review','approved','held','rejected'));
alter table public.proposals alter column creator_id drop not null;
do $$ declare c record; begin for c in select conname from pg_constraint where conrelid='public.proposals'::regclass and contype='f' and conname ilike '%creator_id%' loop execute format('alter table public.proposals drop constraint %I',c.conname); end loop; end $$;
update public.proposals p set creator_id=cp.id from public.creator_profiles cp where p.creator_id=cp.user_id and not exists(select 1 from public.creator_profiles x where x.id=p.creator_id);
update public.proposals p set creator_id=null where p.creator_id is not null and not exists(select 1 from public.creator_profiles cp where cp.id=p.creator_id);
alter table public.proposals add constraint proposals_creator_id_fkey foreign key(creator_id) references public.creator_profiles(id) on delete set null;

-- Asset ownership cannot exceed 100%. It may remain below 100% during production.
create or replace function public.plekxa_validate_asset_ownership(p_asset_id uuid)
returns numeric language plpgsql security definer set search_path=public as $$
declare total numeric; begin select coalesce(sum(master_share),0) into total from public.asset_contributors where asset_id=p_asset_id and allocation_status<>'removed'; if total>100.0000 then raise exception 'Asset contributor ownership cannot exceed 100%% (current total %%)',total; end if; return total; end $$;

create or replace function public.plekxa_guard_asset_ownership() returns trigger language plpgsql set search_path=public as $$
declare total numeric; begin select coalesce(sum(master_share),0) into total from public.asset_contributors where asset_id=new.asset_id and id<>new.id and allocation_status<>'removed'; if total+coalesce(new.master_share,0)>100.0000 then raise exception 'Asset contributor ownership cannot exceed 100%%'; end if; return new; end $$;
drop trigger if exists asset_master_share_guard on public.asset_contributors;
create trigger asset_master_share_guard before insert or update of master_share,allocation_status on public.asset_contributors for each row execute function public.plekxa_guard_asset_ownership();

-- Keep legacy Index RPC compatible; classification is no longer economic input.
create or replace function public.plekxa_assign_asset_to_index(p_asset_id uuid,p_role text)
returns uuid language plpgsql security definer set search_path=public as $$ declare a record; begin select genre,mood into a from public.asset_registry where id=p_asset_id; return public.plekxa_assign_asset_to_index_v2(p_asset_id,a.genre,a.mood); end $$;

notify pgrst, 'reload schema';
commit;
