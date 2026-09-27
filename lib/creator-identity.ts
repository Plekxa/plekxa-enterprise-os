export async function resolveCreatorUserId(admin:any, candidate?:string|null, enterpriseCreatorId?:string|null){
  const ids=[candidate,enterpriseCreatorId].filter(Boolean) as string[];
  for(const id of ids){
    const auth=await admin.auth.admin.getUserById(id);
    if(auth?.data?.user)return id;
    const {data:profile}=await admin.from('creator_profiles').select('user_id').eq('id',id).maybeSingle();
    if(profile?.user_id){const check=await admin.auth.admin.getUserById(profile.user_id);if(check?.data?.user)return String(profile.user_id);}
  }
  return null;
}
