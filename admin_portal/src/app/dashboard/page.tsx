import { createServerSupabase } from '@/lib/supabase/server'
import { StatCard } from '@/components/stat-card'
import { ShoppingCart, Package, DollarSign, Users } from 'lucide-react'

export default async function DashboardPage() {
  const supabase = await createServerSupabase()
  const [{ count: orderCount }, { count: productCount }, { data: revenueData }, { data: pendingOrders }] = await Promise.all([
    supabase.from('orders').select('*', { count: 'exact', head: true }),
    supabase.from('products').select('*', { count: 'exact', head: true }),
    supabase.from('orders').select('final_amount').eq('status', 'delivered'),
    supabase.from('orders').select('id').eq('status', 'pending'),
  ])
  const totalRevenue = revenueData?.reduce((sum, o) => sum + (o.final_amount || 0), 0) ?? 0

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard title="Total Orders" value={orderCount ?? 0} icon={ShoppingCart} />
        <StatCard title="Products" value={productCount ?? 0} icon={Package} />
        <StatCard title="Revenue" value={`NPR ${totalRevenue.toLocaleString()}`} icon={DollarSign} description="From delivered orders" />
        <StatCard title="Pending Orders" value={pendingOrders?.length ?? 0} icon={Users} description="Awaiting confirmation" />
      </div>
    </div>
  )
}
