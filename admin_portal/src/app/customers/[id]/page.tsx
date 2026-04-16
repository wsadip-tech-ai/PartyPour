// src/app/customers/[id]/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { StatCard } from '@/components/stat-card'
import { ArrowLeft, ShoppingCart, DollarSign, TrendingUp, Calendar } from 'lucide-react'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

interface Profile {
  id: string
  full_name: string | null
  email: string | null
  phone: string | null
  role: string
  created_at: string
}

interface ActivityEvent {
  id: string
  event_name: string
  properties: Record<string, any>
  created_at: string
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

function formatEventLabel(e: ActivityEvent): string {
  const props = e.properties ?? {}
  switch (e.event_name) {
    case 'wizard_step_entered': return `Entered wizard step ${props.step} (${props.step_name})`
    case 'wizard_step_completed': return `Completed wizard step ${props.step} (${props.step_name})`
    case 'order_placed': return `Placed order — NPR ${(props.amount ?? 0).toLocaleString()} (${props.item_count} items)`
    case 'product_viewed': return `Viewed product: ${props.product_name}`
    case 'chat_message_sent': return `Sent chat message (${props.message_length} chars)`
    case 'notification_opened': return `Opened notification`
    default: return e.event_name.replace(/_/g, ' ')
  }
}

const statusColors: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  pending: 'outline',
  confirmed: 'secondary',
  dispatched: 'default',
  delivered: 'default',
  cancelled: 'destructive',
}

export default function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [profile, setProfile] = useState<Profile | null>(null)
  const [orders, setOrders] = useState<Order[]>([])
  const [activity, setActivity] = useState<ActivityEvent[]>([])

  const fetchData = useCallback(async () => {
    const [{ data: profileData }, { data: ordersData }, { data: activityData }] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', id).single(),
      supabase.from('orders').select('*').eq('user_id', id).order('created_at', { ascending: false }),
      supabase.from('analytics_events').select('id, event_name, properties, created_at').eq('user_id', id).order('created_at', { ascending: false }).limit(200),
    ])
    if (profileData) setProfile(profileData)
    setOrders(ordersData ?? [])
    setActivity((activityData as ActivityEvent[]) ?? [])
  }, [id])

  useEffect(() => { fetchData() }, [fetchData])

  if (!profile) return <div className="flex items-center justify-center h-64"><p className="text-muted-foreground">Loading...</p></div>

  const totalSpent = orders.reduce((sum, o) => sum + (o.final_amount ?? 0), 0)
  const avgOrder = orders.length > 0 ? totalSpent / orders.length : 0
  const eventTypes = orders.map((o) => o.event_type).filter(Boolean)
  const favoriteEvent = eventTypes.length > 0
    ? eventTypes.sort((a, b) => eventTypes.filter(e => e === a).length - eventTypes.filter(e => e === b).length).pop()
    : null

  const initials = getInitials(profile.full_name, profile.email)
  const color = getAvatarColor(profile.full_name, profile.email)

  return (
    <div className="max-w-4xl space-y-6">
      <Link href="/customers" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to Customers
      </Link>

      <Card>
        <CardContent className="pt-6">
          <div className="flex items-start gap-4">
            <div className={`h-16 w-16 rounded-full ${color} text-white flex items-center justify-center text-2xl font-bold shrink-0`}>
              {initials}
            </div>
            <div className="space-y-1">
              <h1 className="text-2xl font-bold">{profile.full_name || 'Unknown'}</h1>
              <p className="text-muted-foreground">{profile.email || 'No email'}</p>
              {profile.phone && <p className="text-muted-foreground">{profile.phone}</p>}
              <div className="flex items-center gap-2 pt-1">
                {orders.length > 0 ? (
                  <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Converted</Badge>
                ) : (
                  <Badge variant="outline" className="text-muted-foreground">Not Converted</Badge>
                )}
                <span className="text-xs text-muted-foreground">
                  Joined {new Date(profile.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}
                </span>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard title="Total Orders" value={orders.length} icon={ShoppingCart} />
        <StatCard title="Total Spent" value={`NPR ${totalSpent.toLocaleString()}`} icon={DollarSign} />
        <StatCard title="Avg Order" value={`NPR ${Math.round(avgOrder).toLocaleString()}`} icon={TrendingUp} />
        <StatCard title="Favorite Event" value={favoriteEvent ?? 'N/A'} icon={Calendar} />
      </div>

      <Tabs defaultValue="activity">
        <TabsList>
          <TabsTrigger value="activity">Activity Timeline ({activity.length})</TabsTrigger>
          <TabsTrigger value="orders">Orders ({orders.length})</TabsTrigger>
        </TabsList>

        <TabsContent value="activity">
          <Card>
            <CardContent className="pt-6">
              {activity.length === 0 ? (
                <p className="text-muted-foreground text-center py-8">No activity recorded</p>
              ) : (
                <div className="relative">
                  {/* Timeline line */}
                  <div className="absolute left-3 top-2 bottom-2 w-px bg-border" />
                  <div className="space-y-4">
                    {activity.map((e) => {
                      const color = eventColors[e.event_name] ?? 'bg-gray-100 text-gray-700'
                      return (
                        <div key={e.id} className="flex items-start gap-4 relative">
                          <div className={`h-6 w-6 rounded-full ${color} flex items-center justify-center text-xs font-bold shrink-0 z-10 ring-2 ring-background`}>
                            {e.event_name === 'order_placed' ? '$' : e.event_name === 'wizard_step_entered' || e.event_name === 'wizard_step_completed' ? (e.properties?.step ?? '•') : '•'}
                          </div>
                          <div className="flex-1 min-w-0 pb-1">
                            <div className="flex items-center gap-2 flex-wrap">
                              <span className="text-sm font-medium">{formatEventLabel(e)}</span>
                            </div>
                            <span className="text-xs text-muted-foreground">
                              {new Date(e.created_at).toLocaleString('en-US', { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' })}
                            </span>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="orders">
          <Card>
            <CardContent className="pt-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Order ID</TableHead>
                    <TableHead>Event</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {orders.map((order) => (
                    <TableRow key={order.id}>
                      <TableCell>
                        <Link href={`/orders/${order.id}`} className="text-primary hover:underline">
                          #{order.id.substring(0, 8)}
                        </Link>
                      </TableCell>
                      <TableCell className="capitalize">{order.event_type ?? '—'}</TableCell>
                      <TableCell className="text-right font-medium">NPR {order.final_amount.toLocaleString()}</TableCell>
                      <TableCell>
                        <Badge variant={statusColors[order.status] ?? 'default'}>{order.status}</Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground">{new Date(order.created_at).toLocaleDateString()}</TableCell>
                    </TableRow>
                  ))}
                  {orders.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center text-muted-foreground py-8">No orders yet</TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
