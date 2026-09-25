import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';
import { sendMail } from '@/lib/mail';

export async function buildCertificatePdf(s:any,c:any){
 const [{data:a},{data:i}]=await Promise.all([
  s.from('asset_registry').select('title,internal_identifier,genre,mood').eq('id',c.asset_id).single(),
  s.from('plekxa_indexes').select('index_code').eq('id',c.index_id).single()
 ]);
 const pdf=await PDFDocument.create(); const page=pdf.addPage([595.28,841.89]);
 const bold=await pdf.embedFont(StandardFonts.HelveticaBold),regular=await pdf.embedFont(StandardFonts.Helvetica);
 page.drawRectangle({x:28,y:28,width:539,height:786,borderWidth:2,borderColor:rgb(.08,.08,.08)});
 page.drawText('PLEKXA',{x:55,y:755,size:25,font:bold}); page.drawText('INDEX INCLUSION CERTIFICATE',{x:55,y:710,size:18,font:bold});
 page.drawText('Formal record of Asset inclusion and economic participation',{x:55,y:684,size:10,font:regular});
 const rows=[['Certificate ID',c.certificate_code],['Asset',`${a?.internal_identifier||''} — ${a?.title||''}`],['Index',i?.index_code||''],['Genre / Mood',`${a?.genre||'—'} / ${a?.mood||'—'}`],['Asset Index Participation',`${Number(c.asset_index_percentage||0).toFixed(2)}%`],['Contributor',c.creator_name],['Contributor Role',c.creator_role||'—'],['Contributor Asset Participation',`${Number(c.contributor_asset_percentage||0).toFixed(2)}%`],['Effective Index Participation',`${Number(c.effective_index_percentage||c.participation_percentage||0).toFixed(4)}%`],['Effective Inclusion Date',c.effective_inclusion_date||''],['Status',String(c.status||'issued').toUpperCase()]];
 let y=625; for(const [k,v] of rows){page.drawText(k,{x:55,y,size:9,font:bold});page.drawText(String(v),{x:230,y,size:10,font:regular});page.drawLine({start:{x:55,y:y-9},end:{x:540,y:y-9},thickness:.5,color:rgb(.8,.8,.8)});y-=39}
 page.drawText('Issued by Plekxa Group Limited',{x:55,y:115,size:10,font:bold}); page.drawText('This certificate records Index inclusion and participation. Detailed rights remain governed by the applicable contributor agreement.',{x:55,y:88,size:7.5,font:regular,maxWidth:480});
 return {bytes:Buffer.from(await pdf.save()),asset:a,index:i};
}

async function recipientFor(s:any,c:any){
 if(!c.contributor_id)return null;
 const {data:contrib}=await s.from('asset_contributors').select('creator_id').eq('id',c.contributor_id).maybeSingle();
 if(!contrib?.creator_id)return null;
 const {data:profile}=await s.from('creator_profiles').select('user_id,email,legal_name,stage_name').eq('id',contrib.creator_id).maybeSingle();
 if(profile?.email)return {email:profile.email,userId:profile.user_id||null};
 if(profile?.user_id){const {data:u}=await s.auth.admin.getUserById(profile.user_id);if(u?.user?.email)return {email:u.user.email,userId:profile.user_id};}
 return null;
}

export async function deliverCertificatesForAsset(s:any,assetId:string){
 const {data:certs,error}=await s.from('index_certificates').select('*').eq('asset_id',assetId).eq('status','issued'); if(error)throw error;
 const results:any[]=[];
 for(const c of certs||[]){
  if(c.email_status==='sent'){results.push({id:c.id,sent:true,duplicatePrevented:true});continue}
  const recipient=await recipientFor(s,c);
  if(!recipient){await s.from('index_certificates').update({email_status:'no_recipient',email_error:'No creator email is linked to this contributor.'}).eq('id',c.id);results.push({id:c.id,sent:false,reason:'No linked creator email'});continue}
  try{
   const {bytes,asset,index}=await buildCertificatePdf(s,c);
   const subject=`Your Plekxa Index Inclusion Certificate — ${asset?.internal_identifier||asset?.title||'Asset'}`;
   const text=`Your Asset ${asset?.internal_identifier||''} — ${asset?.title||''} has been included in ${index?.index_code||'a Plekxa Index'}.\n\nAsset Index participation: ${Number(c.asset_index_percentage||0).toFixed(2)}%\nYour Asset participation: ${Number(c.contributor_asset_percentage||0).toFixed(2)}%\nYour effective Index participation: ${Number(c.effective_index_percentage||0).toFixed(4)}%\n\nYour formal certificate is attached and is also available in Creator Studio.`;
   const mail=await sendMail({to:recipient.email,subject,text,html:`<p>Your Asset <strong>${asset?.internal_identifier||''} — ${asset?.title||''}</strong> has been included in <strong>${index?.index_code||'a Plekxa Index'}</strong>.</p><p>Asset Index participation: <strong>${Number(c.asset_index_percentage||0).toFixed(2)}%</strong><br/>Your Asset participation: <strong>${Number(c.contributor_asset_percentage||0).toFixed(2)}%</strong><br/>Your effective Index participation: <strong>${Number(c.effective_index_percentage||0).toFixed(4)}%</strong></p><p>Your formal certificate is attached and is also available in Creator Studio.</p>`,attachments:[{filename:`${c.certificate_code}.pdf`,content:bytes,contentType:'application/pdf'}]});
   if(!mail.sent)throw new Error(mail.reason||'Mail provider did not send');
   await s.from('index_certificates').update({email_status:'sent',emailed_at:new Date().toISOString(),emailed_to:recipient.email,email_error:null}).eq('id',c.id);
   if(recipient.userId)await s.from('notifications').insert({recipient_id:recipient.userId,type:'index_certificate_issued',title:'Index certificate issued',message:`Your certificate ${c.certificate_code} is ready.`,action_url:'/certificates',entity_type:'certificate',entity_id:c.id});
   results.push({id:c.id,sent:true,to:recipient.email});
  }catch(e:any){await s.from('index_certificates').update({email_status:'failed',email_error:String(e?.message||e).slice(0,1000)}).eq('id',c.id);results.push({id:c.id,sent:false,reason:e?.message||'Email failed'});}
 }
 return results;
}
