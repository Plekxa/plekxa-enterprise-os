'use client';
import {Bell,Search,Menu} from '@/components/icons';
import {createClient} from '@/lib/supabase/client';
import {useRouter} from 'next/navigation';
import {FormEvent,useEffect,useState} from 'react';
type Me={full_name:string;role_name:string;email?:string};
export default function Topbar({onMenuClick}:{onMenuClick?:()=>void}){
 const[q,setQ]=useState('');const[notificationOpen,setNotificationOpen]=useState(false);const[profileOpen,setProfileOpen]=useState(false);const[me,setMe]=useState<Me>({full_name:'Plekxa User',role_name:'Staff'});const router=useRouter();
 useEffect(()=>{fetch('/api/admin/me').then(r=>r.ok?r.json():null).then(j=>{if(j?.user)setMe(j.user)}).catch(()=>{})},[]);
 function submit(e:FormEvent<HTMLFormElement>){e.preventDefault();if(q.trim())router.push(`/search?q=${encodeURIComponent(q.trim())}`)}
 function go(path:string){setNotificationOpen(false);setProfileOpen(false);router.push(path)}
 async function logout(){const s=createClient();if(s)await s.auth.signOut();setProfileOpen(false);router.replace('/login');router.refresh()}
 const initials=me.full_name.split(' ').map(x=>x[0]).slice(0,2).join('').toUpperCase();
 return <header className="topbar"><button type="button" className="icon-button mobile-menu-button" onClick={onMenuClick} aria-label="Open navigation"><Menu size={22}/></button><form className="search" onSubmit={submit}><Search size={15}/><input suppressHydrationWarning value={q} onChange={e=>setQ(e.target.value)} placeholder="Search creators, staff, projects, assets, experiences…" aria-label="Global search"/></form><div className="user-chip"><button suppressHydrationWarning type="button" className="icon-button notification-button" onClick={()=>{setNotificationOpen(v=>!v);setProfileOpen(false)}} aria-label="Notifications"><Bell size={18}/><i/></button><button suppressHydrationWarning type="button" className="profile-button" onClick={()=>{setProfileOpen(v=>!v);setNotificationOpen(false)}}><div className="avatar">{initials}</div><span>{me.full_name}</span></button>{notificationOpen&&<div className="notification-popover"><strong>Notifications</strong><p>3 applications are awaiting review.</p><p>A newsroom draft is ready for approval.</p><button className="button secondary" onClick={()=>go('/notifications')}>View all</button></div>}{profileOpen&&<div className="profile-popover"><div className="profile-header"><div className="avatar large">{initials}</div><div><strong>{me.full_name}</strong><p>{me.role_name}</p></div></div><hr/><button className="menu-item" onClick={()=>go('/profile')}>My Profile</button><button className="menu-item" onClick={()=>go('/settings')}>Account Settings</button><button className="menu-item" onClick={()=>go('/notifications')}>Notifications</button><hr/><button className="menu-item danger" onClick={logout}>Sign Out</button></div>}</div></header>
}
