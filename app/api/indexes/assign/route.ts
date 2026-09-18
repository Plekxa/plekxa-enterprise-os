import {NextResponse} from 'next/server';
import {createClient} from '@supabase/supabase-js';
function db(){const u=process.env.NEXT_PUBLIC_SUPABASE_URL,k=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!u||!k)throw new Error('Supabase service credentials are not configured.');return createClient(u,k,{auth:{persistSession:false}})}

const VALID=new Set(['flagship','supporting','niche']);
export async function POST(r:Request){
 try{
  const s=db(); const b=await r.json();
  const assignments:Array<{asset_id:string;role:string}>=Array.isArray(b.assignments)?b.assignments:[];
  if(!assignments.length)return NextResponse.json({error:'Select at least one asset to assign.'},{status:400});
  const results=[];
  for(const item of assignments){
   const assetId=String(item.asset_id||''),role=String(item.role||'').toLowerCase();
   if(!assetId||!VALID.has(role)){results.push({asset_id:assetId,ok:false,error:'Choose Flagship, Supporting or Niche.'});continue}
   const {data:indexId,error}=await s.rpc('plekxa_assign_asset_to_index',{p_asset_id:assetId,p_role:role});
   if(error){results.push({asset_id:assetId,ok:false,error:error.message});continue}
   const {error:ce}=await s.rpc('plekxa_issue_index_certificates',{p_asset_id:assetId});
   results.push({asset_id:assetId,ok:true,index_id:indexId,certificate_warning:ce?.message||null});
  }
  const failed=results.filter(x=>!x.ok);
  return NextResponse.json({ok:failed.length===0,results},{status:failed.length===assignments.length?400:200});
 }catch(e){return NextResponse.json({error:e instanceof Error?e.message:'Index assignment failed.'},{status:500})}
}
