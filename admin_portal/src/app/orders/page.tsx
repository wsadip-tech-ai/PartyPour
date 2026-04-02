'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'

const statusColors: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = { pending: 'outline', confirmed: 'secondary', dispatched: 'default', delivered: 'default', cancelled: 'destructive' }

export default function OrdersPage() {
  const supabase = createClient()
  const [orders, setOrders] = useState<Order[]>([])
  const [statusFilter, setStatusFilter] = useState<string>('all')

  useEffect(() => {
    const fetch = async () => {
      let query = supabase.from('orders').select('*, profiles(full_name, email)').order('created_at', { ascending: false })
      if (statusFilter !== 'all') query = query.eq('status', statusFilter)
      const { data } = await query
      setOrders(data ?? [])
    }
    fetch()
  }, [statusFilter])

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Orders</h1>
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v ?? 'all')}><SelectTrigger className="w-48"><SelectValue /></SelectTrigger><SelectContent>
          <SelectItem value="all">All Statuses</SelectItem><SelectItem value="pending">Pending</SelectItem><SelectItem value="confirmed">Confirmed</SelectItem>
          <SelectItem value="dispatched">Dispatched</SelectItem><SelectItem value="delivered">Delivered</SelectItem><SelectItem value="cancelled">Cancelled</SelectItem>
        </SelectContent></Select>
      </div>
      <Table>
        <TableHeader><TableRow><TableHead>Order ID</TableHead><TableHead>Customer</TableHead><TableHead>Event</TableHead><TableHead>Amount</TableHead><TableHead>Status</TableHead><TableHead>Date</TableHead></TableRow></TableHeader>
        <TableBody>
          {orders.map((order) => (
            <TableRow key={order.id}>
              <TableCell><Link href={`/orders/${order.id}`} className="text-primary hover:underline">#{order.id.substring(0, 8)}</Link></TableCell>
              <TableCell>{order.profiles?.full_name ?? order.profiles?.email ?? 'Unknown'}</TableCell>
              <TableCell>{order.event_type ?? '-'}</TableCell>
              <TableCell>NPR {order.final_amount.toLocaleString()}</TableCell>
              <TableCell><Badge variant={statusColors[order.status] ?? 'default'}>{order.status}</Badge></TableCell>
              <TableCell>{new Date(order.created_at).toLocaleDateString()}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
