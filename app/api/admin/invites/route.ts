import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';
export async function POST(request:Request){
 try{
  const {email,name,department,job,access}=await request.json();
  if(!email||!name)return NextResponse.json({error:'Name and email are required'},{status:400});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const serviceKey=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url||!serviceKey)return NextResponse.json({error:'Add NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in Vercel, then redeploy.'},{status:503});
  const s=createClient(url,serviceKey,{auth:{autoRefreshToken:false,persistSession:false}});
  const pending={email:email.trim().toLowerCase(),full_name:name.trim(),department:department||null,job_title:job||null,role_name:access||'Viewer',status:'Invited',invited_at:new Date().toISOString(),accepted_at:null};
  const {data:staff,error:staffError}=await s.from('staff_members').upsert(pending,{onConflict:'email'}).select().single();
  if(staffError)throw staffError;
  const requestOrigin=new URL(request.url).origin;
  const configuredOrigin=(process.env.NEXT_PUBLIC_APP_URL||requestOrigin).replace(/\/$/,'');
  const redirectTo=`${configuredOrigin}/accept-invite`;
  const {data,error}=await s.auth.admin.inviteUserByEmail(pending.email,{redirectTo,data:{full_name:pending.full_name,department:pending.department,job_title:pending.job_title,access_role:pending.role_name,plekxa_invited:true}});
  if(error){return NextResponse.json({error:`The employee was recorded, but Supabase could not send the email: ${error.message}`,staff},{status:502})}
  if(data.user?.id)await s.from('staff_members').update({auth_user_id:data.user.id}).eq('id',staff.id);
  return NextResponse.json({ok:true,staff:{...staff,auth_user_id:data.user?.id}})
 }catch(error){return NextResponse.json({error:error instanceof Error?error.message:'Unable to send invitation'},{status:500})}
}
