export const CREATOR_ROLES = ['Lead Creator','Supporting Creator','Instrumentalist','Producer','Prompt Writer','Narrator','Creative Director','Sponsor','Composer','Songwriter','Engineer','Designer','Other'] as const;
export const EXPERIENCE_TYPES = ['Music','Film','Series','Podcast','Live Experience','Game','Editorial','Mixed Media'] as const;
export const ASSET_TYPES = ['Audio Master','Composition','Instrumental','Vocal Recording','Narration','Video','Artwork','Photography','Script','Film','Episode','Trailer','Other'] as const;

export type Contributor = {id:string;name:string;role:string;ppr:number;creatorId?:string};
export type Asset = {id:string;title:string;type:string;releaseDate:string;theme:string;identifier:string;status:string;contributors:Contributor[];experienceId?:string};
export type ExperienceAsset = {id:string;assetId?:string;title:string;type:string};
export type Experience = {id:string;title:string;type:string;targetAudience:string;releaseDate:string;description:string;creativeDirector:string;creatorPpr:number;status:string;assets:ExperienceAsset[]};
export type FinanceEntry = {id:string;experienceId:string;period:string;gross:number;distribution:number;tax:number;fees:number;net:number;creatorPool:number;companyPool:number;createdAt:string};

export const seedAssets:Asset[]=[
 {id:'asset-1',title:'Between the Lines',type:'Audio Master',releaseDate:'2026-09-30',theme:'A reflective R&B master about the things left unsaid.',identifier:'ISRC pending',status:'Approved',experienceId:'exp-1',contributors:[{id:'c1',name:'Amara Nwosu',role:'Lead Creator',ppr:55,creatorId:'creator-1'},{id:'c2',name:'Beezy X',role:'Producer',ppr:30,creatorId:'creator-2'},{id:'c3',name:'Tobi James',role:'Songwriter',ppr:15,creatorId:'creator-3'}]},
 {id:'asset-2',title:'Moonlight Voice Note',type:'Narration',releaseDate:'2026-09-30',theme:'A spoken-word bridge connecting the experience chapters.',identifier:'PX-A-00418',status:'Approved',experienceId:'exp-1',contributors:[{id:'c4',name:'Maya Adeyemi',role:'Narrator',ppr:70,creatorId:'creator-4'},{id:'c5',name:'Anthony Ighomena',role:'Creative Director',ppr:30}]},
 {id:'asset-3',title:'Bittersweet',type:'Audio Master',releaseDate:'2026-08-18',theme:'The emotional tension between love and self-preservation.',identifier:'GB-PX1-26-00003',status:'Active',experienceId:'exp-2',contributors:[{id:'c6',name:'Daniel Cole',role:'Producer',ppr:40,creatorId:'creator-2'},{id:'c7',name:'Amara Nwosu',role:'Lead Creator',ppr:60,creatorId:'creator-1'}]}
];
export const seedExperiences:Experience[]=[
 {id:'exp-1',title:'Stories and Moonlight',type:'Mixed Media',targetAudience:'Adults aged 24–40 navigating identity, relationships and change',releaseDate:'2026-09-30',description:'An intimate night-time experience combining original music, narration and reflective prompts.',creativeDirector:'Anthony Ighomena',creatorPpr:30,status:'In production',assets:[{id:'ea1',assetId:'asset-1',title:'Between the Lines',type:'Audio Master'},{id:'ea2',assetId:'asset-2',title:'Moonlight Voice Note',type:'Narration'}]},
 {id:'exp-2',title:'Bittersweet',type:'Music',targetAudience:'Alternative R&B and Afropop listeners aged 18–34',releaseDate:'2026-08-18',description:'An experiential album exploring emotional contradiction.',creativeDirector:'Anthony Ighomena',creatorPpr:35,status:'Scheduled',assets:[{id:'ea3',assetId:'asset-3',title:'Bittersweet',type:'Audio Master'}]}
];
export const seedFinance:FinanceEntry[]=[];

export function uid(prefix:string){return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2,7)}`}
export function money(value:number){return new Intl.NumberFormat('en-US',{style:'currency',currency:'USD',maximumFractionDigits:2}).format(Number.isFinite(value)?value:0)}
export function readStore<T>(key:string,fallback:T):T{if(typeof window==='undefined')return fallback;try{const raw=localStorage.getItem(key);return raw?JSON.parse(raw):fallback}catch{return fallback}}
export function writeStore<T>(key:string,value:T){if(typeof window==='undefined')return;localStorage.setItem(key,JSON.stringify(value));window.dispatchEvent(new CustomEvent('plekxa-store',{detail:{key}}))}
