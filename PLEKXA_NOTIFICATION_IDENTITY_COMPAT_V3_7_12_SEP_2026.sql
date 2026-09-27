-- Plekxa Enterprise OS v3.7.12
-- Compatibility guard for legacy code/functions that pass creator_profiles.id
-- where notifications.recipient_id requires auth.users.id.

create or replace function public.plekxa_normalise_notification_recipient()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  resolved_user_id uuid;
begin
  if new.recipient_id is null then
    return new;
  end if;

  -- Already a canonical auth user id: leave untouched.
  if exists (select 1 from auth.users u where u.id = new.recipient_id) then
    return new;
  end if;

  -- Legacy compatibility: translate creator_profiles.id -> creator_profiles.user_id.
  select cp.user_id
    into resolved_user_id
  from public.creator_profiles cp
  where cp.id = new.recipient_id
    and cp.user_id is not null
  limit 1;

  if resolved_user_id is not null
     and exists (select 1 from auth.users u where u.id = resolved_user_id) then
    new.recipient_id := resolved_user_id;
  end if;

  return new;
end;
$$;

drop trigger if exists plekxa_normalise_notification_recipient on public.notifications;
create trigger plekxa_normalise_notification_recipient
before insert or update of recipient_id on public.notifications
for each row
execute function public.plekxa_normalise_notification_recipient();

-- Repair any existing notification rows that contain a creator profile UUID.
update public.notifications n
set recipient_id = cp.user_id
from public.creator_profiles cp
where n.recipient_id = cp.id
  and cp.user_id is not null
  and exists (select 1 from auth.users u where u.id = cp.user_id);
