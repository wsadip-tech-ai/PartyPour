// src/app/customers/[id]/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
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

  const fetchData = useCallback(async () => {
    const [{ data: profileData }, { data: ordersData }] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', id).single(),
      supabase.from('orders').select('*').eq('user_id', id).order('created_at', { ascending: false }),
    ])
    if (profileData) setProfile(profileData)
    setOrders(ordersData ?? [])
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
              <h1 className="text-2xl font-bold">{profile.full_name ?? 'Unknown'}</h1>
              <p className="text-muted-foreground">{profile.email ?? 'No email'}</p>
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

      <Card>
        <CardHeader><CardTitle>Order History</CardTitle></CardHeader>
        <CardContent>
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
    </div>
  )
}
