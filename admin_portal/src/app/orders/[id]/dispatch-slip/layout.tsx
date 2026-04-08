export default function DispatchSlipLayout({ children }: { children: React.ReactNode }) {
  // Sidebar already suppresses itself on /dispatch-slip routes (pathname check in sidebar.tsx).
  // This layout removes the <main> padding so the print page renders full-width.
  return <div style={{ padding: 0, width: '100%' }}>{children}</div>
}
