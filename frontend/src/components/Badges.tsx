import type { Priority, TicketStatus } from '@/types/ticket';

interface PriorityBadgeProps {
  priority: Priority;
}

const PRIORITY_STYLES: Record<Priority, React.CSSProperties> = {
  low:    { background: '#16A34A', color: '#ffffff' },
  medium: { background: '#EA580C', color: '#ffffff' },
  high:   { background: '#DC2626', color: '#ffffff' },
};

const PRIORITY_LABEL: Record<Priority, string> = {
  low:    'Low Priority',
  medium: 'Medium Priority',
  high:   'High Priority',
};

const STATUS_STYLES: Record<TicketStatus, React.CSSProperties> = {
  open:     { background: '#DBEAFE', color: '#1E40AF' },
  resolved: { background: '#DCFCE7', color: '#15803D' },
};

export function PriorityBadge({ priority }: PriorityBadgeProps) {
  return (
    <span
      style={{
        ...PRIORITY_STYLES[priority],
        display: 'inline-flex',
        alignItems: 'center',
        padding: '2px 10px',
        borderRadius: '9999px',
        fontSize: '0.7rem',
        fontWeight: 700,
        letterSpacing: '0.04em',
        textTransform: 'uppercase',
      }}
    >
      {PRIORITY_LABEL[priority]}
    </span>
  );
}

interface StatusBadgeProps {
  status: TicketStatus;
}

export function StatusBadge({ status }: StatusBadgeProps) {
  return (
    <span
      style={{
        ...STATUS_STYLES[status],
        display: 'inline-flex',
        alignItems: 'center',
        gap: '4px',
        padding: '3px 10px',
        borderRadius: '9999px',
        fontSize: '0.7rem',
        fontWeight: 700,
        letterSpacing: '0.04em',
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
      }}
    >
      {status === 'resolved' ? (
        <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <path d="M20 6 9 17l-5-5"/>
        </svg>
      ) : null}
      {status}
    </span>
  );
}
