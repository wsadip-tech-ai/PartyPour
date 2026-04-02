'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { cn } from '@/lib/utils'
import { LayoutDashboard, FolderTree, Package, Percent, ShoppingCart, Wrench, Calculator, LogOut } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/categories', label: 'Categories', icon: FolderTree },
  { href: '/products', label: 'Products', icon: Package },
  { href: '/discounts', label: 'Discounts', icon: Percent },
  { href: '/orders', label: 'Orders', icon: ShoppingCart },
  { href: '/equipment', label: 'Equipment', icon: Wrench },
  { href: '/estimation-rules', label: 'Estimation Rules', icon: Calculator },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
  }

  if (pathname === '/login') return null

  return (
    <aside className="w-64 border-r bg-card h-screen flex flex-col">
      <div className="p-6">
        <h1 className="text-xl font-bold text-primary">RaksiChaiyo</h1>
        <p className="text-xs text-muted-foreground">Admin Portal</p>
      </div>
      <nav className="flex-1 px-4 space-y-1">
        {navItems.map((item) => (
          <Link key={item.href} href={item.href}
            className={cn('flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors',
              pathname.startsWith(item.href) ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground')}>
            <item.icon className="h-4 w-4" />{item.label}
          </Link>
        ))}
      </nav>
      <div className="p-4 border-t">
        <button onClick={handleSignOut} className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted-foreground hover:bg-accent w-full">
          <LogOut className="h-4 w-4" />Sign Out
        </button>
      </div>
    </aside>
  )
}
