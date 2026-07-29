-- Ensure the master Super Admin role includes every current Enterprise route.
-- The application also bypasses route-level checks for master roles, so newly added modules cannot lock out Super Admin.
update public.access_roles
set permissions = '["/dashboard","/people","/creators","/applications","/projects","/proposals","/contracts","/assets","/experiences","/content","/website","/pages","/navigation","/media","/leadership","/events","/brand","/newsroom","/marketing","/crm","/careers","/support","/notifications","/finance","/analytics","/activity","/settings","/profile","/search"]'::jsonb,
    is_master = true,
    updated_at = now()
where lower(regexp_replace(trim(name), '[[:space:]_-]+', ' ', 'g')) = 'super admin';
