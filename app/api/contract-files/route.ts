import {NextResponse} from 'next/server';
import {PutObjectCommand} from '@aws-sdk/client-s3';
import {getSignedUrl} from '@aws-sdk/s3-request-presigner';
import {r2Client,safeFileName} from '@/lib/r2';
import {createClient} from '@/lib/supabase/server';
const BUCKET=process.env.CLOUDFLARE_R2_INTERNAL_BUCKET||'plekxa-internal';
export async function POST(r:Request){try{const s=await createClient();const {data:{user}}=await s.auth.getUser();if(!user)return NextResponse.json({error:'Not authenticated.'},{status:401});const b=await r.json();const name=safeFileName(String(b.file_name||'contract-document'));const type=String(b.mime_type||'application/octet-stream');const key=`contracts/${new Date().getFullYear()}/${crypto.randomUUID()}-${name}`;const upload_url=await getSignedUrl(r2Client(),new PutObjectCommand({Bucket:BUCKET,Key:key,ContentType:type}),{expiresIn:3600});return NextResponse.json({upload_url,key,bucket:BUCKET,storage_uri:`r2://${BUCKET}/${key}`});}catch(e:any){return NextResponse.json({error:e?.message||'Could not prepare contract document upload.'},{status:500})}}
