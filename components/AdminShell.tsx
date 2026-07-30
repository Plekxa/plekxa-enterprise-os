'use client';
import {useEffect,useState} from 'react';
import {usePathname} from 'next/navigation';
import Sidebar from './Sidebar';
import Topbar from './Topbar';

type Access={role:string;permissions:string[];isMaster:boolean};

const normaliseRole=(role:string)=>role.trim().toLowerCase().replace(/[\s_-]+/g,' ');
const isSuperAdmin=(access:Access|null)=>Boolean(access&&(access.isMaster||normaliseRole(access.role)==='super admin'));
const routeAllowed=(pathname:string,permissions:string[])=>permissions.some(route=>pathname===route||pathname.startsWith(`${route}/`));

export default function AdminShell({children}:{children:React.ReactNode}){
 const pathname=usePathname();
 const[access,setAccess]=useState<Access|null>(null);
 const[error,setError]=useState('');
 const[mobileNavOpen,setMobileNavOpen]=useState(false);
 useEffect(()=>{
  fetch('/api/admin/me',{cache:'no-store'}).then(async r=>{
   const j=await r.json();
   if(!r.ok){
    if(r.status===401){window.location.replace('/login');return}
    if(j.code==='INVITE_ACTIVATION_REQUIRED'){window.location.replace('/accept-invite');return}
    throw new Error(j.error||'Unable to load access');
   }
   setAccess({role:j.user.role_name,permissions:j.user.permissions||[],isMaster:Boolean(j.user.is_master)});
  }).catch(e=>setError(e instanceof Error?e.message:'Unable to load access'));
 },[]);
 useEffect(()=>setMobileNavOpen(false),[pathname]);
 useEffect(()=>{document.body.style.overflow=mobileNavOpen?'hidden':'';return()=>{document.body.style.overflow=''}},[mobileNavOpen]);
 const allowed=isSuperAdmin(access)||pathname.startsWith('/search')||routeAllowed(pathname,access?.permissions||[]);
 return <div className="shell"><Sidebar mobileOpen={mobileNavOpen} onClose={()=>setMobileNavOpen(false)} access={access}/><main className="main"><Topbar onMenuClick={()=>setMobileNavOpen(true)}/><div className="content">{error?<div className="access-denied"><strong>Access unavailable</strong><p>{error}</p></div>:!access?<div className="access-loading">Loading access…</div>:allowed?children:<div className="access-denied"><strong>Access restricted</strong><p>Your {access.role} role does not have permission to open this work area.</p></div>}</div></main></div>
}
