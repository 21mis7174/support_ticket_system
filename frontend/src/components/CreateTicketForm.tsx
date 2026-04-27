'use client';

import { useState } from 'react';
import type { FormEvent } from 'react';
import type { CreateTicketPayload, Priority } from '@/types/ticket';

interface CreateTicketFormProps {
  onSubmit: (payload: CreateTicketPayload) => Promise<void>;
}

const PRIORITY_STYLES: Record<Priority, { default: React.CSSProperties; active: React.CSSProperties }> = {
  low:    { default: { border: '1px solid #16A34A', color: '#16A34A', background: 'white' }, active: { border: '1px solid #16A34A', color: 'white', background: '#16A34A' } },
  medium: { default: { border: '1px solid #EA580C', color: '#EA580C', background: 'white' }, active: { border: '1px solid #EA580C', color: 'white', background: '#EA580C' } },
  high:   { default: { border: '1px solid #DC2626', color: '#DC2626', background: 'white' }, active: { border: '1px solid #DC2626', color: 'white', background: '#DC2626' } },
};

export function CreateTicketForm({ onSubmit }: CreateTicketFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<Priority>('medium');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setSuccess(false);
    if (!title.trim() || !description.trim()) {
      setError('Title and description are required.');
      return;
    }
    setSubmitting(true);
    try {
      await onSubmit({ title: title.trim(), description: description.trim(), priority });
      setTitle('');
      setDescription('');
      setPriority('medium');
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create ticket.');
    } finally {
      setSubmitting(false);
    }
  }

  const inputBase: React.CSSProperties = {
    width: '100%',
    padding: '8px 12px',
    borderRadius: '8px',
    border: '1px solid #D1D5DB',
    fontSize: '14px',
    color: '#111827',
    outline: 'none',
    background: 'white',
  };

  function onFocus(e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>) {
    e.target.style.borderColor = '#0D9488';
    e.target.style.boxShadow = '0 0 0 2px rgba(13,148,136,0.2)';
  }
  function onBlur(e: React.FocusEvent<HTMLInputElement | HTMLTextAreaElement>) {
    e.target.style.borderColor = '#D1D5DB';
    e.target.style.boxShadow = 'none';
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="rounded-2xl overflow-hidden"
      style={{ background: 'white', border: '1px solid #E2E8F0', boxShadow: '0 1px 4px rgba(0,0,0,0.08)' }}
    >
      {/* Header */}
      <div className="px-6 pt-6 pb-4" style={{ borderBottom: '1px solid #F3F4F6' }}>
        <p className="text-xs font-semibold uppercase tracking-widest mb-0.5" style={{ color: '#0D9488' }}>NEW TICKET</p>
        <h2 className="text-xl font-bold" style={{ color: '#0F172A' }}>CREATE TICKET</h2>
      </div>

      {/* Fields */}
      <div className="px-6 py-5 space-y-4">

        <div>
          <label className="block text-sm font-medium mb-1.5" style={{ color: '#374151' }}>Ticket Title</label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Enter a brief summary..."
            maxLength={200}
            required
            style={inputBase}
            onFocus={onFocus}
            onBlur={onBlur}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1.5" style={{ color: '#374151' }}>Description</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Provide details about the issue..."
            rows={4}
            maxLength={2000}
            required
            style={{ ...inputBase, resize: 'vertical', minHeight: '96px' }}
            onFocus={onFocus as unknown as React.FocusEventHandler<HTMLTextAreaElement>}
            onBlur={onBlur as unknown as React.FocusEventHandler<HTMLTextAreaElement>}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-2" style={{ color: '#374151' }}>Priority</label>
          <div className="flex gap-2">
            {(['low', 'medium', 'high'] as Priority[]).map((p) => (
              <button
                key={p}
                type="button"
                onClick={() => setPriority(p)}
                className="flex-1 py-2 rounded-lg text-sm font-semibold transition-all capitalize"
                style={priority === p ? PRIORITY_STYLES[p].active : PRIORITY_STYLES[p].default}
              >
                {p}
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div className="px-3 py-2.5 rounded-lg text-sm" style={{ background: '#FEF2F2', color: '#DC2626', border: '1px solid #FECACA' }}>
            {error}
          </div>
        )}
        {success && (
          <div className="px-3 py-2.5 rounded-lg text-sm" style={{ background: '#F0FDF4', color: '#15803D', border: '1px solid #BBF7D0' }}>
            ✓ Ticket created successfully!
          </div>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3 rounded-xl font-semibold text-sm text-white transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          style={{ background: '#0D9488' }}
          onMouseEnter={(e) => { if (!submitting) e.currentTarget.style.background = '#0F766E'; }}
          onMouseLeave={(e) => { e.currentTarget.style.background = '#0D9488'; }}
        >
          {submitting ? 'Creating...' : 'Create Ticket'}
        </button>
      </div>
    </form>
  );
}

