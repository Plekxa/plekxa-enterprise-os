import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';

export async function POST(request:Request){
 try{
  const body=await request.json();
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey=process.env.SUPABASE_SERVICE_ROLE_KEY;
  if(!url||!serviceKey)return NextResponse.json({ok:true,stored:false,reason:'Database environment variables are unavailable.'});
  const supabase=createClient(url,serviceKey,{auth:{autoRefreshToken:false,persistSession:false}});
  const {error}=await supabase.from('analytics_reports').insert({external_id:body.id,name:body.name,department:body.department,format:body.format,date_range:body.dateRange,created_at:body.createdAt});
  if(error)return NextResponse.json({ok:true,stored:false,reason:error.message});
  return NextResponse.json({ok:true,stored:true});
 }catch(error){return NextResponse.json({error:error instanceof Error?error.message:'Unable to save report.'},{status:500})}
}
