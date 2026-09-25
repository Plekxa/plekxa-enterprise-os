import {NextResponse} from 'next/server';
import {enterpriseContext,audit} from '@/lib/enterprise-auth';

function fail(e:any){return NextResponse.json({error:e?.message||'Project production request failed.'},{status:e?.status||500})}
async function creator(s:any,id:string){const {data,error}=await s.from('creator_profiles').select('id,user_id,legal_name,stage_name,email,display_name').eq('id',id).single();if(error)throw error;return data}
async function project(s:any,id:string){const {data,error}=await s.from('projects').select('*').eq('id',id).single();if(error)throw error;return data}
export async function GET(_:Request,{params}:{params:Promise<{id:string}>}){try{const {admin:s}=await enterpriseContext();const {id}=await params;const p=await project(s,id);if(!p.reserved_asset_id)throw new Error('This Project has no reserved Asset.');const [assetQ,contribQ,workspaceQ,appsQ,creatorsQ]=await Promise.all([
 s.from('asset_registry').select('*').eq('id',p.reserved_asset_id).single(),
 s.from('asset_contributors').select('*').eq('asset_id',p.reserved_asset_id).neq('allocation_status','removed').order('created_at'),
 s.from('creator_project_workspaces').select('*').eq('project_id',id).order('created_at'),
 s.from('creator_applications').select('*').eq('project_id',id).order('applied_at',{ascending:false}),
 s.from('creator_profiles').select('id,user_id,legal_name,stage_name,email,display_name').order('created_at',{ascending:false})
]);
 for(const q of [assetQ,contribQ,workspaceQ,appsQ,creatorsQ])if(q.error)throw q.error;
 return NextResponse.json({project:p,asset:assetQ.data,contributors:contribQ.data||[],workspaces:workspaceQ.data||[],applications:appsQ.data||[],creators:creatorsQ.data||[]});
}catch(e){return fail(e)}}

