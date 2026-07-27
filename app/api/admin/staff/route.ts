import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';

function admin(){
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
 const key=process.env.SUPABASE_SERVICE_ROLE_KEY;
 return url&&key?createClient(url,key,{auth:{autoRefreshToken:false,persistSession:false}}):null;
}
export async function GET(){
 const s=admin(); if(!s)return NextResponse.json({error:'Supabase service credentials are not configured'},{status:503});
 const {data,error}=await s.from('staff_members').select('*').order('created_at',{ascending:false});
 return error?NextResponse.json({error:error.message},{status:500}):NextResponse.json({staff:data??[]});
}
export async function PATCH(request:Request){
 const s=admin(); if(!s)return NextResponse.json({error:'Supabase service credentials are not configured'},{status:503});
 const {id,role_name,status,full_name,department,job_title}=await request.json();
 if(!id)return NextResponse.json({error:'Staff ID is required'},{status:400});
 const updates:Object={}; Object.assign(updates,role_name!==undefined?{role_name}: {},status!==undefined?{status}: {},full_name!==undefined?{full_name}: {},department!==undefined?{department}: {},job_title!==undefined?{job_title}: {});
 const {data,error}=await s.from('staff_members').update(updates).eq('id',id).select().single();
 return error?NextResponse.json({error:error.message},{status:500}):NextResponse.json({staff:data});
}
export async function DELETE(request:Request){
 const s=admin(); if(!s)return NextResponse.json({error:'Supabase service credentials are not configured'},{status:503});
 const {id,auth_user_id,permanent=false}=await request.json();
 if(!id)return NextResponse.json({error:'Staff ID is required'},{status:400});
 if(permanent){
   const {error}=await s.from('staff_members').delete().eq('id',id); if(error)return NextResponse.json({error:error.message},{status:500});
   if(auth_user_id){const result=await s.auth.admin.deleteUser(auth_user_id);if(result.error)return NextResponse.json({error:result.error.message},{status:500});}
 }else{
   const {error}=await s.from('staff_members').update({status:'Suspended'}).eq('id',id); if(error)return NextResponse.json({error:error.message},{status:500});
   if(auth_user_id)await s.auth.admin.updateUserById(auth_user_id,{ban_duration:'876000h'});
 }
 return NextResponse.json({ok:true});
}
