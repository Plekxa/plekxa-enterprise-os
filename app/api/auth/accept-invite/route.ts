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
  const now=new Date().toISOString();
  const {data:staff,error}=await admin.from('staff_members').update({auth_user_id:user.id,status:'Active',accepted_at:now}).eq('email',user.email.toLowerCase()).select().single();
  if(error)return NextResponse.json({error:`Unable to activate staff record: ${error.message}`},{status:500});
  return NextResponse.json({ok:true,staff});
 }catch(error){return NextResponse.json({error:error instanceof Error?error.message:'Unable to activate invitation.'},{status:500})}
}
