-- Plekxa Enterprise OS v3.5.5 — production schema contract repair
begin;

-- Proposals: one vocabulary shared by Studio and Enterprise.
do $$ declare c record; begin
 for c in select conname from pg_constraint where conrelid='public.proposals'::regclass and contype='c' and conname ilike '%status%' loop
  execute format('alter table public.proposals drop constraint %I',c.conname);
 end loop;
end $$;
alter table public.proposals add constraint proposals_status_check check (status in ('draft','submitted','under_review','approved','held','rejected'));
update public.proposals set status='submitted' where status is null;

-- Contracts: creator_id is the Enterprise creator profile id, never auth.users.id.
do $$ declare c record; begin
 for c in select conname from pg_constraint where conrelid='public.contracts'::regclass and contype='f' and conname ilike '%creator%' loop
  execute format('alter table public.contracts drop constraint %I',c.conname);
 end loop;
end $$;
update public.contracts c set creator_id=null where creator_id is not null and not exists(select 1 from public.creator_profiles p where p.id=c.creator_id);
alter table public.contracts add constraint contracts_creator_id_fkey foreign key (creator_id) references public.creator_profiles(id) on delete set null;

-- Audit display identity survives service-role writes and staff account changes.
alter table public.admin_audit_logs add column if not exists actor_email text;
alter table public.admin_audit_logs add column if not exists actor_name text;
alter table public.admin_audit_logs add column if not exists source text not null default 'database';

commit;
notify pgrst, 'reload schema';
