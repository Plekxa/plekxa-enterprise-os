export type AccessRole=string;
export type PermissionRole={id:string;name:string;description:string;permissions:string[];system:boolean;master:boolean};
export const ALL_ROUTES=['/dashboard','/people','/creators','/applications','/projects','/proposals','/contracts','/assets','/experiences','/content','/newsroom','/marketing','/crm','/careers','/support','/notifications','/finance','/analytics','/activity','/settings','/profile','/search'];
export const ROUTE_LABELS:Record<string,string>={
 '/dashboard':'Dashboard','/people':'People & Access','/creators':'Creator Directory','/applications':'Studio Submissions','/projects':'Projects','/proposals':'Proposals','/contracts':'Contracts','/assets':'Asset Registry','/experiences':'Experiences','/content':'Content Studio','/newsroom':'Newsroom','/marketing':'Marketing','/crm':'CRM','/careers':'Careers','/support':'Support','/notifications':'Notifications','/finance':'Finance','/analytics':'Analytics','/activity':'Audit Activity','/settings':'Settings','/profile':'My Profile','/search':'Global Search'
};
export const DEFAULT_ROLES:PermissionRole[]=[
 {id:'master-admin',name:'Master Admin',description:'Company owner with every permission and reserved ownership controls.',permissions:ALL_ROUTES,system:true,master:true},
 {id:'administrator',name:'Administrator',description:'Full day-to-day operational administration without ownership transfer.',permissions:ALL_ROUTES,system:true,master:false},
 {id:'it-administrator',name:'IT Administrator',description:'All technical and operational areas without ownership-level controls.',permissions:ALL_ROUTES,system:true,master:false},
 {id:'creator-success',name:'Creator Success',description:'Creator onboarding, submissions, contracts and catalogue operations.',permissions:['/dashboard','/creators','/applications','/projects','/contracts','/assets','/experiences','/notifications','/analytics'],system:true,master:false},
 {id:'project-manager',name:'Project Manager',description:'Project, proposal, experience and delivery management.',permissions:['/dashboard','/creators','/applications','/projects','/proposals','/contracts','/assets','/experiences','/content','/analytics'],system:true,master:false},
 {id:'finance',name:'Finance',description:'Revenue, contracts, registry and reporting.',permissions:['/dashboard','/creators','/contracts','/assets','/experiences','/finance','/analytics','/activity'],system:true,master:false},
 {id:'content-marketing',name:'Content & Marketing',description:'Publishing, campaigns, CRM and experience promotion.',permissions:['/dashboard','/creators','/projects','/experiences','/content','/newsroom','/marketing','/crm','/notifications','/analytics'],system:true,master:false},
 {id:'support',name:'Support',description:'Customer and creator support operations.',permissions:['/dashboard','/creators','/projects','/support','/notifications'],system:true,master:false},
 {id:'viewer',name:'Viewer',description:'Read-only executive overview.',permissions:['/dashboard','/analytics'],system:true,master:false}
];
export const MASTER_ONLY=['company ownership','delete company','transfer master access','security recovery','billing ownership'];
export function readRoles():PermissionRole[]{if(typeof window==='undefined')return DEFAULT_ROLES;try{const raw=localStorage.getItem('plekxa:roles');return raw?JSON.parse(raw):DEFAULT_ROLES}catch{return DEFAULT_ROLES}}
export function writeRoles(roles:PermissionRole[]){if(typeof window==='undefined')return;localStorage.setItem('plekxa:roles',JSON.stringify(roles));window.dispatchEvent(new Event('plekxa-permissions-change'))}
export function permissionsFor(roleName:string,roles=DEFAULT_ROLES){return roles.find(r=>r.name===roleName)?.permissions||['/dashboard']}
