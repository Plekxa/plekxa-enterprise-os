'use client';

import { Bell, Search } from '@/components/icons';
import { useRouter } from 'next/navigation';
import { FormEvent, useState } from 'react';

export default function Topbar() {
  const [q, setQ] = useState('');
  const [notificationOpen, setNotificationOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);

  const router = useRouter();

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const searchTerm = q.trim();

    if (!searchTerm) {
      return;
    }

    router.push(`/projects?search=${encodeURIComponent(searchTerm)}`);
  }

  function navigateTo(path: string) {
    setNotificationOpen(false);
    setProfileOpen(false);
    router.push(path);
  }

  function logout() {
    localStorage.clear();
    sessionStorage.clear();

    document.cookie.split(';').forEach((cookie) => {
      document.cookie = cookie
        .replace(/^ +/, '')
        .replace(
          /=.*/,
          `=;expires=${new Date(0).toUTCString()};path=/`,
        );
    });

    setNotificationOpen(false);
    setProfileOpen(false);

    router.replace('/login');
    router.refresh();
  }

  return (
    <header className="topbar">
      <form className="search" onSubmit={submit}>
        <Search size={15} />

        <input
          suppressHydrationWarning
          value={q}
          onChange={(event) => setQ(event.target.value)}
          placeholder="Search projects, creators, content…"
          aria-label="Search"
        />
      </form>

      <div className="user-chip">
        <button
          suppressHydrationWarning
          type="button"
          className="icon-button notification-button"
          onClick={() => {
            setNotificationOpen((current) => !current);
            setProfileOpen(false);
          }}
          aria-label="Notifications"
          aria-expanded={notificationOpen}
        >
          <Bell size={18} />
          <i />
        </button>

        <button
          suppressHydrationWarning
          type="button"
          className="profile-button"
          onClick={() => {
            setProfileOpen((current) => !current);
            setNotificationOpen(false);
          }}
          aria-label="Open account menu"
          aria-expanded={profileOpen}
        >
          <div className="avatar">AI</div>
          <span>Anthony Ighomena</span>
        </button>

        {notificationOpen && (
          <div className="notification-popover">
            <strong>Notifications</strong>

            <p>3 applications are awaiting review.</p>
            <p>A newsroom draft is ready for approval.</p>

            <button
              suppressHydrationWarning
              type="button"
              className="button secondary"
              onClick={() => navigateTo('/notifications')}
            >
              View all
            </button>
          </div>
        )}

        {profileOpen && (
          <div className="profile-popover">
            <div className="profile-header">
              <div className="avatar large">AI</div>

              <div>
                <strong>Anthony Ighomena</strong>
                <p>Master Administrator</p>
              </div>
            </div>

            <hr />

            <button
              type="button"
              className="menu-item"
              onClick={() => navigateTo('/profile')}
            >
              My Profile
            </button>

            <button
              type="button"
              className="menu-item"
              onClick={() => navigateTo('/settings')}
            >
              Account Settings
            </button>

            <button
              type="button"
              className="menu-item"
              onClick={() => navigateTo('/notifications')}
            >
              Notifications
            </button>

            <hr />

            <button
              type="button"
              className="menu-item danger"
              onClick={logout}
            >
              Sign Out
            </button>
          </div>
        )}
      </div>
    </header>
  );
}