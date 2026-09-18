import {NextResponse} from 'next/server';
const gone=()=>NextResponse.json({error:'Experiences were retired in September 2026. Use Projects, Assets, Indexes, Releases and Collections.'},{status:410});
export const GET=gone; export const POST=gone; export const PATCH=gone; export const DELETE=gone;
