'use client';

import Image from 'next/image';
import {useEffect,useState} from 'react';
import {useRouter} from 'next/navigation';
import type {AuthChangeEvent,Session} from '@supabase/supabase-js';
import {createClient} from '@/lib/supabase/client';

export default function AcceptInvitePage(){
 const router=useRouter();
 const [password,setPassword]=useState('');
 const [confirmPassword,setConfirmPassword]=useState('');
 const [message,setMessage]=useState('Verifying your invitation…');
 const [ready,setReady]=useState(false);
 const [busy,setBusy]=useState(false);

 useEffect(()=>{
  const supabase=createClient();
  if(!supabase){setMessage('Supabase is not configured for this deployment.');return}
  let mounted=true;
  const verify=async()=>{
   const {data:{session}}=await supabase.auth.getSession();
   if(session&&mounted){setReady(true);setMessage('Invitation verified. Create a password to activate your account.');return}
   const {data:{subscription}}=supabase.auth.onAuthStateChange((_event:AuthChangeEvent,nextSession:Session|null)=>{
    if(nextSession&&mounted){setReady(true);setMessage('Invitation verified. Create a password to activate your account.')}
   });
   window.setTimeout(async()=>{
    if(!mounted)return;
    const {data:{session:laterSession}}=await supabase.auth.getSession();
    if(!laterSession){setMessage('This invitation link is invalid, expired, or has already been used. Ask an administrator to send a new invitation.')}
   },2500);
   return()=>subscription.unsubscribe();
  };
  let cleanup:(()=>void)|undefined;
  verify().then(fn=>{cleanup=fn});
  return()=>{mounted=false;cleanup?.()};
 },[]);

 async function activate(e:React.FormEvent){
  e.preventDefault();
  if(password.length<8){setMessage('Use a password with at least 8 characters.');return}
  if(password!==confirmPassword){setMessage('The passwords do not match.');return}
  const supabase=createClient();
  if(!supabase){setMessage('Supabase is not configured for this deployment.');return}
  setBusy(true);setMessage('Activating your account…');
  const {data:{session}}=await supabase.auth.getSession();
  if(!session){setBusy(false);setReady(false);setMessage('Your invitation session has expired. Ask an administrator to send a new invitation.');return}
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
