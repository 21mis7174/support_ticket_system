import type { Ticket, CreateTicketPayload, TicketListResponse } from '@/types/ticket';

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:8000';

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let message = `Request failed: ${response.status} ${response.statusText}`;
    try {
      const data = await response.json();
      if (data?.detail) {
        message = typeof data.detail === 'string' ? data.detail : JSON.stringify(data.detail);
      }
    } catch {
      // ignore JSON parse errors
    }
    throw new Error(message);
  }
  return response.json() as Promise<T>;
}

export async function fetchTickets(): Promise<TicketListResponse> {
  const response = await fetch(`${API_BASE}/tickets`, { cache: 'no-store' });
  return handleResponse<TicketListResponse>(response);
}

export async function createTicket(payload: CreateTicketPayload): Promise<Ticket> {
  const response = await fetch(`${API_BASE}/tickets`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  return handleResponse<Ticket>(response);
}

export async function resolveTicket(ticketId: string): Promise<Ticket> {
  const response = await fetch(`${API_BASE}/tickets/${ticketId}/resolve`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
  });
  return handleResponse<Ticket>(response);
}
