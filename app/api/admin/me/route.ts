import {NextResponse} from 'next/server';
import {createClient as createServerClient} from '@/lib/supabase/server';
import {createClient} from '@supabase/supabase-js';
export async function GET(){
 const s=await createServerClient();
 if(!s)return NextResponse.json({error:'Supabase is not configured'},{status:503});
 const{data:{user},error}=await s.auth.getUser();
 if(error||!user)return NextResponse.json({error:'Not authenticated'},{status:401});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!url||!key)return NextResponse.json({error:'Admin access is not configured'},{status:503});
 const admin=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
 let staff=(await admin.from('staff_members').select('*').eq('auth_user_id',user.id).maybeSingle()).data;
 if(!staff&&user.email){
  const byEmail=(await admin.from('staff_members').select('*').ilike('email',user.email.trim()).maybeSingle()).data;
  if(byEmail&&(!byEmail.auth_user_id||byEmail.auth_user_id===user.id))staff=byEmail;
 }
 if(!staff)return NextResponse.json({error:'No staff account is linked to this login.'},{status:403});
 if(staff.status==='Invited'||!staff.accepted_at)return NextResponse.json({error:'Invitation activation is required.',code:'INVITE_ACTIVATION_REQUIRED'},{status:403});
 if(staff.status!=='Active')return NextResponse.json({error:`This staff account is ${staff.status}.`},{status:403});
 const roleName=staff.role_name;
 const role=(await admin.from('access_roles').select('permissions,is_master').eq('name',roleName).maybeSingle()).data;
 if(!role)return NextResponse.json({error:'The assigned role is not configured. Contact an administrator.'},{status:403});
 const permissions=Array.isArray(role.permissions)?role.permissions:[];
 const isMaster=Boolean(role.is_master)||roleName.trim().toLowerCase().replace(/[\s_-]+/g,' ')==='super admin';
 return NextResponse.json({user:{id:user.id,email:user.email,full_name:staff.full_name||user.email?.split('@')[0]||'User',role_name:roleName,permissions,is_master:isMaster,department:staff.department||'',job_title:staff.job_title||'',status:staff.status,last_sign_in_at:user.last_sign_in_at}})
}
