'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'
import { Printer, CheckCircle, XCircle, Truck, PackageCheck } from 'lucide-react'

interface OrderActionsProps {
  orderId: string
  status: string
  onStatusUpdate: () => void
}

export function OrderActions({ orderId, status, onStatusUpdate }: OrderActionsProps) {
  const supabase = createClient()
  const [loading, setLoading] = useState(false)

  const updateStatus = async (newStatus: string) => {
    setLoading(true)
    const { error } = await supabase.from('orders').update({ status: newStatus }).eq('id', orderId)
    if (error) {
      toast.error('Failed to update order status')
    } else {
      toast.success(`Order ${newStatus} successfully`)
      // Notify customer via in-app + push notification
      supabase.functions.invoke('notify-order-status', {
        body: { order_id: orderId, new_status: newStatus },
      }).catch(() => {}) // non-blocking
      onStatusUpdate()
    }
    setLoading(false)
  }

  const openDispatchSlip = () => {
    window.open(`/orders/${orderId}/dispatch-slip`, '_blank')
  }

  return (
    <div className="flex items-center gap-2 flex-wrap">
      {status === 'pending' && (
        <>
          <Button className="bg-green-600 hover:bg-green-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('confirmed')}>
            <CheckCircle className="h-4 w-4" /> Confirm Order
          </Button>
          <Button variant="destructive" className="gap-2" disabled={loading} onClick={() => updateStatus('cancelled')}>
            <XCircle className="h-4 w-4" /> Cancel Order
          </Button>
        </>
      )}
      {status === 'confirmed' && (
        <Button className="bg-blue-600 hover:bg-blue-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('dispatched')}>
          <Truck className="h-4 w-4" /> Mark Dispatched
        </Button>
      )}
      {status === 'dispatched' && (
        <Button className="bg-purple-600 hover:bg-purple-700 text-white gap-2" disabled={loading} onClick={() => updateStatus('delivered')}>
          <PackageCheck className="h-4 w-4" /> Mark Delivered
        </Button>
      )}
      <Button variant="outline" className="gap-2" onClick={openDispatchSlip}>
        <Printer className="h-4 w-4" /> Print Dispatch Slip
      </Button>
    </div>
  )
}
