-- Plekxa shared identity constraint repair (rerunnable).
-- Fixes ON CONFLICT (user_id) by replacing the old partial index with a
-- full unique index. PostgreSQL unique indexes permit multiple NULL values.

-- Keep the most recently updated row for any accidental duplicate user IDs.
with ranked as (
  select ctid,
         row_number() over (
           partition by user_id
           order by updated_at desc nulls last, created_at desc nulls last, ctid desc
         ) as rn
  from public.creator_profiles
  where user_id is not null
)
delete from public.creator_profiles p
using ranked r
where p.ctid = r.ctid and r.rn > 1;

drop index if exists public.creator_profiles_user_id_unique;
create unique index creator_profiles_user_id_unique
  on public.creator_profiles(user_id);
