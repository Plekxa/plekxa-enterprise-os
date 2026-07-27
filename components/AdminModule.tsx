'use client';

import {useMemo, useState} from 'react';
import {Check, ChevronRight, Download, MoreHorizontal, Plus, Search, X} from '@/components/icons';
import MetricCards from './MetricCards';
import type {Metric} from '@/lib/types';

type Column={key:string;label:string};
type Row=Record<string,string|number|undefined>;
type Action={label:string;status?:string;danger?:boolean};

type Props={
  eyebrow:string;title:string;copy:string;action:string;
  metrics:Metric[];columns:Column[];initialRows:Row[];
  actions?:Action[];
};

const defaults:Record<string,Action[]>={
  Creators:[{label:'Approve creator',status:'Verified'},{label:'Request changes',status:'Pending review'},{label:'Restrict creator',status:'Restricted',danger:true}],
  Applications:[{label:'Shortlist',status:'Shortlisted'},{label:'Approve application',status:'Approved'},{label:'Reject application',status:'Rejected',danger:true}],
  'Proposals & pitches':[{label:'Approve proposal',status:'Approved'},{label:'Request revision',status:'Under review'},{label:'Hold proposal',status:'Held'},{label:'Reject proposal',status:'Rejected',danger:true}],
  Projects:[{label:'Open applications',status:'Open'},{label:'Move to production',status:'In production'},{label:'Send to review',status:'In review'},{label:'Complete project',status:'Completed'}],
  Contracts:[{label:'Send for signature',status:'Awaiting signature'},{label:'Mark active',status:'Active'},{label:'Mark completed',status:'Completed'}],
  'Asset registry':[{label:'Approve rights',status:'Approved'},{label:'Mark active',status:'Active'},{label:'Restrict asset',status:'Restricted',danger:true}],
  Experiences:[{label:'Approve experience',status:'Approved'},{label:'Schedule',status:'Scheduled'},{label:'Publish',status:'Published'}],
  'Audience catalogue':[{label:'Approve content',status:'Approved'},{label:'Schedule',status:'Scheduled'},{label:'Publish',status:'Published'},{label:'Unpublish',status:'Draft',danger:true}],
  Newsroom:[{label:'Send to review',status:'Review'},{label:'Schedule article',status:'Scheduled'},{label:'Publish article',status:'Published'},{label:'Archive article',status:'Archived',danger:true}],
  Careers:[{label:'Publish vacancy',status:'Open'},{label:'Close vacancy',status:'Closed',danger:true}],
  Marketing:[{label:'Approve campaign',status:'Approved'},{label:'Schedule campaign',status:'Scheduled'},{label:'Launch campaign',status:'Active'},{label:'Pause campaign',status:'Paused',danger:true}],
  'Support centre':[{label:'Assign to me',status:'Open'},{label:'Waiting on user',status:'Waiting on user'},{label:'Resolve ticket',status:'Resolved'}],
  Notifications:[{label:'Send now',status:'Sent'},{label:'Schedule',status:'Scheduled'},{label:'Cancel',status:'Cancelled',danger:true}],
  Finance:[{label:'Submit for approval',status:'Review'},{label:'Approve batch',status:'Approved'},{label:'Mark paid',status:'Paid'}],
  'People & access':[{label:'Activate account',status:'Active'},{label:'Resend invite',status:'Pending invite'},{label:'Suspend account',status:'Suspended',danger:true}],
  'Activity log':[{label:'View event details'}],
  'Platform settings':[{label:'Activate setting',status:'Active'},{label:'Disable setting',status:'Disabled',danger:true}],
};

function badge(status:unknown){const s=String(status??'');return s.match(/active|approved|published|resolved|paid|verified|completed|sent|open/i)?'good':s.match(/pending|review|draft|waiting|scheduled|shortlisted|awaiting/i)?'warn':s.match(/reject|restrict|suspend|cancel|closed|failed|disabled/i)?'bad':''}

