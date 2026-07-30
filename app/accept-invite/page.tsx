'use client';

import Image from 'next/image';
import {useEffect,useState} from 'react';
import {useRouter} from 'next/navigation';
import {createClient} from '@/lib/supabase/client';

function inviteParams(){
 const query=new URLSearchParams(window.location.search);
 const hash=new URLSearchParams(window.location.hash.replace(/^#/,''));
 return {
  code:query.get('code'),
  tokenHash:query.get('token_hash'),
  type:query.get('type'),
  accessToken:hash.get('access_token'),
  refreshToken:hash.get('refresh_token'),
  hashType:hash.get('type'),
 };
}

export default function AcceptInvitePage(){
 const router=useRouter();
 const [password,setPassword]=useState('');
 const [confirmPassword,setConfirmPassword]=useState('');
 const [message,setMessage]=useState('Verifying your invitation…');
 const [ready,setReady]=useState(false);
 const [busy,setBusy]=useState(false);

 useEffect(()=>{
  let cancelled=false;
  const verify=async()=>{
   const supabase=createClient();
   if(!supabase){setMessage('Supabase is not configured for this deployment.');return}
   const params=inviteParams();
   const hasInvite=Boolean(params.code||params.tokenHash||(params.accessToken&&params.refreshToken));
   if(!hasInvite){
    await supabase.auth.signOut();
    if(!cancelled)setMessage('This invitation link is invalid, expired, or has already been used. Ask an administrator to send a new invitation.');
    return;
   }

   // An administrator may already be signed in in this browser. Clear that session
   // before accepting the invitation so the invited employee can never inherit it.
   await supabase.auth.signOut();

   let error:Error|null=null;
   if(params.code){
    const result=await supabase.auth.exchangeCodeForSession(params.code);
    error=result.error;
   }else if(params.tokenHash){
    const result=await supabase.auth.verifyOtp({
     token_hash:params.tokenHash,
     type:(params.type==='recovery'?'recovery':'invite'),
    });
    error=result.error;
   }else if(params.accessToken&&params.refreshToken){
    const result=await supabase.auth.setSession({access_token:params.accessToken,refresh_token:params.refreshToken});
    error=result.error;
   }

   if(error){
    if(!cancelled)setMessage(error.message);
    return;
   }

   const {data:{session}}=await supabase.auth.getSession();
   if(!session){
    if(!cancelled)setMessage('The invitation session could not be created. Ask an administrator to resend the invitation.');
    return;
   }

   window.history.replaceState({},document.title,window.location.pathname);
   if(!cancelled){
    setReady(true);
    setMessage('Invitation verified. Create a password to activate your account.');
   }
  };
  verify();
  return()=>{cancelled=true};
 },[]);

 async function activate(e:React.FormEvent){
  e.preventDefault();
  if(password.length<8){setMessage('Use a password with at least 8 characters.');return}
  if(password!==confirmPassword){setMessage('The passwords do not match.');return}
  const supabase=createClient();
  if(!supabase){setMessage('Supabase is not configured for this deployment.');return}
  setBusy(true);setMessage('Activating your account…');
  const {data:{session}}=await supabase.auth.getSession();
  if(!session){setBusy(false);setReady(false);setMessage('Your invitation session has expired. Ask an administrator to resend the invitation.');return}
  const {error:updateError}=await supabase.auth.updateUser({password});
  if(updateError){setBusy(false);setMessage(updateError.message);return}
  const response=await fetch('/api/auth/accept-invite',{method:'POST',headers:{Authorization:`Bearer ${session.access_token}`}});
  const result=await response.json();
  if(!response.ok){setBusy(false);setMessage(result.error||'Your password was saved, but the staff account could not be activated. Contact an administrator.');return}
  window.dispatchEvent(new Event('plekxa-role-change'));
  setMessage('Account activated. Opening Plekxa Enterprise OS…');
  router.replace('/dashboard');
  router.refresh();
 }

 return <div className="login-page"><section className="login-brand"><Image src="/brand/plekxa-logo.png" alt="Plekxa" width={160} height={40}/><div><h1>Welcome to Plekxa.</h1><p>Accept your staff invitation, create your password and access the work areas assigned to your role.</p></div><small>Restricted to authorised Plekxa personnel.</small></section><section className="login-form-wrap"><form className="login-form" onSubmit={activate}><div className="eyebrow">Employee invitation</div><h2>Activate your account</h2><p className="page-copy">Create the password you will use to sign in.</p><div className="notice">{message}</div><div className="field"><label>New password</label><input type="password" minLength={8} value={password} onChange={e=>setPassword(e.target.value)} disabled={!ready||busy} required/></div><div className="field"><label>Confirm password</label><input type="password" minLength={8} value={confirmPassword} onChange={e=>setConfirmPassword(e.target.value)} disabled={!ready||busy} required/></div><button className="button primary" style={{width:'100%',justifyContent:'center'}} disabled={!ready||busy}>{busy?'Activating…':'Activate account'}</button></form></section></div>
}
