'use client';
import {useEffect,useState} from 'react';
import {usePathname} from 'next/navigation';
import Sidebar from './Sidebar';
import Topbar from './Topbar';
import {permissionsFor,readRoles} from '@/lib/access';
export default function AdminShell({children}:{children:React.ReactNode}){
 const pathname=usePathname();const[role,setRole]=useState('Master Admin');const[allowedRoutes,setAllowedRoutes]=useState<string[]>([]);const[ready,setReady]=useState(false);const[mobileNavOpen,setMobileNavOpen]=useState(false);
 useEffect(()=>{const sync=()=>{const r=localStorage.getItem('plekxa:current-role')||'Master Admin';setRole(r);setAllowedRoutes(permissionsFor(r,readRoles()));setReady(true)};sync();window.addEventListener('plekxa-role-change',sync);window.addEventListener('plekxa-permissions-change',sync);return()=>{window.removeEventListener('plekxa-role-change',sync);window.removeEventListener('plekxa-permissions-change',sync)}},[]);
 useEffect(()=>setMobileNavOpen(false),[pathname]);
 useEffect(()=>{document.body.style.overflow=mobileNavOpen?'hidden':'';return()=>{document.body.style.overflow=''}},[mobileNavOpen]);
 const allowed=allowedRoutes.includes(pathname);
 return <div className="shell"><Sidebar mobileOpen={mobileNavOpen} onClose={()=>setMobileNavOpen(false)}/><main className="main"><Topbar onMenuClick={()=>setMobileNavOpen(true)}/><div className="content">{!ready?<div className="access-loading">Loading access…</div>:allowed?children:<div className="access-denied"><strong>Access restricted</strong><p>Your {role} role does not have permission to open this work area. Ask an Administrator to change your assigned permissions.</p></div>}</div></main></div>
}
