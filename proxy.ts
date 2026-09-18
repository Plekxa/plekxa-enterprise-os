import { createServerClient } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function proxy(request: NextRequest) {
  const path=request.nextUrl.pathname;
  const publicPath=path==='/login'||path==='/accept-invite'||path.startsWith('/api/auth/accept-invite');
  if(publicPath)return NextResponse.next();
  let response=NextResponse.next({request});
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY||process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
  if(!url||!key)return NextResponse.json({error:'Authentication is not configured.'},{status:503});
  const supabase=createServerClient(url,key,{cookies:{getAll:()=>request.cookies.getAll(),setAll:(items)=>{items.forEach(({name,value})=>request.cookies.set(name,value));response=NextResponse.next({request});items.forEach(({name,value,options})=>response.cookies.set(name,value,options));}}});
  const {data:{user}}=await supabase.auth.getUser();
  if(!user){
    if(path.startsWith('/api/'))return NextResponse.json({error:'Not authenticated.'},{status:401});
    const login=request.nextUrl.clone();login.pathname='/login';login.searchParams.set('next',path);return NextResponse.redirect(login);
  }
  return response;
}
export const config={matcher:['/((?!_next/static|_next/image|favicon.ico|icon.png|apple-icon.png).*)']};
