"use client";
import Link from "next/link";
import {usePathname} from "next/navigation";
import * as Icons from "@/components/icons";
const items=[
 {href:"/dashboard",label:"Home",icon:Icons.LayoutDashboard},
 {href:"/creative-programmes",label:"Commissions",icon:Icons.FolderKanban},
 {href:"/projects",label:"Projects",icon:Icons.Kanban},
 {href:"/profile",label:"Profile",icon:Icons.UserRound},
];
type Access={role:string;permissions:string[];isMaster:boolean};
export default function MobileBottomNav({access,onMore:_onMore}:{access:Access|null;onMore:()=>void}){
 const path=usePathname();if(!access)return null;
 const privileged=access.isMaster||access.role.trim().toLowerCase().replace(/[\s_-]+/g," ")==="super admin";
 const visible=items.filter(item=>item.href==="/profile"||privileged||access.permissions.some(p=>item.href===p||item.href.startsWith(p+"/")));
 return <nav className="plekxa-mobile-bottom-nav" aria-label="Mobile primary navigation">{visible.map(({href,label,icon:Icon})=><Link key={href} href={href} aria-current={path===href||path.startsWith(href+"/")?"page":undefined}><Icon size={21}/><span>{label}</span></Link>)}</nav>;
}
