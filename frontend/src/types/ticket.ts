export type Priority = 'low' | 'medium' | 'high';
export type TicketStatus = 'open' | 'resolved';

export interface Ticket {
  id: string;
  title: string;
  description: string;
  priority: Priority;
  status: TicketStatus;
  created_at: string;
  resolved_at: string | null;
}

export interface CreateTicketPayload {
  title: string;
  description: string;
  priority: Priority;
}

export interface TicketListResponse {
  tickets: Ticket[];
  total: number;
}
