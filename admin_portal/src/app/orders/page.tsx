'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { toast } from 'sonner'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { Eye } from 'lucide-react'

const statusColors: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  pending: 'outline',
  confirmed: 'secondary',
  dispatched: 'default',
  delivered: 'default',
  cancelled: 'destructive',
}

export default function OrdersPage() {
  const supabase = createClient()
  const [orders, setOrders] = useState<Order[]>([])
  const [statusFilter, setStatusFilter] = useState<string>('pending')
  const [pendingCount, setPendingCount] = useState<number>(0)
  const [actionLoading, setActionLoading] = useState<string | null>(null)

  const fetchOrders = useCallback(async () => {
    let query = supabase
      .from('orders')
      .select('*, profiles(full_name, email)')
      .order('created_at', { ascending: false })
    if (statusFilter !== 'all') query = query.eq('status', statusFilter)
    const { data } = await query
    setOrders(data ?? [])
  }, [statusFilter])

  const fetchPendingCount = useCallback(async () => {
    const { count } = await supabase
      .from('orders')
      .select('*', { count: 'exact', head: true })
      .eq('status', 'pending')
    setPendingCount(count ?? 0)
  }, [])

  useEffect(() => {
    fetchOrders()
    fetchPendingCount()
  }, [fetchOrders, fetchPendingCount])

  const quickUpdateStatus = async (orderId: string, newStatus: 'confirmed' | 'cancelled') => {
    setActionLoading(orderId + newStatus)
    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', orderId)
    if (error) {
      toast.error(`Failed to update order status`)
    } else {
      toast.success(`Order ${newStatus === 'confirmed' ? 'confirmed' : 'cancelled'} successfully`)
      await fetchOrders()
      await fetchPendingCount()
    }
    setActionLoading(null)
  }

  return (
    <div>
      {/* Pending orders count banner */}
      {pendingCount > 0 && (
        <div className="mb-6 flex items-center gap-3 rounded-lg border border-orange-200 bg-orange-50 px-5 py-4">
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-orange-500 text-sm font-bold text-white">
            {pendingCount}
          </span>
          <div>
            <p className="font-semibold text-orange-800">
              {pendingCount} pending order{pendingCount !== 1 ? 's' : ''} awaiting confirmation
            </p>
            <p className="text-sm text-orange-600">Review and confirm or cancel each order below.</p>
          </div>
          {statusFilter !== 'pending' && (
            <Button
              variant="outline"
              size="sm"
              className="ml-auto border-orange-300 text-orange-700 hover:bg-orange-100"
              onClick={() => setStatusFilter('pending')}
            >
              View Pending
            </Button>
          )}
        </div>
      )}

      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Orders</h1>
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v ?? 'pending')}>
          <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="confirmed">Confirmed</SelectItem>
            <SelectItem value="dispatched">Dispatched</SelectItem>
            <SelectItem value="delivered">Delivered</SelectItem>
            <SelectItem value="cancelled">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Order ID</TableHead>
            <TableHead>Customer</TableHead>
            <TableHead>Event</TableHead>
            <TableHead>Amount</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Date</TableHead>
            <TableHead>Actions</TableHead>
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
              <TableCell>
                <div className="flex items-center gap-2">
                  <div className={`h-6 w-6 rounded-full ${getAvatarColor(order.profiles?.full_name, order.profiles?.email)} text-white flex items-center justify-center text-xs font-bold shrink-0`}>
                    {getInitials(order.profiles?.full_name, order.profiles?.email)}
                  </div>
                  <span>{order.profiles?.full_name ?? order.profiles?.email ?? 'Unknown'}</span>
                </div>
              </TableCell>
              <TableCell>{order.event_type ?? '-'}</TableCell>
              <TableCell>NPR {order.final_amount.toLocaleString()}</TableCell>
              <TableCell>
                <Badge variant={statusColors[order.status] ?? 'default'}>{order.status}</Badge>
              </TableCell>
              <TableCell>{new Date(order.created_at).toLocaleDateString()}</TableCell>
              <TableCell>
                <div className="flex items-center gap-2">
                  <Link href={`/orders/${order.id}`}>
                    <Button size="sm" variant="outline" className="h-7 px-3 text-xs gap-1">
                      <Eye className="h-3 w-3" /> View
                    </Button>
                  </Link>
                  {order.status === 'pending' && (
                    <>
                      <Button
                        size="sm"
                        className="bg-green-600 hover:bg-green-700 text-white h-7 px-3 text-xs"
                        disabled={actionLoading !== null}
                        onClick={() => quickUpdateStatus(order.id, 'confirmed')}
                      >
                        {actionLoading === order.id + 'confirmed' ? '...' : 'Confirm'}
                      </Button>
                      <Button
                        size="sm"
                        variant="destructive"
                        className="h-7 px-3 text-xs"
                        disabled={actionLoading !== null}
                        onClick={() => quickUpdateStatus(order.id, 'cancelled')}
                      >
                        {actionLoading === order.id + 'cancelled' ? '...' : 'Cancel'}
                      </Button>
                    </>
                  )}
                </div>
              </TableCell>
            </TableRow>
          ))}
          {orders.length === 0 && (
            <TableRow>
              <TableCell colSpan={7} className="text-center text-muted-foreground py-8">
                No orders found
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}
