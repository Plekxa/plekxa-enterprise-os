
import { S3Client } from "@aws-sdk/client-s3";

export const R2_BUCKET = process.env.CLOUDFLARE_R2_BUCKET || "plekxa-masters";
export function r2Client() {
  const accountId = process.env.CLOUDFLARE_ACCOUNT_ID;
  const accessKeyId = process.env.CLOUDFLARE_R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.CLOUDFLARE_R2_SECRET_ACCESS_KEY;
  if (!accountId || !accessKeyId || !secretAccessKey) throw new Error("Cloudflare R2 is not configured.");
  return new S3Client({
    region: "auto",
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
  });
}
export function safeFileName(name:string){return name.replace(/[^a-zA-Z0-9._-]+/g,"-").replace(/^-+|-+$/g,"")||"file"}
export function assetObjectKey(assetCode:string, category:string, name:string){
  const folder = ({audio:"audio",video:"video",artwork:"artwork",stems:"stems",lyrics:"lyrics",document:"documents",other:"documents"} as Record<string,string>)[category]||"documents";
  return `${assetCode}/${folder}/${crypto.randomUUID()}-${safeFileName(name)}`;
}
