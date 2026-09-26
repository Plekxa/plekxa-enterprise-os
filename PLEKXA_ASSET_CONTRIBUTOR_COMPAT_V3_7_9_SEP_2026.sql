-- Plekxa Enterprise OS v3.7.9 — asset contributor compatibility hardening
-- Production currently contains both the legacy contributor_role/ppr_split fields
-- and the canonical role_name/master_share fields. Keep them synchronized while
-- older database objects are still present.
begin;

alter table public.asset_contributors
  alter column contributor_role set default 'Contributor';
alter table public.asset_contributors
  alter column ppr_split set default 0;

update public.asset_contributors
set contributor_role = coalesce(nullif(contributor_role,''), nullif(role_name,''), 'Contributor'),
    role_name = coalesce(nullif(role_name,''), nullif(contributor_role,''), 'Contributor'),
    ppr_split = coalesce(ppr_split, master_share, 0),
    master_share = coalesce(master_share, ppr_split, 0)
where contributor_role is null
   or role_name is null
   or ppr_split is null
   or master_share is null;

create or replace function public.plekxa_sync_asset_contributor_compat()
returns trigger
language plpgsql
as $$
begin
  new.role_name := coalesce(nullif(new.role_name,''), nullif(new.contributor_role,''), 'Contributor');
  new.contributor_role := coalesce(nullif(new.contributor_role,''), new.role_name, 'Contributor');
  new.master_share := coalesce(new.master_share, new.ppr_split, 0);
  new.ppr_split := coalesce(new.ppr_split, new.master_share, 0);
  return new;
end;
$$;

drop trigger if exists plekxa_asset_contributor_compat on public.asset_contributors;
create trigger plekxa_asset_contributor_compat
before insert or update on public.asset_contributors
for each row execute function public.plekxa_sync_asset_contributor_compat();

commit;
