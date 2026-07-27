import {NextResponse} from 'next/server';
import {createClient as createServerClient} from '@/lib/supabase/server';
import {createClient} from '@supabase/supabase-js';
export async function GET(){
 const s=await createServerClient();if(!s)return NextResponse.json({error:'Supabase is not configured'},{status:503});
 const {data:{user},error}=await s.auth.getUser();if(error||!user)return NextResponse.json({error:'Not authenticated'},{status:401});
 let staff=(await s.from('staff_members').select('*').eq('auth_user_id',user.id).maybeSingle()).data;
 if(!staff&&user.email)staff=(await s.from('staff_members').select('*').ilike('email',user.email).maybeSingle()).data;
 // Reconcile accepted invitations that still carry the old Invited status.
 if(staff&&staff.status==='Invited'){
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(url&&key){const admin=createClient(url,key,{auth:{autoRefreshToken:false,persistSession:false}});const {data:activated}=await admin.from('staff_members').update({auth_user_id:user.id,status:'Active',accepted_at:staff.accepted_at||new Date().toISOString()}).eq('id',staff.id).select().single();if(activated)staff=activated;}
 }
 return NextResponse.json({user:{id:user.id,email:user.email,full_name:staff?.full_name||user.user_metadata?.full_name||user.email?.split('@')[0]||'User',role_name:staff?.role_name||user.user_metadata?.access_role||'Viewer',department:staff?.department||user.user_metadata?.department||'',job_title:staff?.job_title||user.user_metadata?.job_title||'',status:staff?.status||'Active',last_sign_in_at:user.last_sign_in_at}})
}
