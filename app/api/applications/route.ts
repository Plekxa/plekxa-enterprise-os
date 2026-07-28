import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export const dynamic = 'force-dynamic';

type DbRow = Record<string, unknown>;

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  return url && key
    ? createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } })
    : null;
}

function message(error: unknown) {
  if (error instanceof Error) return error.message;
  if (error && typeof error === 'object' && 'message' in error) return String(error.message);
  return 'Database request failed.';
}

export async function GET() {
  try {
    const s = admin();
    if (!s) return NextResponse.json({ error: 'Supabase service credentials are not configured' }, { status: 503 });

    const { data: applications, error } = await s
      .from('creator_applications')
      .select('*')
      .order('applied_at', { ascending: false })
      .limit(250);
    if (error) throw error;

    const rows = applications ?? [];
    const projectIds = [...new Set(rows.map((r) => r.project_id).filter(Boolean))] as string[];
    const creatorIds = [...new Set(rows.map((r) => r.creator_id).filter(Boolean))] as string[];
    const userIds = [...new Set(rows.map((r) => r.creator_user_id).filter(Boolean))] as string[];

    const projects = projectIds.length
      ? await s.from('projects').select('*').in('id', projectIds)
      : { data: [], error: null };
    if (projects.error) throw projects.error;

    let creators: { data: DbRow[] | null; error: unknown } = { data: [], error: null };
    if (creatorIds.length || userIds.length) {
      const clauses = [
        creatorIds.length ? `id.in.(${creatorIds.join(',')})` : '',
        userIds.length ? `user_id.in.(${userIds.join(',')})` : '',
      ].filter(Boolean);
      creators = await s.from('creator_profiles').select('*').or(clauses.join(','));
      if (creators.error) throw creators.error;
    }

    const projectMap = new Map((projects.data ?? []).map((x) => [String(x.id), x]));
    const creatorMap = new Map<string, DbRow>();
    for (const creator of creators.data ?? []) {
      creatorMap.set(String(creator.id), creator);
      if (creator.user_id) creatorMap.set(String(creator.user_id), creator);
    }

    return NextResponse.json({
      applications: rows.map((application) => ({
        ...application,
        project: projectMap.get(String(application.project_id)) ?? null,
        creator: creatorMap.get(String(application.creator_id)) ?? creatorMap.get(String(application.creator_user_id)) ?? null,
      })),
    });
  } catch (error) {
    console.error('Admin applications GET error:', error);
    return NextResponse.json({ error: message(error) }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const s = admin();
    if (!s) return NextResponse.json({ error: 'Supabase service credentials are not configured' }, { status: 503 });
    const body = await request.json();
    const id = String(body.id || '');
    const status = String(body.status || '').toLowerCase();
    const allowed = ['pending', 'under_review', 'shortlisted', 'accepted', 'rejected', 'withdrawn'];
    if (!id || !allowed.includes(status)) return NextResponse.json({ error: 'A valid application and status are required.' }, { status: 400 });

    const update: Record<string, unknown> = { status, updated_at: new Date().toISOString() };
    if (['accepted', 'rejected'].includes(status)) update.reviewed_at = new Date().toISOString();
    if (body.reviewNotes !== undefined) update.review_notes = body.reviewNotes || null;
    if (body.rejectionReason !== undefined) update.rejection_reason = body.rejectionReason || null;

    const { data, error } = await s.from('creator_applications').update(update).eq('id', id).select('*').single();
    if (error) throw error;
    return NextResponse.json({ application: data });
  } catch (error) {
    console.error('Admin applications PATCH error:', error);
    return NextResponse.json({ error: message(error) }, { status: 500 });
  }
}
