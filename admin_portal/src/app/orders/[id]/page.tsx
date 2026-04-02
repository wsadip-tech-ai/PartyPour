'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { toast } from 'sonner'

const statusFlow = ['pending', 'confirmed', 'dispatched', 'delivered', 'cancelled'] as const

const statusBannerStyles: Record<string, { bg: string; border: string; text: string; label: string }> = {
  pending:   { bg: 'bg-orange-50',  border: 'border-orange-300', text: 'text-orange-800', label: 'Awaiting Confirmation' },
  confirmed: { bg: 'bg-green-50',   border: 'border-green-300',  text: 'text-green-800',  label: 'Order Confirmed' },
  dispatched:{ bg: 'bg-blue-50',    border: 'border-blue-300',   text: 'text-blue-800',   label: 'Out for Delivery' },
  delivered: { bg: 'bg-purple-50',  border: 'border-purple-300', text: 'text-purple-800', label: 'Delivered' },
  cancelled: { bg: 'bg-red-50',     border: 'border-red-300',    text: 'text-red-800',    label: 'Cancelled' },
}

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [order, setOrder] = useState<Order | null>(null)
  const [newStatus, setNewStatus] = useState('')
  const [updating, setUpdating] = useState(false)

  const fetchOrder = async () => {
    const { data } = await supabase
      .from('orders')
      .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
      .eq('id', id)
      .single()
    if (data) { setOrder(data); setNewStatus(data.status) }
  }

  useEffect(() => { fetchOrder() }, [])

  const updateStatus = async (status?: string) => {
    const target = status ?? newStatus
    setUpdating(true)
    const { error } = await supabase.from('orders').update({ status: target }).eq('id', id)
    if (error) {
      toast.error('Failed to update order status')
    } else {
      toast.success(`Order status updated to "${target}"`)
      await fetchOrder()
    }
    setUpdating(false)
  }

  if (!order) return <p>Loading...</p>

  const profile = (order as any).profiles
  const banner = statusBannerStyles[order.status] ?? statusBannerStyles['pending']
  const isPending = order.status === 'pending'

  return (
    <div className="max-w-4xl space-y-6">
      {/* Status banner */}
      <div className={`rounded-lg border-2 px-5 py-4 ${banner.bg} ${banner.border}`}>
        <div className="flex items-center justify-between">
          <div>
            <p className={`text-xs font-semibold uppercase tracking-widest ${banner.text} opacity-70`}>Current Status</p>
            <p className={`text-2xl font-bold mt-0.5 ${banner.text}`}>{banner.label}</p>
          </div>
          <span className={`rounded-full border ${banner.border} ${banner.bg} ${banner.text} px-3 py-1 text-sm font-semibold capitalize`}>
            {order.status}
          </span>
        </div>
      </div>

      <h1 className="text-3xl font-bold">Order #{order.id.substring(0, 8)}</h1>

      {/* Quick action buttons — only for pending orders */}
      {isPending && (
        <div className="flex items-center gap-3">
          <Button
            size="lg"
            className="bg-green-600 hover:bg-green-700 text-white gap-2"
            disabled={updating}
            onClick={() => updateStatus('confirmed')}
          >
            ✓ Confirm Order
          </Button>
          <Button
            size="lg"
            variant="destructive"
            disabled={updating}
            onClick={() => updateStatus('cancelled')}
          >
            ✕ Cancel Order
          </Button>
        </div>
      )}

      <div className="grid grid-cols-2 gap-6">
        <Card>
          <CardHeader><CardTitle>Customer</CardTitle></CardHeader>
          <CardContent className="space-y-1 text-sm">
            <p><strong>Name:</strong> {profile?.full_name ?? 'N/A'}</p>
            <p><strong>Email:</strong> {profile?.email ?? 'N/A'}</p>
            <p><strong>Phone:</strong> {order.contact_phone ?? profile?.phone ?? 'N/A'}</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Event Details</CardTitle></CardHeader>
          <CardContent className="space-y-1 text-sm">
            <p><strong>Type:</strong> {order.event_type ?? 'N/A'}</p>
            <p><strong>Date:</strong> {order.event_date ?? 'N/A'}</p>
            <p><strong>Guests:</strong> {order.guest_count ?? 'N/A'}</p>
            <p><strong>Address:</strong> {order.delivery_address ?? 'N/A'}</p>
            {order.special_instructions && <p><strong>Notes:</strong> {order.special_instructions}</p>}
          </CardContent>
        </Card>
      </div>

      {/* Status update card */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Update Status</CardTitle>
          <div className="flex items-center gap-2">
            <Select value={newStatus} onValueChange={(v) => setNewStatus(v ?? '')}>
              <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
              <SelectContent>
                {statusFlow.map(s => <SelectItem key={s} value={s}>{s}</SelectItem>)}
              </SelectContent>
            </Select>
            <Button
              onClick={() => updateStatus()}
              disabled={newStatus === order.status || updating}
              size="sm"
            >
              {updating ? 'Saving...' : 'Update'}
            </Button>
          </div>
        </CardHeader>
      </Card>

      <Card>
        <CardHeader><CardTitle>Items</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Size</TableHead>
                <TableHead>Qty</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Unit Price</TableHead>
                <TableHead>Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.order_items?.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{(item as any).variants?.products?.name ?? 'N/A'}</TableCell>
                  <TableCell>{(item as any).variants?.size ?? 'N/A'}</TableCell>
                  <TableCell>{item.quantity}</TableCell>
                  <TableCell>{item.unit_type}</TableCell>
                  <TableCell>NPR {item.unit_price}</TableCell>
                  <TableCell>NPR {item.total_price}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="mt-4 text-right space-y-1">
            <p>Subtotal: NPR {order.total_amount.toLocaleString()}</p>
            <p>Discount: - NPR {order.discount_amount.toLocaleString()}</p>
            <p className="text-lg font-bold">Total: NPR {order.final_amount.toLocaleString()}</p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
