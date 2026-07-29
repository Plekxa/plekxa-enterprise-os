'use client';

import { useEffect, useMemo, useState } from 'react';
import { Download, Search } from '@/components/icons';

type AnalyticsReport = {
  id: string;
  name?: string | null;
  department?: string | null;
  date_range?: string | null;
  format?: string | null;
  created_at?: string | null;
  [key: string]: unknown;
};

const departments = [
  'Executive overview',
  'Finance',
  'Marketing',
  'Creator operations',
  'Projects',
  'Content',
  'Experiences',
  'Support',
  'People',
];

const dateRanges = [
  'All periods',
  'Last 7 days',
  'Last 30 days',
  'This quarter',
  'This year',
];

function normalise(value: unknown) {
  return String(value ?? '')
    .trim()
    .toLowerCase()
    .replaceAll('_', ' ');
}

function displayValue(value: unknown) {
  const text = String(value ?? '').trim();

  if (!text) {
    return '—';
  }

  return text.replaceAll('_', ' ').replace(/\b\w/g, character =>
    character.toUpperCase(),
  );
}

export default function AnalyticsWorkspace() {
  const [reports, setReports] = useState<AnalyticsReport[]>([]);
  const [department, setDepartment] = useState('Executive overview');
  const [dateRange, setDateRange] = useState('All periods');
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function loadReports() {
    setLoading(true);
    setError('');

    try {
      const response = await fetch('/api/live/analytics', {
        cache: 'no-store',
      });

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.error || 'Could not load analytics reports.');
      }

      setReports(Array.isArray(result.records) ? result.records : []);
    } catch (loadError) {
      setError(
        loadError instanceof Error
          ? loadError.message
          : 'Could not load analytics reports.',
      );
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadReports();
  }, []);

  const departmentReports = useMemo(() => {
    const selectedDepartment = normalise(department);

    return reports.filter(report => {
      if (department === 'Executive overview') {
        return true;
      }

      const reportDepartment = normalise(report.department);

      if (department === 'Creator operations') {
        return (
          reportDepartment.includes('creator') ||
          reportDepartment.includes('creator operations')
        );
      }

      if (department === 'People') {
        return (
          reportDepartment.includes('people') ||
          reportDepartment.includes('human resources') ||
          reportDepartment.includes('hr')
        );
      }

      return reportDepartment.includes(selectedDepartment);
    });
  }, [reports, department]);

  const visibleReports = useMemo(() => {
    const searchTerm = normalise(query);

    return departmentReports.filter(report => {
      const matchesSearch =
        !searchTerm ||
        Object.values(report)
          .map(value => normalise(value))
          .join(' ')
          .includes(searchTerm);

      const matchesDateRange =
        dateRange === 'All periods' ||
        normalise(report.date_range).includes(normalise(dateRange));

      return matchesSearch && matchesDateRange;
    });
  }, [departmentReports, query, dateRange]);

  const departmentCounts = useMemo(() => {
    return departments.reduce<Record<string, number>>((counts, item) => {
      if (item === 'Executive overview') {
        counts[item] = reports.length;
        return counts;
      }

      const selected = normalise(item);

      counts[item] = reports.filter(report => {
        const reportDepartment = normalise(report.department);

        if (item === 'Creator operations') {
          return reportDepartment.includes('creator');
        }

        if (item === 'People') {
          return (
            reportDepartment.includes('people') ||
            reportDepartment.includes('human resources') ||
            reportDepartment === 'hr'
          );
        }

        return reportDepartment.includes(selected);
      }).length;

      return counts;
    }, {});
  }, [reports]);

  function exportCsv() {
    const headers = [
      'Report',
      'Department',
      'Date range',
      'Format',
      'Created',
    ];

    const rows = visibleReports.map(report => [
      report.name ?? '',
      report.department ?? '',
      report.date_range ?? '',
      report.format ?? '',
      report.created_at ?? '',
    ]);

    const csv = [headers, ...rows]
      .map(row =>
        row
          .map(value => `"${String(value).replaceAll('"', '""')}"`)
          .join(','),
      )
      .join('\n');

    const url = URL.createObjectURL(
      new Blob([csv], {
        type: 'text/csv;charset=utf-8',
      }),
    );

    const link = document.createElement('a');
    link.href = url;
    link.download = `plekxa-${normalise(department).replaceAll(' ', '-')}-analytics.csv`;
    link.click();

    URL.revokeObjectURL(url);
  }

  return (
    <>
      <div className="page-head">
        <div>
          <div className="eyebrow">Intelligence</div>
          <h1 className="page-title">Analytics</h1>

          <p className="page-copy">
            Review reports and operational intelligence across Plekxa.
          </p>
        </div>

        <div className="head-actions">
          <button
            type="button"
            className="button secondary"
            onClick={exportCsv}
            disabled={visibleReports.length === 0}
          >
            <Download size={15} />
            Export
          </button>
        </div>
      </div>

      {error && (
        <div className="integration-banner pending">
          <div>
            <strong>Analytics error</strong>
            <span>{error}</span>
          </div>
        </div>
      )}

      <div className="metric-grid">
        <article className="metric">
          <span>Total reports</span>
          <strong>{reports.length}</strong>
        </article>

        <article className="metric">
          <span>Selected area</span>
          <strong>{departmentCounts[department] ?? 0}</strong>
        </article>

        <article className="metric">
          <span>Visible reports</span>
          <strong>{visibleReports.length}</strong>
        </article>

        <article className="metric">
          <span>Departments</span>
          <strong>
            {
              new Set(
                reports
                  .map(report => normalise(report.department))
                  .filter(Boolean),
              ).size
            }
          </strong>
        </article>
      </div>

      <div className="workspace-card">
        <div className="module-toolbar">
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: '12px',
              width: '100%',
            }}
          >
            <label
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '6px',
                minWidth: '220px',
              }}
            >
              <span style={{ fontSize: '12px', fontWeight: 600 }}>
                Analytics area
              </span>

              <select
                value={department}
                onChange={event => setDepartment(event.target.value)}
              >
                {departments.map(item => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </label>

            <label
              style={{
                display: 'flex',
                flexDirection: 'column',
                gap: '6px',
                minWidth: '180px',
              }}
            >
              <span style={{ fontSize: '12px', fontWeight: 600 }}>
                Date range
              </span>

              <select
                value={dateRange}
                onChange={event => setDateRange(event.target.value)}
              >
                {dateRanges.map(item => (
                  <option key={item} value={item}>
                    {item}
                  </option>
                ))}
              </select>
            </label>

            <div
              className="table-search"
              style={{
                alignSelf: 'flex-end',
                flex: '1 1 240px',
              }}
            >
              <Search size={15} />

              <input
                value={query}
                onChange={event => setQuery(event.target.value)}
                placeholder="Search reports…"
              />
            </div>

            <button
              type="button"
              className="button secondary"
              style={{ alignSelf: 'flex-end' }}
              onClick={() => void loadReports()}
            >
              Refresh
            </button>
          </div>
        </div>

        <div
          style={{
            padding: '20px 24px 4px',
          }}
        >
          <div className="eyebrow">{department}</div>

          <h2
            style={{
              margin: '6px 0 4px',
              fontSize: '22px',
            }}
          >
            {department} analytics
          </h2>

          <p
            style={{
              margin: 0,
              opacity: 0.7,
            }}
          >
            {department === 'Executive overview'
              ? 'Reports from every part of the company.'
              : `Reports assigned to ${department}.`}
          </p>
        </div>

        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>Report</th>
                <th>Department</th>
                <th>Date range</th>
                <th>Format</th>
                <th>Created</th>
              </tr>
            </thead>

            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={5}>Loading analytics reports…</td>
                </tr>
              ) : visibleReports.length === 0 ? (
                <tr>
                  <td colSpan={5}>
                    No reports are available for this analytics area.
                  </td>
                </tr>
              ) : (
                visibleReports.map(report => (
                  <tr key={report.id}>
                    <td>
                      <strong>{displayValue(report.name)}</strong>
                    </td>

                    <td>{displayValue(report.department)}</td>
                    <td>{displayValue(report.date_range)}</td>
                    <td>{displayValue(report.format)}</td>

                    <td>
                      {report.created_at
                        ? new Date(report.created_at).toLocaleDateString(
                            'en-GB',
                          )
                        : '—'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}