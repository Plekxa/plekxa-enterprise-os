import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';
export const dynamic='force-dynamic';
export async function GET(request:Request){
 const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;
 if(!u||!k)return NextResponse.json({error:'Supabase service credentials are not configured.'},{status:503});
 const s=createClient(u,k,{auth:{persistSession:false}});
 const limit=Math.min(Number(new URL(request.url).searchParams.get('limit')||500),500);
 const {data,error}=await s.from('notifications').select('*').eq('audience','enterprise').order('created_at',{ascending:false}).limit(limit);
 if(error)return NextResponse.json({error:error.message},{status:500});
 const out=[];
 for(const n of data??[]){const user=await s.auth.admin.getUserById(n.recipient_id);out.push({...n,recipient_email:user.data.user?.email||null})}
 return NextResponse.json({notifications:out});
}
