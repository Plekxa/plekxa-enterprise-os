-- Plekxa Enterprise OS v3.4.5 — operational audit trail
-- Run once in Supabase SQL Editor.
begin;

alter table public.admin_audit_logs add column if not exists actor_email text;
alter table public.admin_audit_logs add column if not exists actor_name text;
alter table public.admin_audit_logs add column if not exists source text not null default 'database';

create index if not exists admin_audit_logs_created_at_idx on public.admin_audit_logs(created_at desc);
create index if not exists admin_audit_logs_resource_idx on public.admin_audit_logs(resource_type, resource_id);
create index if not exists admin_audit_logs_actor_idx on public.admin_audit_logs(actor_id);

create or replace function public.plekxa_audit_sanitise(v jsonb)
returns jsonb language sql immutable as $$
  select coalesce(v,'{}'::jsonb)
    - 'password' - 'password_hash' - 'token' - 'access_token' - 'refresh_token'
    - 'secret' - 'api_key' - 'service_role_key';
$$;

create or replace function public.plekxa_audit_row_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  oldj jsonb := case when tg_op in ('UPDATE','DELETE') then public.plekxa_audit_sanitise(to_jsonb(old)) else null end;
  newj jsonb := case when tg_op in ('INSERT','UPDATE') then public.plekxa_audit_sanitise(to_jsonb(new)) else null end;
  rid text;
  inferred_actor uuid;
  changed jsonb := '{}'::jsonb;
  k text;
begin
  rid := coalesce(newj->>'id', oldj->>'id', newj->>'internal_identifier', oldj->>'internal_identifier', newj->>'certificate_code', oldj->>'certificate_code');
  begin
    inferred_actor := coalesce(
      auth.uid(),
      nullif(newj->>'updated_by','')::uuid,
      nullif(newj->>'created_by','')::uuid,
      nullif(newj->>'uploaded_by','')::uuid,
      nullif(oldj->>'updated_by','')::uuid,
      nullif(oldj->>'created_by','')::uuid,
      nullif(oldj->>'uploaded_by','')::uuid
    );
  exception when invalid_text_representation then inferred_actor := auth.uid(); end;

  if tg_op='UPDATE' then
    for k in select jsonb_object_keys(newj) loop
      if (oldj->k) is distinct from (newj->k) then
        changed := changed || jsonb_build_object(k,jsonb_build_object('before',oldj->k,'after',newj->k));
      end if;
    end loop;
  end if;

  insert into public.admin_audit_logs(actor_id,action,resource_type,resource_id,metadata,source)
  values(
    inferred_actor,
    case tg_op when 'INSERT' then 'created' when 'UPDATE' then 'updated' else 'deleted' end,
    tg_table_name,
    rid,
    case tg_op
      when 'INSERT' then jsonb_build_object('after',newj)
      when 'UPDATE' then jsonb_build_object('changes',changed)
      else jsonb_build_object('before',oldj)
    end,
    case when auth.uid() is null then 'backend' else 'user' end
  );
  return case when tg_op='DELETE' then old else new end;
end;
$$;

-- Attach only to tables that exist. This makes the migration safe across older Plekxa schemas.
do $$
declare t text;
begin
  foreach t in array array[
    'asset_registry','asset_files','asset_contributors','indexes','index_assets','index_certificates',
    'projects','creator_applications','creator_project_workspaces','project_deliverables','project_files',
    'contracts','asset_revenue_entries','creator_ledger','payments','notifications','proposals',
    'internal_files','profiles','releases','collections','content_items','marketing_campaigns',
    'cms_articles','cms_jobs','cms_pages','cms_homepage_sections','cms_navigation','cms_media',
    'cms_leadership','cms_events','cms_settings','crm_contacts','support_requests','staff_members',
    'access_roles','staff_role_assignments'
  ] loop
    if to_regclass('public.'||t) is not null then
      execute format('drop trigger if exists plekxa_audit_change on public.%I',t);
      execute format('create trigger plekxa_audit_change after insert or update or delete on public.%I for each row execute function public.plekxa_audit_row_change()',t);
    end if;
  end loop;
end $$;

-- Audit records themselves are append-only. No trigger is placed on this table.
create or replace function public.plekxa_block_audit_mutation()
returns trigger language plpgsql as $$ begin raise exception 'Audit log entries are immutable'; end; $$;
drop trigger if exists plekxa_audit_immutable on public.admin_audit_logs;
create trigger plekxa_audit_immutable before update or delete on public.admin_audit_logs
for each row execute function public.plekxa_block_audit_mutation();

commit;
notify pgrst, 'reload schema';
