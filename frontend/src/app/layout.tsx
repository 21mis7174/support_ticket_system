import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Mini AI Support Ticket System',
  description: 'Create and manage support tickets',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body className="min-h-full">{children}</body>
    </html>
  );
}
