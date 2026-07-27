import './globals.css';
import type { Metadata } from 'next';
export const metadata: Metadata = { title: { default: 'Plekxa Admin', template: '%s | Plekxa Admin' }, description: 'Central operations console for Plekxa.' };
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en" suppressHydrationWarning><body suppressHydrationWarning>{children}</body></html>}
