'use client';
import {useEffect} from 'react';

export default function Home(){
 useEffect(()=>{
  const query=window.location.search;
  const hash=window.location.hash;
  const combined=`${query}${hash}`;
  const isInvite=/code=|token_hash=|access_token=|type=invite|type=recovery/.test(combined);
  window.location.replace(isInvite?`/accept-invite${query}${hash}`:'/dashboard');
 },[]);
 return <div className="access-loading">Opening Plekxa…</div>;
}
