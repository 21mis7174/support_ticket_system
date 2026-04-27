'use client';

import { useState } from 'react';
import type { Ticket } from '@/types/ticket';

interface TicketCardProps {
  ticket: Ticket;
  onResolve: (id: string) => Promise<void>;
}

function timeAgo(iso: string): string {
  // Ensure timestamp is treated as UTC (add Z if not present)
  const utcIso = iso.endsWith('Z') ? iso : iso + 'Z';
  const diff = Date.now() - new Date(utcIso).getTime();
  const minutes = Math.floor(diff / 60000);
  const hours = Math.floor(diff / 3600000);
  const days = Math.floor(diff / 86400000);
  if (days > 0) return `${days}d ago`;
  if (hours > 0) return `${hours}h ago`;
  if (minutes > 0) return `${minutes}m ago`;
  return 'just now';
}

const PRIORITY_COLORS: Record<string, { bg: string; text: string }> = {
  high:   { bg: '#DC2626', text: '#ffffff' },
  medium: { bg: '#EA580C', text: '#ffffff' },
  low:    { bg: '#16A34A', text: '#ffffff' },
};

const STATUS_STYLES: Record<string, { bg: string; text: string }> = {
  open:     { bg: '#DBEAFE', text: '#1E40AF' },
  resolved: { bg: '#DCFCE7', text: '#15803D' },
};

const BORDER_COLORS: Record<string, string> = {
  high: '#DC2626', medium: '#EA580C', low: '#16A34A',
};

export function TicketCard({ ticket, onResolve }: TicketCardProps) {
  const [resolving, setResolving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expanded, setExpanded] = useState(false);

  async function handleResolve() {
    if (resolving || ticket.status === 'resolved') return;
    setResolving(true);
    setError(null);
    try {
      await onResolve(ticket.id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to resolve ticket.');
    } finally {
      setResolving(false);
    }
  }

  const priority = PRIORITY_COLORS[ticket.priority] ?? PRIORITY_COLORS.low;
  const statusStyle = STATUS_STYLES[ticket.status] ?? STATUS_STYLES.open;
  const borderColor = BORDER_COLORS[ticket.priority] ?? '#6B7280';
  const isLong = ticket.description.length > 100;

  return (
    <div
      style={{
        background: ticket.status === 'resolved' ? '#F0FDF4' : 'white',
        border: '1px solid ' + (ticket.status === 'resolved' ? '#BBF7D0' : '#E2E8F0'),
        borderLeft: `4px solid ${borderColor}`,
        borderRadius: '12px',
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        padding: '14px 16px',
      }}
    >
      {/* Main row: priority pill | title+description | right column */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: '12px' }}>

        {/* Priority pill */}
        <span
          style={{
            background: priority.bg, color: priority.text,
            fontSize: '11px', fontWeight: 700, padding: '3px 10px',
            borderRadius: '20px', flexShrink: 0, marginTop: '2px',
            textTransform: 'capitalize', letterSpacing: '0.03em',
          }}
        >
          {ticket.priority}
        </span>

        {/* Middle: title + description */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <p style={{ fontSize: '14px', fontWeight: 600, color: '#111827', marginBottom: '4px', lineHeight: 1.4 }}>
            {ticket.title}
          </p>
          <p
            style={{
              fontSize: '13px', color: '#6B7280', lineHeight: 1.5,
              overflow: expanded ? 'visible' : 'hidden',
              display: expanded ? 'block' : '-webkit-box',
              WebkitLineClamp: expanded ? undefined : 1,
              WebkitBoxOrient: 'vertical' as const,
            }}
          >
            {ticket.description}
          </p>
          {isLong && (
            <button
              onClick={() => setExpanded((p) => !p)}
              style={{ fontSize: '12px', color: '#0D9488', background: 'none', border: 'none', padding: '2px 0', cursor: 'pointer', marginTop: '2px' }}
            >
              {expanded ? '▲ Show less' : '▼ Show more'}
            </button>
          )}
          {error && <p style={{ fontSize: '12px', color: '#DC2626', marginTop: '4px' }}>{error}</p>}
        </div>

        {/* Right column: status badge + (time & resolve side by side) */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '6px', flexShrink: 0 }}>
          {/* Status badge */}
          <span
            style={{
              background: statusStyle.bg, color: statusStyle.text,
              fontSize: '11px', fontWeight: 700, padding: '3px 10px',
              borderRadius: '20px', textTransform: 'uppercase', letterSpacing: '0.03em',
            }}
          >
            {ticket.status}
          </span>

          {/* Time + resolve button side by side */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {ticket.status === 'resolved' && ticket.resolved_at ? (
              <span style={{ fontSize: '11px', color: '#16A34A', display: 'flex', alignItems: 'center', gap: '3px' }}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
                {timeAgo(ticket.resolved_at)}
              </span>
            ) : (
              <span style={{ fontSize: '11px', color: '#9CA3AF', display: 'flex', alignItems: 'center', gap: '3px' }}>
                <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
                {timeAgo(ticket.created_at)}
              </span>
            )}

            {ticket.status === 'open' && (
              <button
                onClick={handleResolve}
                disabled={resolving}
                style={{
                  background: '#16A34A', color: 'white',
                  fontSize: '12px', fontWeight: 600, padding: '5px 12px',
                  borderRadius: '8px', border: 'none', cursor: resolving ? 'not-allowed' : 'pointer',
                  opacity: resolving ? 0.6 : 1,
                }}
                onMouseEnter={(e) => { if (!resolving) e.currentTarget.style.background = '#15803D'; }}
                onMouseLeave={(e) => { e.currentTarget.style.background = '#16A34A'; }}
              >
                {resolving ? 'Resolving...' : 'Resolve'}
              </button>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
