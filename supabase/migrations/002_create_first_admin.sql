-- 1. Create the staff user in Supabase Authentication > Users first.
-- 2. Replace the email below, then run this script.
insert into public.admin_staff(user_id,full_name,department,job_title,status)
select id,'Anthony Ighomena','Executive','Founder & CEO','active'
from auth.users where email='REPLACE_WITH_YOUR_EMAIL'
on conflict(user_id) do update set status='active';

insert into public.admin_staff_roles(user_id,role_id)
select u.id,r.id from auth.users u cross join public.admin_roles r
where u.email='REPLACE_WITH_YOUR_EMAIL' and r.name='Super Admin'
on conflict do nothing;

insert into public.admin_role_permissions(role_id,permission_id)
select r.id,p.id from public.admin_roles r cross join public.admin_permissions p
where r.name='Super Admin' on conflict do nothing;
