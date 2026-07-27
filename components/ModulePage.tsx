import EnterpriseModule from './EnterpriseModule';
import {genericConfigs,moduleConfigs} from '@/lib/module-data';
export default function ModulePage({slug}:{slug:string}){const config=moduleConfigs[slug]||genericConfigs[slug];return <EnterpriseModule config={config}/>}