export async function POST(r:Request,{params}:{params:Promise<{id:string}>}){try{const {admin:s,user,staff}=await enterpriseContext();const {id}=await params;const b=await r.json();const action=String(b.action||'');const p=await project(s,id);if(!p.reserved_asset_id)throw new Error('Reserve the Project Asset before commissioning creators.');
 if(action==='assign_director'){
  const cp=await creator(s,String(b.creator_id||''));const share=Number(b.ownership_percent||0);if(share<0||share>100)return NextResponse.json({error:'Ownership must be between 0 and 100.'},{status:400});
  await s.from('projects').update({director_creator_id:cp.id,director_user_id:cp.user_id||null,director_ownership_percent:share,production_mode:'director_led'}).eq('id',id);
  const {data:existing}=await s.from('asset_contributors').select('id').eq('asset_id',p.reserved_asset_id).eq('creator_id',cp.id).maybeSingle();
  const row={asset_id:p.reserved_asset_id,creator_id:cp.id,contributor_name:cp.legal_name||cp.stage_name||cp.display_name||cp.email||'Director',role_name:'Director',master_share:share,publishing_share:0,allocation_status:'planned',updated_at:new Date().toISOString()};
  if(existing)await s.from('asset_contributors').update(row).eq('id',existing.id);else{const q=await s.from('asset_contributors').insert(row);if(q.error)throw q.error;}
  const {error:ve}=await s.rpc('plekxa_validate_asset_ownership',{p_asset_id:p.reserved_asset_id});if(ve)throw ve;
  if(cp.user_id){const {data:w}=await s.from('creator_project_workspaces').select('id').eq('project_id',id).eq('creator_id',cp.user_id).eq('commission_role','director').maybeSingle();if(!w){const q=await s.from('creator_project_workspaces').insert({project_id:id,creator_id:cp.user_id,enterprise_creator_id:cp.id,asset_id:p.reserved_asset_id,title:p.title||p.name,status:'active',commission_code:`DIR-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`,commission_role:'director',director_can_view:true,pay_amount:Number(b.pay_amount||0),pay_currency:b.pay_currency||p.pay_currency||'GBP'});if(q.error)throw q.error;}}
  await audit(s,user,staff,'director_assigned','project',id,{creator_id:cp.id,asset_id:p.reserved_asset_id,ownership_percent:share});return NextResponse.json({ok:true});
 }
 if(action==='commission_contributor'){
  const cp=await creator(s,String(b.creator_id||''));const share=Number(b.ownership_percent||0);if(share<0||share>100)return NextResponse.json({error:'Ownership must be between 0 and 100.'},{status:400});const role=String(b.role_name||'Contributor').trim()||'Contributor';
  const {data:w,error:we}=await s.from('creator_project_workspaces').insert({project_id:id,creator_id:cp.user_id||null,enterprise_creator_id:cp.id,asset_id:p.reserved_asset_id,title:p.title||p.name,status:'active',commission_code:`COM-${new Date().getFullYear()}-${String(Date.now()).slice(-6)}`,commission_role:role.toLowerCase().replace(/\s+/g,'_'),director_can_view:true,pay_amount:Number(b.pay_amount||0),pay_currency:b.pay_currency||p.pay_currency||'GBP'}).select('*').single();if(we)throw we;
  const {data:existing}=await s.from('asset_contributors').select('id').eq('asset_id',p.reserved_asset_id).eq('creator_id',cp.id).maybeSingle();const row={asset_id:p.reserved_asset_id,creator_id:cp.id,contributor_name:cp.legal_name||cp.stage_name||cp.display_name||cp.email||'Contributor',role_name:role,master_share:share,publishing_share:0,allocation_status:'planned',source_workspace_id:w.id,updated_at:new Date().toISOString()};if(existing)await s.from('asset_contributors').update(row).eq('id',existing.id);else{const q=await s.from('asset_contributors').insert(row);if(q.error)throw q.error;}
  const {error:ve}=await s.rpc('plekxa_validate_asset_ownership',{p_asset_id:p.reserved_asset_id});if(ve){await s.from('creator_project_workspaces').delete().eq('id',w.id);throw ve;}
  await audit(s,user,staff,'creator_commissioned','project',id,{creator_id:cp.id,role,asset_id:p.reserved_asset_id,ownership_percent:share,workspace_id:w.id});return NextResponse.json({ok:true,workspace:w});
 }
 if(action==='finalize_asset'){
  const {data:total,error:te}=await s.rpc('plekxa_validate_asset_ownership',{p_asset_id:p.reserved_asset_id});if(te)throw te;if(Number(total)!==100)return NextResponse.json({error:`Contributor ownership must total exactly 100% before final approval. Current total: ${Number(total).toFixed(2)}%.`},{status:409});
  const q=await s.from('asset_registry').update({status:'approved'}).eq('id',p.reserved_asset_id);if(q.error)throw q.error;await s.from('asset_contributors').update({allocation_status:'confirmed',updated_at:new Date().toISOString()}).eq('asset_id',p.reserved_asset_id).neq('allocation_status','removed');
  const {error:ce}=await s.rpc('plekxa_issue_index_certificates',{p_asset_id:p.reserved_asset_id});if(ce)throw ce;await audit(s,user,staff,'asset_finalized','asset',p.reserved_asset_id,{project_id:id,ownership_total:100});return NextResponse.json({ok:true});
 }
 if(action==='update_contributor'){
  const share=Number(b.ownership_percent||0);const patch:any={master_share:share,updated_at:new Date().toISOString()};if(b.role_name)patch.role_name=String(b.role_name);const q=await s.from('asset_contributors').update(patch).eq('id',String(b.contributor_id||''));if(q.error)throw q.error;const {error:ve}=await s.rpc('plekxa_validate_asset_ownership',{p_asset_id:p.reserved_asset_id});if(ve)throw ve;await audit(s,user,staff,'asset_contributor_updated','asset',p.reserved_asset_id,{contributor_id:b.contributor_id,ownership_percent:share});return NextResponse.json({ok:true});
 }
 return NextResponse.json({error:'Unknown production action.'},{status:400});
}catch(e){return fail(e)}}
