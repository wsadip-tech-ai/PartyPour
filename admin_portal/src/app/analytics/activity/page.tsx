'use client'

import { useEffect, useState, useCallback } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { RefreshCw } from 'lucide-react'

interface ActivityEvent {
  id: string
  user_id: string
  event_name: string
  properties: Record<string, any>
  created_at: string
  profiles?: { full_name: string | null; email: string | null } | null
}

const eventColors: Record<string, string> = {
  app_opened: 'bg-gray-100 text-gray-700',
  wizard_step_entered: 'bg-blue-100 text-blue-700',
  wizard_step_completed: 'bg-green-100 text-green-700',
  order_placed: 'bg-purple-100 text-purple-700',
  product_viewed: 'bg-cyan-100 text-cyan-700',
  chat_started: 'bg-amber-100 text-amber-700',
  chat_message_sent: 'bg-amber-100 text-amber-700',
  order_history_viewed: 'bg-indigo-100 text-indigo-700',
  notification_opened: 'bg-pink-100 text-pink-700',
}

function timeAgo(dateStr: string): string {
  const diffMs = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diffMs / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  return `${days}d ago`
}

export default function AnalyticsActivityPage() {
  const supabase = createClient()
  const [events, setEvents] = useState<ActivityEvent[]>([])
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(false)

  const fetchEvents = useCallback(async () => {
    setLoading(true)
    let query = supabase
      .from('analytics_events')
      .select('*, profiles(full_name, email)')
      .order('created_at', { ascending: false })
      .limit(100)

    if (filter !== 'all') query = query.eq('event_name', filter)

    const { data } = await query
    setEvents((data as ActivityEvent[]) ?? [])
    setLoading(false)
  }, [filter])

  useEffect(() => { fetchEvents() }, [fetchEvents])

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Select value={filter} onValueChange={(v) => setFilter(v ?? 'all')}>
          <SelectTrigger className="w-52"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Events</SelectItem>
            <SelectItem value="app_opened">App Opened</SelectItem>
            <SelectItem value="wizard_step_entered">Wizard Step Entered</SelectItem>
            <SelectItem value="wizard_step_completed">Wizard Step Completed</SelectItem>
            <SelectItem value="order_placed">Order Placed</SelectItem>
            <SelectItem value="product_viewed">Product Viewed</SelectItem>
            <SelectItem value="chat_started">Chat Started</SelectItem>
            <SelectItem value="chat_message_sent">Chat Message Sent</SelectItem>
            <SelectItem value="order_history_viewed">Order History Viewed</SelectItem>
            <SelectItem value="notification_opened">Notification Opened</SelectItem>
          </SelectContent>
        </Select>
        <Button variant="outline" className="gap-2" onClick={fetchEvents} disabled={loading}>
          <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} /> Refresh
        </Button>
      </div>

      <Card>
        <CardHeader><CardTitle>Recent Activity ({events.length})</CardTitle></CardHeader>
        <CardContent>
          {events.length === 0 ? (
            <p className="text-muted-foreground text-center py-8">No events yet</p>
          ) : (
            <div className="space-y-3">
              {events.map((e) => {
                const profile = e.profiles
                const color = eventColors[e.event_name] ?? 'bg-gray-100 text-gray-700'
                const props = e.properties ?? {}
                const propStr = Object.entries(props).map(([k, v]) => `${k}: ${v}`).join(', ')

                return (
                  <div key={e.id} className="flex items-center gap-3 py-2 border-b last:border-0">
                    <div className={`h-7 w-7 rounded-full ${getAvatarColor(profile?.full_name, profile?.email)} text-white flex items-center justify-center text-xs font-bold shrink-0`}>
                      {getInitials(profile?.full_name, profile?.email)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-medium">{profile?.full_name ?? profile?.email ?? 'Unknown'}</span>
                        <Badge className={`${color} text-xs`}>{e.event_name.replace(/_/g, ' ')}</Badge>
                      </div>
                      {propStr && <p className="text-xs text-muted-foreground truncate">{propStr}</p>}
                    </div>
                    <span className="text-xs text-muted-foreground shrink-0">{timeAgo(e.created_at)}</span>
                  </div>
                )
              })}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
