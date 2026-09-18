import {createClient as createAdminClient} from '@supabase/supabase-js';
import {createClient as createSessionClient} from '@/lib/supabase/server';
export async function enterpriseContext(){
 const session=await createSessionClient(); if(!session) throw Object.assign(new Error('Supabase session unavailable.'),{status:503});
 const {data:{user}}=await session.auth.getUser(); if(!user) throw Object.assign(new Error('Not authenticated.'),{status:401});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY; if(!url||!key) throw Object.assign(new Error('Database not configured.'),{status:503});
 const admin=createAdminClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
 const {data:staff}=await admin.from('staff_members').select('id,full_name,email,job_title,department,status').or(`auth_user_id.eq.${user.id}${user.email?`,email.ilike.${user.email}`:''}`).limit(1).maybeSingle();
 if(!staff||String(staff.status).toLowerCase()==='disabled') throw Object.assign(new Error('Enterprise staff access is required.'),{status:403});
 return {admin,user,staff};
}
export async function audit(admin:any,user:any,staff:any,action:string,resourceType:string,resourceId:string|null,metadata:any={}){
 await admin.from('admin_audit_logs').insert({actor_id:user.id,actor_email:user.email||staff?.email||null,actor_name:staff?.full_name||user.user_metadata?.full_name||user.email||'Staff member',action,resource_type:resourceType,resource_id:resourceId,metadata,source:'enterprise_api'});
}
