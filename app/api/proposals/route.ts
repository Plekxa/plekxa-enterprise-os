import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { sendMail } from '@/lib/mail';

export const dynamic = 'force-dynamic';

type Row = Record<string, any>;

function admin() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  return url && key ? createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } }) : null;
}

function msg(error: unknown) {
  if (error instanceof Error) return error.message;
  if (error && typeof error === 'object' && 'message' in error) return String(error.message);
  return 'Proposal request failed.';
}

async function identity(s: NonNullable<ReturnType<typeof admin>>, userId: string) {
  const { data, error } = await s.auth.admin.getUserById(userId);
  if (error || !data.user) return null;
  const metadata = data.user.user_metadata ?? {};
  return { user_id: userId, legal_name: metadata.full_name || metadata.name || null, email: data.user.email || null };
}

export async function GET() {
  try {
    const s = admin();
    if (!s) return NextResponse.json({ error: 'Supabase service credentials are not configured.' }, { status: 503 });
    const { data, error } = await s.from('proposals').select('*').order('created_at', { ascending: false }).limit(250);
    if (error) throw error;
    const rows = data ?? [];
    const userIds = [...new Set(rows.map((r) => r.creator_user_id).filter(Boolean))] as string[];
    const creatorIds = [...new Set(rows.map((r) => r.creator_id).filter(Boolean))] as string[];
    let creators: Row[] = [];
    if (userIds.length || creatorIds.length) {
      const filters = [userIds.length ? `user_id.in.(${userIds.join(',')})` : '', creatorIds.length ? `id.in.(${creatorIds.join(',')})` : ''].filter(Boolean);
      const result = await s.from('creator_profiles').select('*').or(filters.join(','));
      if (result.error) throw result.error;
      creators = result.data ?? [];
    }
    const map = new Map<string, Row>();
    creators.forEach((c) => { map.set(String(c.id), c); if (c.user_id) map.set(String(c.user_id), c); });
    for (const userId of userIds) if (!map.has(userId)) { const auth = await identity(s, userId); if (auth) map.set(userId, auth); }
    return NextResponse.json({ proposals: rows.map((r) => ({ ...r, creator: map.get(String(r.creator_user_id)) || map.get(String(r.creator_id)) || null })) });
  } catch (error) {
    console.error('Admin proposals GET error:', error);
    return NextResponse.json({ error: msg(error) }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const s = admin();
    if (!s) return NextResponse.json({ error: 'Supabase service credentials are not configured.' }, { status: 503 });
    const body = await request.json();
    const id = String(body.id || '');
    const status = String(body.status || '').toLowerCase();
    const allowed = ['submitted', 'under_review', 'approved', 'held', 'rejected'];
    if (!id || !allowed.includes(status)) return NextResponse.json({ error: 'A valid proposal and status are required.' }, { status: 400 });
    const { data, error } = await s.from('proposals').update({ status, review_notes: body.reviewNotes || null, reviewed_at: new Date().toISOString(), updated_at: new Date().toISOString() }).eq('id', id).select('*').single();
    if (error) throw error;

    let delivery = null;
    const userId = data.creator_user_id as string | undefined;
    if (userId && ['approved', 'held', 'rejected'].includes(status)) {
      const title = status === 'approved' ? 'Your Plekxa proposal was approved' : status === 'held' ? 'Your Plekxa proposal is being held for future review' : 'Update on your Plekxa proposal';
      const text = status === 'approved' ? `Your proposal “${data.title}” has been approved.` : status === 'held' ? `Your proposal “${data.title}” has been placed on hold for future review.` : `Your proposal “${data.title}” was not selected.${body.reviewNotes ? ` Feedback: ${body.reviewNotes}` : ''}`;
      const notification = await (s.from('notifications') as any).insert({ recipient_id: userId, type: 'proposal_decision', title, message: text, action_url: '/proposals', entity_type: 'proposal', entity_id: data.id, metadata: { status } });
      const auth = await identity(s, userId);
      let mail = { sent: false, reason: 'No email available.' };
      if (auth?.email) {
        try { mail = await sendMail({ to: auth.email, subject: title, text: `${text}\n\nView your proposals: ${process.env.NEXT_PUBLIC_STUDIO_URL || 'https://studio.plekxa.com'}/proposals` }); }
        catch (e) { mail = { sent: false, reason: msg(e) }; }
      }
      delivery = { notified: !notification.error, emailed: mail.sent, reason: notification.error?.message || mail.reason };
    }
    return NextResponse.json({ proposal: data, delivery });
  } catch (error) {
    console.error('Admin proposals PATCH error:', error);
    return NextResponse.json({ error: msg(error) }, { status: 500 });
  }
}
