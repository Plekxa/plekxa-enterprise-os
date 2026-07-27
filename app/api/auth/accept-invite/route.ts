import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';

export async function POST(request:Request){
 try{
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publicKey=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY||process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  const serviceKey=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url||!publicKey||!serviceKey)return NextResponse.json({error:'Supabase environment variables are incomplete.'},{status:503});
  const token=request.headers.get('authorization')?.replace(/^Bearer\s+/i,'');
  if(!token)return NextResponse.json({error:'Missing invitation session.'},{status:401});
  const publicClient=createClient(url,publicKey,{auth:{autoRefreshToken:false,persistSession:false}});
  const {data:{user},error:userError}=await publicClient.auth.getUser(token);
  if(userError||!user?.email)return NextResponse.json({error:'The invitation session is invalid or expired.'},{status:401});
  const admin=createClient(url,serviceKey,{auth:{autoRefreshToken:false,persistSession:false}});
  const email=user.email.trim().toLowerCase();
  const {data:existing,error:lookupError}=await admin.from('staff_members').select('*').or(`auth_user_id.eq.${user.id},email.ilike.${email}`).limit(1).maybeSingle();
  if(lookupError)return NextResponse.json({error:`Unable to locate staff record: ${lookupError.message}`},{status:500});
  if(!existing)return NextResponse.json({error:'No employee record matches this invitation. Ask an administrator to resend it.'},{status:404});
  const now=new Date().toISOString();
  const {data:staff,error}=await admin.from('staff_members').update({auth_user_id:user.id,email,status:'Active',accepted_at:existing.accepted_at||now}).eq('id',existing.id).select().single();
  if(error)return NextResponse.json({error:`Unable to activate staff record: ${error.message}`},{status:500});
  await admin.auth.admin.updateUserById(user.id,{user_metadata:{...user.user_metadata,full_name:staff.full_name,access_role:staff.role_name,department:staff.department,job_title:staff.job_title,staff_status:'Active'}});
  return NextResponse.json({ok:true,staff});
 }catch(error){return NextResponse.json({error:error instanceof Error?error.message:'Unable to activate invitation.'},{status:500})}
}
