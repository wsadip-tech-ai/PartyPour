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

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [order, setOrder] = useState<Order | null>(null)
  const [newStatus, setNewStatus] = useState('')

  const fetchOrder = async () => {
    const { data } = await supabase.from('orders').select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))').eq('id', id).single()
    if (data) { setOrder(data); setNewStatus(data.status) }
  }

  useEffect(() => { fetchOrder() }, [])

  const updateStatus = async () => {
    await supabase.from('orders').update({ status: newStatus }).eq('id', id)
    toast.success(`Order status updated to ${newStatus}`); fetchOrder()
  }

  if (!order) return <p>Loading...</p>
  const profile = (order as any).profiles

  return (
    <div className="max-w-4xl space-y-6">
      <h1 className="text-3xl font-bold">Order #{order.id.substring(0, 8)}</h1>
      <div className="grid grid-cols-2 gap-6">
        <Card><CardHeader><CardTitle>Customer</CardTitle></CardHeader><CardContent className="space-y-1 text-sm">
          <p><strong>Name:</strong> {profile?.full_name ?? 'N/A'}</p><p><strong>Email:</strong> {profile?.email ?? 'N/A'}</p><p><strong>Phone:</strong> {order.contact_phone ?? profile?.phone ?? 'N/A'}</p>
        </CardContent></Card>
        <Card><CardHeader><CardTitle>Event Details</CardTitle></CardHeader><CardContent className="space-y-1 text-sm">
          <p><strong>Type:</strong> {order.event_type ?? 'N/A'}</p><p><strong>Date:</strong> {order.event_date ?? 'N/A'}</p>
          <p><strong>Guests:</strong> {order.guest_count ?? 'N/A'}</p><p><strong>Address:</strong> {order.delivery_address ?? 'N/A'}</p>
          {order.special_instructions && <p><strong>Notes:</strong> {order.special_instructions}</p>}
        </CardContent></Card>
      </div>
      <Card><CardHeader className="flex flex-row items-center justify-between"><CardTitle>Status</CardTitle>
        <div className="flex items-center gap-2">
          <Select value={newStatus} onValueChange={setNewStatus}><SelectTrigger className="w-40"><SelectValue /></SelectTrigger><SelectContent>{statusFlow.map(s => <SelectItem key={s} value={s}>{s}</SelectItem>)}</SelectContent></Select>
          <Button onClick={updateStatus} disabled={newStatus === order.status} size="sm">Update</Button>
        </div>
      </CardHeader></Card>
      <Card><CardHeader><CardTitle>Items</CardTitle></CardHeader><CardContent>
        <Table>
          <TableHeader><TableRow><TableHead>Product</TableHead><TableHead>Size</TableHead><TableHead>Qty</TableHead><TableHead>Type</TableHead><TableHead>Unit Price</TableHead><TableHead>Total</TableHead></TableRow></TableHeader>
          <TableBody>
            {order.order_items?.map((item) => (
              <TableRow key={item.id}>
                <TableCell>{(item as any).variants?.products?.name ?? 'N/A'}</TableCell><TableCell>{(item as any).variants?.size ?? 'N/A'}</TableCell>
                <TableCell>{item.quantity}</TableCell><TableCell>{item.unit_type}</TableCell>
                <TableCell>NPR {item.unit_price}</TableCell><TableCell>NPR {item.total_price}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        <div className="mt-4 text-right space-y-1">
          <p>Subtotal: NPR {order.total_amount.toLocaleString()}</p><p>Discount: - NPR {order.discount_amount.toLocaleString()}</p>
          <p className="text-lg font-bold">Total: NPR {order.final_amount.toLocaleString()}</p>
        </div>
      </CardContent></Card>
    </div>
  )
}
