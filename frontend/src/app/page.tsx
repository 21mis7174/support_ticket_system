'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import type { Ticket, CreateTicketPayload } from '@/types/ticket';
import { fetchTickets, createTicket, resolveTicket } from '@/lib/api';
import { CreateTicketForm } from '@/components/CreateTicketForm';
import { TicketCard } from '@/components/TicketCard';

type FilterStatus = 'all' | 'open' | 'resolved';

export default function HomePage() {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [filter, setFilter] = useState<FilterStatus>('all');
  const [search, setSearch] = useState('');
  const [priorityFilter, setPriorityFilter] = useState<'all' | 'low' | 'medium' | 'high'>('all');
  const [showForm, setShowForm] = useState(false);
  const hasFetched = useRef(false);

  const loadTickets = useCallback(async () => {
    setFetchError(null);
    try {
      const data = await fetchTickets();
      setTickets(data.tickets);
    } catch (err) {
      setFetchError(err instanceof Error ? err.message : 'Failed to load tickets.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (hasFetched.current) return;
    hasFetched.current = true;
    loadTickets();
  }, [loadTickets]);

  async function handleCreateTicket(payload: CreateTicketPayload) {
    const ticket = await createTicket(payload);
    setTickets((prev) => [ticket, ...prev]);
    setShowForm(false);
  }

  async function handleResolveTicket(id: string) {
    const updated = await resolveTicket(id);
    setTickets((prev) => prev.map((t) => (t.id === updated.id ? updated : t)));
  }

  const openCount = tickets.filter((t) => t.status === 'open').length;
  const resolvedCount = tickets.filter((t) => t.status === 'resolved').length;

  const filteredTickets = tickets.filter((t) => {
    const matchesStatus = filter === 'all' || t.status === filter;
    const matchesPriority = priorityFilter === 'all' || t.priority === priorityFilter;
    const q = search.toLowerCase();
    const matchesSearch = !q || t.title.toLowerCase().includes(q) || t.description.toLowerCase().includes(q);
    return matchesStatus && matchesPriority && matchesSearch;
  });

  return (
    <div className="min-h-screen" style={{ background: '#F1F5F9' }}>

      {/* Header */}
      <header style={{ background: 'linear-gradient(to right, #134E5E, #0D9488)', boxShadow: '0 2px 10px rgba(0,0,0,0.25)', position: 'sticky', top: 0, zIndex: 20 }}>
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: 'rgba(255,255,255,0.18)' }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2z"/>
                <path d="M13 5v2"/><path d="M13 17v2"/><path d="M13 11v2"/>
              </svg>
            </div>
            <span className="text-white font-bold tracking-widest text-sm uppercase">Support Tickets</span>
          </div>
          <div className="flex items-center gap-3">
            <button className="w-9 h-9 flex items-center justify-center rounded-lg" style={{ background: 'rgba(255,255,255,0.1)' }} aria-label="Search">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
            </button>
            <button className="w-9 h-9 flex items-center justify-center rounded-lg" style={{ background: 'rgba(255,255,255,0.1)' }} aria-label="Notifications">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
            </button>
            <div className="w-9 h-9 rounded-full flex items-center justify-center" style={{ background: 'rgba(255,255,255,0.2)', border: '2px solid rgba(255,255,255,0.35)' }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
            </div>
          </div>
        </div>
      </header>

      {/* Modal overlay for Create Ticket form */}
      {showForm && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center p-4"
          style={{ background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)' }}
          onClick={(e) => { if (e.target === e.currentTarget) setShowForm(false); }}
        >
          <div className="w-full max-w-lg relative">
            <button
              onClick={() => setShowForm(false)}
              className="absolute -top-3 -right-3 z-10 w-8 h-8 rounded-full flex items-center justify-center text-white font-bold"
              style={{ background: '#374151' }}
              aria-label="Close form"
            >
              ×
            </button>
            <CreateTicketForm onSubmit={handleCreateTicket} />
          </div>
        </div>
      )}

      {/* Main content */}
      <main className="max-w-7xl mx-auto px-6 py-8">

        {/* Stat cards */}
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="rounded-xl p-5 flex items-center gap-4" style={{ background: '#2563EB', color: 'white' }}>
            <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ background: 'rgba(255,255,255,0.2)' }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2z"/>
                <path d="M13 5v2"/><path d="M13 17v2"/><path d="M13 11v2"/>
              </svg>
            </div>
            <div>
              <p className="text-sm" style={{ opacity: 0.85 }}>Open Tickets</p>
              <p className="text-3xl font-bold">{openCount}</p>
            </div>
          </div>
          <div className="rounded-xl p-5 flex items-center gap-4" style={{ background: '#16A34A', color: 'white' }}>
            <div className="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0" style={{ background: 'rgba(255,255,255,0.2)' }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><path d="m9 11 3 3L22 4"/>
              </svg>
            </div>
            <div>
              <p className="text-sm" style={{ opacity: 0.85 }}>Resolved Tickets</p>
              <p className="text-3xl font-bold">{resolvedCount}</p>
            </div>
          </div>
        </div>

        {/* Filter tabs row + New Ticket button */}
        <div className="flex items-center justify-between mb-4" style={{ borderBottom: '1px solid #E2E8F0' }}>
          <div className="flex">
            {(['all', 'open', 'resolved'] as FilterStatus[]).map((f) => {
              const label = f === 'all' ? `All (${tickets.length})` : f === 'open' ? `Open (${openCount})` : `Resolved (${resolvedCount})`;
              return (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className="px-5 py-3 text-sm font-semibold capitalize"
                  style={{
                    color: filter === f ? '#0D9488' : '#6B7280',
                    background: 'transparent',
                    border: 'none',
                    borderBottom: filter === f ? '2px solid #0D9488' : '2px solid transparent',
                    marginBottom: '-1px',
                    cursor: 'pointer',
                  }}
                >
                  {label}
                </button>
              );
            })}
          </div>
          <button
            onClick={() => setShowForm(true)}
            className="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold text-white mb-2"
            style={{ background: '#0D9488' }}
            onMouseEnter={(e) => { e.currentTarget.style.background = '#0F766E'; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = '#0D9488'; }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M12 5v14"/><path d="M5 12h14"/></svg>
            New Ticket
          </button>
        </div>

        {/* Search + filter bar */}
        <div className="flex items-center gap-3 mb-4">
          <div className="flex-1 relative">
            <svg className="absolute left-3 top-1/2 -translate-y-1/2" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9CA3AF" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
            </svg>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search tickets by title or description..."
              style={{ width: '100%', paddingLeft: '36px', paddingRight: '12px', paddingTop: '9px', paddingBottom: '9px', borderRadius: '8px', border: '1px solid #E2E8F0', background: 'white', fontSize: '14px', color: '#111827', outline: 'none' }}
              onFocus={(e) => { e.target.style.borderColor = '#0D9488'; e.target.style.boxShadow = '0 0 0 2px rgba(13,148,136,0.15)'; }}
              onBlur={(e) => { e.target.style.borderColor = '#E2E8F0'; e.target.style.boxShadow = 'none'; }}
            />
          </div>
          <select
            value={priorityFilter}
            onChange={(e) => setPriorityFilter(e.target.value as typeof priorityFilter)}
            style={{ padding: '9px 12px', borderRadius: '8px', border: '1px solid #E2E8F0', background: 'white', fontSize: '14px', color: '#374151', outline: 'none', cursor: 'pointer' }}
          >
            <option value="all">All Priorities</option>
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low</option>
          </select>
        </div>

        {/* Loading */}
        {loading && (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="rounded-xl h-20 animate-shimmer" style={{ border: '1px solid #E2E8F0' }} />
            ))}
          </div>
        )}

        {/* Error */}
        {!loading && fetchError && (
          <div className="rounded-xl p-6 text-center" style={{ background: '#FEF2F2', border: '1px solid #FECACA' }}>
            <p className="text-sm font-medium mb-3" style={{ color: '#DC2626' }}>{fetchError}</p>
            <button onClick={loadTickets} className="text-xs font-semibold px-4 py-2 rounded-lg" style={{ background: '#DC2626', color: 'white' }}>Retry</button>
          </div>
        )}

        {/* Empty state */}
        {!loading && !fetchError && filteredTickets.length === 0 && (
          <div className="rounded-xl p-16 text-center" style={{ background: 'white', border: '1px solid #E2E8F0' }}>
            <div className="w-20 h-20 rounded-2xl mx-auto mb-5 flex items-center justify-center" style={{ background: '#F0FDFA' }}>
              <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#0D9488" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
                <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"/>
                <polyline points="14 2 14 8 20 8"/>
                <line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><line x1="10" y1="9" x2="8" y2="9"/>
              </svg>
            </div>
            <p className="text-xl font-bold mb-2" style={{ color: '#0F172A' }}>No tickets found</p>
            <p className="text-sm" style={{ color: '#6B7280' }}>Try adjusting your filters or create a new ticket.</p>
          </div>
        )}

        {/* Ticket list */}
        {!loading && !fetchError && filteredTickets.length > 0 && (
          <div className="space-y-2">
            {filteredTickets.map((ticket) => (
              <TicketCard key={ticket.id} ticket={ticket} onResolve={handleResolveTicket} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
