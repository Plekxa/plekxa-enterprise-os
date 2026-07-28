'use client';

import { useEffect, useMemo, useState } from 'react';

type ApplicationRow = {
  id: string;
  status?: string;
  applied_at?: string;
  cover_letter?: string;
  portfolio_url?: string;
  creator_user_id?: string;
  creator?: {
    stage_name?: string;
    legal_name?: string;
    full_name?: string;
    email?: string;
  } | null;
  project?: {
    title?: string;
    name?: string;
  } | null;
};

type IconProps = {
  size?: number;
};

function CheckIcon({ size = 16 }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 6 9 17l-5-5" />
    </svg>
  );
}

function ChevronRightIcon({ size = 16 }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="m9 18 6-6-6-6" />
    </svg>
  );
}

function RefreshIcon({ size = 16 }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M20 11a8.1 8.1 0 0 0-15.5-2M4 4v5h5" />
      <path d="M4 13a8.1 8.1 0 0 0 15.5 2M20 20v-5h-5" />
    </svg>
  );
}

function CloseIcon({ size = 16 }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M18 6 6 18" />
      <path d="m6 6 12 12" />
    </svg>
  );
}

const labels: Record<string, string> = {
  pending: 'Pending review',
  under_review: 'Under review',
  shortlisted: 'Shortlisted',
  accepted: 'Accepted',
  rejected: 'Rejected',
  withdrawn: 'Withdrawn',
};

export default function ApplicationsWorkspace() {
  const [items, setItems] = useState<ApplicationRow[]>([]);
  const [selected, setSelected] = useState<ApplicationRow | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const loadApplications = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/applications', {
        cache: 'no-store',
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.error || 'Could not load applications.');
      }

      setItems(data.applications || []);
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Could not load applications.',
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadApplications();
  }, []);

  const counts = useMemo(
    () => ({
      total: items.length,
      pending: items.filter((item) =>
        ['pending', 'under_review'].includes(item.status || ''),
      ).length,
      shortlisted: items.filter(
        (item) => item.status === 'shortlisted',
      ).length,
      accepted: items.filter(
        (item) => item.status === 'accepted',
      ).length,
    }),
    [items],
  );

  const updateApplication = async (status: string) => {
    if (!selected) return;

    setSaving(true);
    setError('');

    try {
      const response = await fetch('/api/applications', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          id: selected.id,
          status,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(
          data.error || 'Could not update application.',
        );
      }

      const updatedApplication: ApplicationRow = {
        ...selected,
        ...data.application,
        status,
      };

      setSelected(updatedApplication);

      setItems((currentItems) =>
        currentItems.map((item) =>
          item.id === updatedApplication.id
            ? updatedApplication
            : item,
        ),
      );
    } catch (err) {
      setError(
        err instanceof Error
          ? err.message
          : 'Could not update application.',
      );
    } finally {
      setSaving(false);
    }
  };

  const getCreatorName = (application: ApplicationRow) =>
    application.creator?.stage_name ||
    application.creator?.legal_name ||
    application.creator?.full_name ||
    application.creator?.email ||
    application.creator_user_id ||
    'Unknown creator';

  const getProjectName = (application: ApplicationRow) =>
    application.project?.title ||
    application.project?.name ||
    'Unknown project';

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Creator operations</div>
          <h1 className="page-title">Applications</h1>
          <p className="page-copy">
            Review and decide creator applications submitted through
            Plekxa Studio.
          </p>
        </div>

        <button
          type="button"
          className="button secondary"
          onClick={() => void loadApplications()}
          disabled={loading}
        >
          <RefreshIcon size={16} />
          Refresh
        </button>
      </div>

      {error && (
        <div className="integration-banner pending">
          <div>
            <strong>Database error</strong>
            <span>{error}</span>
          </div>
        </div>
      )}

      <div className="metric-grid">
        <article className="metric">
          <span>Total</span>
          <strong>{counts.total}</strong>
        </article>

        <article className="metric">
          <span>Awaiting review</span>
          <strong>{counts.pending}</strong>
        </article>

        <article className="metric">
          <span>Shortlisted</span>
          <strong>{counts.shortlisted}</strong>
        </article>

        <article className="metric">
          <span>Accepted</span>
          <strong>{counts.accepted}</strong>
        </article>
      </div>

      <div className="workspace-card">
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Creator</th>
                <th>Project</th>
                <th>Submitted</th>
                <th>Status</th>
                <th aria-label="Open application" />
              </tr>
            </thead>

            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5}>Loading applications…</td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    No applications found in the shared database.
                  </td>
                </tr>
              ) : (
                items.map((application) => (
                  <tr
                    key={application.id}
                    className="click-row"
                    onClick={() => setSelected(application)}
                  >
                    <td>
                      <strong>{getCreatorName(application)}</strong>
                      <small className="table-sub">
                        {application.creator?.email || ''}
                      </small>
                    </td>

                    <td>{getProjectName(application)}</td>

                    <td>
                      {application.applied_at
                        ? new Date(
                            application.applied_at,
                          ).toLocaleDateString('en-GB')
                        : '—'}
                    </td>

                    <td>
                      <span
                        className={`status ${
                          application.status === 'accepted'
                            ? 'good'
                            : 'warn'
                        }`}
                      >
                        {labels[application.status || ''] ||
                          application.status ||
                          'Unknown'}
                      </span>
                    </td>

                    <td>
                      <ChevronRightIcon size={16} />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {selected && (
        <div
          className="drawer-backdrop"
          onMouseDown={() => setSelected(null)}
        >
          <aside
            className="record-drawer"
            onMouseDown={(event) => event.stopPropagation()}
          >
            <header className="drawer-head">
              <div>
                <div className="eyebrow">Application</div>
                <h2>{getCreatorName(selected)}</h2>
                <p>{getProjectName(selected)}</p>
              </div>
            </header>

            <div className="drawer-body">
              <div className="detail-grid">
                <div className="detail">
                  <span>Status</span>
                  <strong>
                    {labels[selected.status || ''] ||
                      selected.status ||
                      'Unknown'}
                  </strong>
                </div>

                <div className="detail">
                  <span>Portfolio</span>
                  <strong>
                    {selected.portfolio_url ? (
                      <a
                        href={selected.portfolio_url}
                        target="_blank"
                        rel="noreferrer"
                      >
                        Open portfolio
                      </a>
                    ) : (
                      'Not supplied'
                    )}
                  </strong>
                </div>
              </div>

              <h3>Cover letter</h3>
              <p>
                {selected.cover_letter ||
                  'No cover letter supplied.'}
              </p>
            </div>

            <footer className="drawer-actions">
              <button
                type="button"
                disabled={saving}
                className="button secondary"
                onClick={() =>
                  void updateApplication('rejected')
                }
              >
                <CloseIcon size={16} />
                Reject
              </button>

              <button
                type="button"
                disabled={saving}
                className="button secondary"
                onClick={() =>
                  void updateApplication('shortlisted')
                }
              >
                Shortlist
              </button>

              <button
                type="button"
                disabled={saving}
                className="button primary"
                onClick={() =>
                  void updateApplication('accepted')
                }
              >
                <CheckIcon size={16} />
                Accept
              </button>
            </footer>
          </aside>
        </div>
      )}
    </>
  );
}