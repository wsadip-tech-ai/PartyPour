'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { StatCard } from '@/components/stat-card'
import { FunnelChart } from '@/components/funnel-chart'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Users, UserCheck, TrendingDown, BarChart3 } from 'lucide-react'

const dateRanges: Record<string, number> = {
  '7d': 7, '30d': 30, '90d': 90, 'all': 0,
}

export default function AnalyticsFunnelPage() {
  const supabase = createClient()
  const [range, setRange] = useState('30d')
  const [funnelData, setFunnelData] = useState<{ label: string; count: number }[]>([])
  const [totalUsers, setTotalUsers] = useState(0)
  const [conversions, setConversions] = useState(0)

  const fetchFunnel = useCallback(async () => {
    const days = dateRanges[range]
    const since = days > 0
      ? new Date(Date.now() - days * 86400000).toISOString()
      : '2020-01-01T00:00:00Z'

    const { data: stepData } = await supabase
      .from('analytics_events')
      .select('user_id, properties')
      .eq('event_name', 'wizard_step_entered')
      .gte('created_at', since)

    const { data: orderData } = await supabase
      .from('analytics_events')
      .select('user_id')
      .eq('event_name', 'order_placed')
      .gte('created_at', since)

    const { data: appData } = await supabase
      .from('analytics_events')
      .select('user_id')
      .eq('event_name', 'app_opened')
      .gte('created_at', since)

    const appUsers = new Set((appData ?? []).map((e: any) => e.user_id))
    const stepNames = ['event', 'types', 'quantities', 'brands', 'review', 'confirm']
    const stepCounts = stepNames.map((name, i) => {
      const users = new Set(
        (stepData ?? [])
          .filter((e: any) => e.properties?.step === i + 1)
          .map((e: any) => e.user_id)
      )
      return { label: `Step ${i + 1}: ${name.charAt(0).toUpperCase() + name.slice(1)}`, count: users.size }
    })

    const orderUsers = new Set((orderData ?? []).map((e: any) => e.user_id))

    const funnel = [
      { label: 'App Opened', count: appUsers.size },
      ...stepCounts,
      { label: 'Order Placed', count: orderUsers.size },
    ]

    setFunnelData(funnel)
    setTotalUsers(appUsers.size)
    setConversions(orderUsers.size)
  }, [range])

  useEffect(() => { fetchFunnel() }, [fetchFunnel])

  const conversionRate = totalUsers > 0 ? ((conversions / totalUsers) * 100).toFixed(1) : '0'
  const funnelEntries = funnelData[1]?.count ?? 0

  return (
    <div className="space-y-6">
      <div className="flex justify-end">
        <Select value={range} onValueChange={(v) => setRange(v ?? '30d')}>
          <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="7d">Last 7 days</SelectItem>
            <SelectItem value="30d">Last 30 days</SelectItem>
            <SelectItem value="90d">Last 90 days</SelectItem>
            <SelectItem value="all">All time</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard title="Total Users" value={totalUsers} icon={Users} />
        <StatCard title="Funnel Entries" value={funnelEntries} icon={BarChart3} description="Started wizard" />
        <StatCard title="Conversions" value={conversions} icon={UserCheck} description="Placed an order" />
        <StatCard title="Conversion Rate" value={`${conversionRate}%`} icon={TrendingDown} description="App open → order" />
      </div>

      <Card>
        <CardHeader><CardTitle>Conversion Funnel</CardTitle></CardHeader>
        <CardContent>
          {funnelData.length > 0 ? (
            <FunnelChart steps={funnelData} />
          ) : (
            <p className="text-muted-foreground text-center py-8">No analytics data yet. Events will appear once users interact with the app.</p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
