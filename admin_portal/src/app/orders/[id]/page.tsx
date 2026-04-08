'use client'

import { useEffect, useState, useCallback } from 'react'
import { useParams } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { OrderProgress } from '@/components/order-progress'
import { OrderActions } from '@/components/order-actions'
import { CustomerCard } from '@/components/customer-card'
import { EventCard } from '@/components/event-card'
import { ActivityTimeline } from '@/components/activity-timeline'
import { ArrowLeft } from 'lucide-react'

interface Notification {
  id: string
  title: string
  message: string
  created_at: string
}

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [order, setOrder] = useState<Order | null>(null)
  const [orderCount, setOrderCount] = useState(0)
  const [timeline, setTimeline] = useState<Notification[]>([])

  const fetchOrder = useCallback(async () => {
    const { data } = await supabase
      .from('orders')
      .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
      .eq('id', id)
      .single()
    if (data) {
      setOrder(data)
      // Fetch order count for this customer
      const { count } = await supabase
        .from('orders')
        .select('*', { count: 'exact', head: true })
        .eq('user_id', data.user_id)
      setOrderCount(count ?? 0)
      // Fetch activity timeline from notifications
      const { data: notifs } = await supabase
        .from('notifications')
        .select('id, title, message, created_at')
        .eq('order_id', id)
        .order('created_at', { ascending: false })
      setTimeline(notifs ?? [])
    }
  }, [id])

  useEffect(() => { fetchOrder() }, [fetchOrder])

  if (!order) return <div className="flex items-center justify-center h-64"><p className="text-muted-foreground">Loading order...</p></div>

  const profile = order.profiles ?? null

  return (
    <div className="max-w-4xl space-y-6">
      {/* Back link */}
      <Link href="/orders" className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
        <ArrowLeft className="h-4 w-4" /> Back to Orders
      </Link>

      {/* 1. Status Banner + Progress */}
      <OrderProgress status={order.status} />

      {/* 2. Order Header + Actions */}
      <div className="flex items-start justify-between flex-wrap gap-4">
        <div>
          <h1 className="text-2xl font-bold">Order #{order.id.substring(0, 8)}</h1>
          <p className="text-sm text-muted-foreground">
            Placed {new Date(order.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })} at{' '}
            {new Date(order.created_at).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })}
          </p>
        </div>
        <OrderActions orderId={order.id} status={order.status} onStatusUpdate={fetchOrder} />
      </div>

      {/* 3. Customer + 4. Event — side by side on desktop */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <CustomerCard
          profile={profile}
          contactPhone={order.contact_phone}
          orderCount={orderCount}
          userId={order.user_id}
        />
        <EventCard
          eventType={order.event_type}
          eventDate={order.event_date}
          guestCount={order.guest_count}
          deliveryAddress={order.delivery_address}
          specialInstructions={order.special_instructions}
        />
      </div>

      {/* 5. Order Items */}
      <Card>
        <CardHeader><CardTitle>Items ({order.order_items?.length ?? 0} products)</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Size</TableHead>
                <TableHead className="text-center">Qty</TableHead>
                <TableHead className="text-center">Type</TableHead>
                <TableHead className="text-right">Unit Price</TableHead>
                <TableHead className="text-right">Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.order_items?.map((item) => (
                <TableRow key={item.id}>
                  <TableCell className="font-medium">{(item as any).variants?.products?.name ?? 'N/A'}</TableCell>
                  <TableCell>{(item as any).variants?.size ?? 'N/A'}</TableCell>
                  <TableCell className="text-center">{item.quantity}</TableCell>
                  <TableCell className="text-center capitalize">{item.unit_type}</TableCell>
                  <TableCell className="text-right">NPR {item.unit_price.toLocaleString()}</TableCell>
                  <TableCell className="text-right font-medium">NPR {item.total_price.toLocaleString()}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="mt-4 text-right space-y-1 border-t pt-4">
            <p className="text-sm">Subtotal: NPR {order.total_amount.toLocaleString()}</p>
            {order.discount_amount > 0 && (
              <p className="text-sm text-green-600">Discount: - NPR {order.discount_amount.toLocaleString()}</p>
            )}
            <p className="text-xl font-bold">Total: NPR {order.final_amount.toLocaleString()}</p>
          </div>
        </CardContent>
      </Card>

      {/* 6. Activity Timeline */}
      <ActivityTimeline events={timeline} />
    </div>
  )
}
