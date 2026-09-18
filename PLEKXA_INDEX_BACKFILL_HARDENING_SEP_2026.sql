begin;

-- v3.4.3: safe legacy Asset backfill + idempotent certificate issuing.
alter table public.asset_registry add column if not exists index_participation_percentage numeric(7,4);
alter table public.asset_registry add column if not exists index_assigned_at timestamptz;

-- Existing Assets remain deliberately unassigned until staff classifies them.
-- Economic percentages are fixed by role: Flagship 8%, Supporting 6%, Niche 3.2%.
create or replace function public.plekxa_role_share(p_role text)
returns numeric language sql immutable as $$
 select case lower(trim(coalesce(p_role,''))) when 'flagship' then 8.0 when 'supporting' then 6.0 when 'niche' then 3.2 else null end
$$;
create or replace function public.plekxa_role_capacity(p_role text)
returns integer language sql immutable as $$
 select case lower(trim(coalesce(p_role,''))) when 'flagship' then 4 when 'supporting' then 6 when 'niche' then 10 else null end
$$;

-- One active certificate per Asset/contributor. Re-running assignment cannot duplicate certificates.
create unique index if not exists index_certificates_asset_contributor_unique
on public.index_certificates(asset_id,contributor_id)
where contributor_id is not null and status='issued';

create or replace function public.plekxa_issue_index_certificates(p_asset_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare a record; c record; n int:=0; v_code text; v_effective numeric;
begin
 select ar.*,i.id iid into a from public.asset_registry ar join public.plekxa_indexes i on i.id=ar.index_id where ar.id=p_asset_id;
 if not found then raise exception 'Asset must be assigned to an Index before certificates are issued'; end if;
 for c in select id,contributor_name,role_name,master_share from public.asset_contributors where asset_id=p_asset_id loop
   if exists(select 1 from public.index_certificates ic where ic.asset_id=p_asset_id and ic.contributor_id=c.id and ic.status='issued') then continue; end if;
   v_effective:=coalesce(a.index_participation_percentage,0)*coalesce(c.master_share,0)/100.0;
   v_code:='CERT-'||extract(year from current_date)::int||'-'||lpad(nextval('public.plekxa_certificate_seq')::text,6,'0');
   insert into public.index_certificates(certificate_code,asset_id,index_id,creator_name,creator_role,participation_percentage,effective_inclusion_date,status,issuer,contributor_id,asset_index_percentage,contributor_asset_percentage,effective_index_percentage,issued_at)
   values(v_code,p_asset_id,a.index_id,c.contributor_name,c.role_name,v_effective,current_date,'issued','Plekxa Group Limited',c.id,a.index_participation_percentage,coalesce(c.master_share,0),v_effective,now()); n:=n+1;
 end loop;
 return n;
end $$;

notify pgrst, 'reload schema';
commit;
