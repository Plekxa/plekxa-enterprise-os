import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { sendMail } from '@/lib/mail';

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

async function authIdentity(s: any, userId: string) {
  const { data, error } = await s.auth.admin.getUserById(userId);
  if (error || !data.user) return null;
  const metadata = data.user.user_metadata ?? {};
  return {
    user_id: data.user.id,
    legal_name: metadata.full_name || metadata.name || null,
    stage_name: metadata.stage_name || null,
    email: data.user.email || null,
  };
}

async function notifyDecision(
  s: any,
  application: DbRow,
  status: string,
  projectTitle: string,
  reason?: string | null,
) {
  const userId = String(application.creator_user_id || '');
  if (!userId) return { notified: false, emailed: false, reason: 'Application has no creator_user_id.' };

  const accepted = status === 'accepted';
  const shortlisted = status === 'shortlisted';
  const title = accepted
    ? 'Your Plekxa application was accepted'
    : shortlisted
      ? 'Your Plekxa application was shortlisted'
      : 'Update on your Plekxa application';
  const messageText = accepted
    ? `Your application for ${projectTitle} has been accepted.`
    : shortlisted
      ? `Your application for ${projectTitle} has been shortlisted for further review.`
      : `Your application for ${projectTitle} was not selected.${reason ? ` Reason: ${reason}` : ''}`;

  const { error: notificationError } = await (s.from('notifications') as any).insert({
    recipient_id: userId,
    type: 'application_decision',
    title,
    message: messageText,
    action_url: '/applications',
    entity_type: 'creator_application',
    entity_id: application.id,
    metadata: { status, project_title: projectTitle },
  });

  const identity = await authIdentity(s, userId);
  let mail: { sent: boolean; reason?: string } = { sent: false, reason: 'No email address available.' };
  if (identity?.email) {
    try {
      mail = await sendMail({
        to: identity.email,
        subject: title,
        text: `${messageText}

Sign in to Plekxa Studio to view the application: ${process.env.NEXT_PUBLIC_STUDIO_URL || 'https://studio.plekxa.com'}/applications`,
      });
    } catch (error) {
      mail = { sent: false, reason: message(error) };
    }
  }

  return {
    notified: !notificationError,
    emailed: mail.sent,
    reason: notificationError?.message || mail.reason,
  };
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

    for (const userId of userIds) {
      if (!creatorMap.has(userId)) {
        const identity = await authIdentity(s, userId);
        if (identity) creatorMap.set(userId, identity);
      }
    }

    const milestoneResult = projectIds.length
      ? await s.from('project_milestones').select('*').in('project_id', projectIds).order('position', { ascending: true })
      : { data: [], error: null };
    if (milestoneResult.error) throw milestoneResult.error;
    const deliverableResult = projectIds.length
      ? await s.from('project_deliverables').select('*').in('project_id', projectIds).order('created_at', { ascending: true })
      : { data: [], error: null };
    if (deliverableResult.error) throw deliverableResult.error;
    const deliverableIds = (deliverableResult.data ?? []).map((x) => x.id);
    const fileResult = deliverableIds.length
      ? await s.from('project_files').select('*').in('deliverable_id', deliverableIds).order('created_at', { ascending: false })
      : { data: [], error: null };
    if (fileResult.error) throw fileResult.error;

    return NextResponse.json({
      applications: rows.map((application) => {
        const projectId = String(application.project_id || '');
        const creatorId = String(application.creator_id || '');
        const creatorUserId = String(application.creator_user_id || '');
        const milestones = (milestoneResult.data ?? []).filter((x) => String(x.project_id) === projectId);
        const deliverables = (deliverableResult.data ?? []).filter((x) => {
          if (String(x.project_id) !== projectId) return false;
          if (x.assignee_creator_id && creatorId) return String(x.assignee_creator_id) === creatorId;
          if (x.assignee_user_id && creatorUserId) return String(x.assignee_user_id) === creatorUserId;
          return true;
        }).map((d) => ({...d, files:(fileResult.data ?? []).filter((f) => String(f.deliverable_id) === String(d.id))}));
        return {
          ...application,
          project: projectMap.get(projectId) ?? null,
          creator: creatorMap.get(creatorId) ?? creatorMap.get(creatorUserId) ?? {
            legal_name: application.applicant_name || null,
            email: application.applicant_email || null,
          },
          milestones,
          deliverables,
        };
      }),
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

    let delivery = null;
    if (['accepted', 'rejected', 'shortlisted'].includes(status)) {
      const { data: project } = data.project_id
        ? await s.from('projects').select('*').eq('id', data.project_id).maybeSingle()
        : { data: null };
      const projectTitle = String(project?.title || project?.name || 'your selected project');
      delivery = await notifyDecision(s, data, status, projectTitle, String(body.rejectionReason || '') || null);
    }

    return NextResponse.json({ application: data, delivery });
  } catch (error) {
    console.error('Admin applications PATCH error:', error);
    return NextResponse.json({ error: message(error) }, { status: 500 });
  }
}