export default function AdminModule({eyebrow,title,copy,action,metrics,columns,initialRows,actions}:Props){
  const [rows,setRows]=useState<Row[]>(initialRows);
  const [query,setQuery]=useState('');
  const [selected,setSelected]=useState<number|null>(null);
  const [creating,setCreating]=useState(false);
  const [toast,setToast]=useState('');
  const [draft,setDraft]=useState<Row>({});
  const availableActions=actions??defaults[title]??[{label:'Mark approved',status:'Approved'},{label:'Archive',status:'Archived',danger:true}];
  const filtered=useMemo(()=>rows.map((row,index)=>({row,index})).filter(({row})=>Object.values(row).join(' ').toLowerCase().includes(query.toLowerCase())),[rows,query]);
  const current=selected===null?null:rows[selected];
  function notify(message:string){setToast(message);window.setTimeout(()=>setToast(''),2600)}
  function updateStatus(status?:string,label?:string){if(selected===null)return;if(status)setRows(old=>old.map((r,i)=>i===selected?{...r,status}:r));notify(`${label??'Record updated'} successfully`);if(status)setSelected(null)}
  function create(){const row:Row={};columns.forEach((c,i)=>row[c.key]=draft[c.key]|| (c.key==='status'?'Draft':i===0?'Untitled record':'—'));setRows(old=>[row,...old]);setDraft({});setCreating(false);notify(`${action} created`)}
  function exportCsv(){const csv=[columns.map(c=>c.label).join(','),...rows.map(r=>columns.map(c=>`"${String(r[c.key]??'').replaceAll('"','""')}"`).join(','))].join('\n');const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([csv],{type:'text/csv'}));a.download=`${title.toLowerCase().replaceAll(' ','-')}.csv`;a.click();URL.revokeObjectURL(a.href);notify('CSV export downloaded')}
  const isExport=/export/i.test(action);
  return <>
    {toast&&<div className="toast"><Check size={16}/>{toast}</div>}
    <div className="page-head"><div><div className="eyebrow">{eyebrow}</div><h1 className="page-title">{title}</h1><p className="page-copy">{copy}</p></div><button className="button primary" onClick={isExport?exportCsv:()=>setCreating(true)}>{isExport?<Download size={15}/>:<Plus size={15}/>} {action}</button></div>
    <MetricCards items={metrics}/>
    <div className="table-toolbar"><div className="table-search"><Search size={15}/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder={`Search ${title.toLowerCase()}…`}/></div><span>{filtered.length} records</span></div>
    <div className="card table-wrap"><table className="data-table"><thead><tr>{columns.map(c=><th key={c.key}>{c.label}</th>)}<th aria-label="Actions"/></tr></thead><tbody>{filtered.length?filtered.map(({row,index})=><tr key={index} className="click-row" onClick={()=>setSelected(index)}>{columns.map(c=><td key={c.key}>{c.key==='status'?<span className={`status ${badge(row[c.key])}`}>{row[c.key]}</span>:row[c.key]}</td>)}<td><button className="icon-button" aria-label="Open record" onClick={e=>{e.stopPropagation();setSelected(index)}}><ChevronRight size={17}/></button></td></tr>):<tr><td colSpan={columns.length+1}><div className="empty">No matching records.</div></td></tr>}</tbody></table></div>
    {(creating||current)&&<div className="modal-backdrop" onMouseDown={()=>{setCreating(false);setSelected(null)}}><section className="modal" onMouseDown={e=>e.stopPropagation()}>
      <header className="modal-head"><div><div className="eyebrow">{creating?'New record':'Record details'}</div><h2>{creating?action:String(current?.[columns[0].key]??title)}</h2></div><button className="icon-button" onClick={()=>{setCreating(false);setSelected(null)}}><X size={18}/></button></header>
      {creating?<div className="modal-body form-grid">{columns.filter(c=>c.key!=='status').map(c=><label className="field" key={c.key}><span>{c.label}</span><input value={String(draft[c.key]??'')} onChange={e=>setDraft(d=>({...d,[c.key]:e.target.value}))} placeholder={`Enter ${c.label.toLowerCase()}`}/></label>)}<label className="field"><span>Status</span><select value={String(draft.status??'Draft')} onChange={e=>setDraft(d=>({...d,status:e.target.value}))}><option>Draft</option><option>Active</option><option>Pending review</option><option>Published</option></select></label></div>:<div className="modal-body"><div className="detail-grid">{columns.map(c=><div className="detail" key={c.key}><span>{c.label}</span><strong>{current?.[c.key]??'—'}</strong></div>)}</div><label className="field"><span>Internal notes</span><textarea rows={4} placeholder="Add a private note for your team…"/></label></div>}
      <footer className="modal-actions">{creating?<><button className="button secondary" onClick={()=>setCreating(false)}>Cancel</button><button className="button primary" onClick={create}>Create record</button></>:<>{availableActions.map(a=><button key={a.label} className={`button ${a.danger?'danger':a.status?'primary':'secondary'}`} onClick={()=>updateStatus(a.status,a.label)}>{a.label}</button>)}</>}</footer>
    </section></div>}
  </>
}
