'use client';
import Image from 'next/image';
import Link from 'next/link';
import {useEffect,useState} from 'react';
import {usePathname} from 'next/navigation';
import * as Icons from '@/components/icons';
import {navigation} from '@/lib/navigation';
import {permissionsFor,readRoles} from '@/lib/access';

type SidebarProps={mobileOpen?:boolean;onClose?:()=>void};

export default function Sidebar({mobileOpen=false,onClose}:SidebarProps){
 const p=usePathname();
 const[role,setRole]=useState('Master Admin');
 useEffect(()=>{const sync=()=>setRole(localStorage.getItem('plekxa:current-role')||'Master Admin');sync();window.addEventListener('plekxa-role-change',sync);window.addEventListener('plekxa-permissions-change',sync);return()=>{window.removeEventListener('plekxa-role-change',sync);window.removeEventListener('plekxa-permissions-change',sync)}},[]);
 useEffect(()=>{onClose?.()},[p]);
 const allowed=permissionsFor(role,readRoles());let section='';
 return <>
  <button type="button" aria-label="Close navigation" className={`mobile-sidebar-backdrop ${mobileOpen?'open':''}`} onClick={onClose}/>
  <aside className={`sidebar ${mobileOpen?'mobile-open':''}`}>
   <div className="sidebar-mobile-head"><Image className="brand" src="/brand/plekxa-logo.png" alt="Plekxa" width={150} height={35}/><button className="icon-button sidebar-close" type="button" onClick={onClose} aria-label="Close navigation"><Icons.X size={20}/></button></div>
   <div className="role-preview"><span>Access</span><strong>{role}</strong></div>
   <nav>{navigation.filter(i=>allowed.includes(i.href)).map(i=>{const Icon=(Icons as unknown as Record<string,React.ComponentType<{size?:number}>>)[i.icon];const head=i.section!==section;section=i.section;return <div key={i.href}>{head&&<div className="nav-section">{i.section}</div>}<Link className={`nav-link ${p===i.href?'active':''}`} href={i.href} onClick={onClose}>{Icon&&<Icon size={18}/>}<span>{i.label}</span></Link></div>})}</nav>
  </aside>
 </>
}
