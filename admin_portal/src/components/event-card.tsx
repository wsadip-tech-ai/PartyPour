'use client'

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Copy, Calendar, Users, MapPin, Clock, PartyPopper } from 'lucide-react'
import { toast } from 'sonner'

interface EventCardProps {
  eventType: string | null
  eventDate: string | null
  guestCount: number | null
  deliveryAddress: string | null
  specialInstructions: string | null
}

const eventIcons: Record<string, string> = {
  wedding: '💒', birthday: '🎂', corporate: '🏢', house_party: '🏠', anniversary: '💑', other: '🎉',
}

function daysUntil(dateStr: string): number {
  const target = new Date(dateStr)
  const now = new Date()
  return Math.ceil((target.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
}

export function EventCard({ eventType, eventDate, guestCount, deliveryAddress, specialInstructions }: EventCardProps) {
  const days = eventDate ? daysUntil(eventDate) : null

  const copyAddress = () => {
    if (deliveryAddress) {
      navigator.clipboard.writeText(deliveryAddress)
      toast.success('Address copied')
    }
  }

  return (
    <Card>
      <CardHeader><CardTitle>Event Details</CardTitle></CardHeader>
      <CardContent className="space-y-3 text-sm">
        <div className="flex items-center gap-2">
          <PartyPopper className="h-4 w-4 text-muted-foreground" />
          <span className="font-semibold capitalize">{eventIcons[eventType ?? 'other']} {eventType ?? 'N/A'}</span>
        </div>
        <div className="flex items-center gap-2">
          <Calendar className="h-4 w-4 text-muted-foreground" />
          <span>{eventDate ?? 'N/A'}</span>
          {days !== null && days > 0 && (
            <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${
              days <= 3 ? 'bg-red-100 text-red-700' :
              days <= 14 ? 'bg-orange-100 text-orange-700' :
              'bg-green-100 text-green-700'
            }`}>
              {days} day{days !== 1 ? 's' : ''} away
            </span>
          )}
          {days !== null && days <= 0 && (
            <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-gray-100 text-gray-600">Event passed</span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4 text-muted-foreground" />
          <span>{guestCount ?? 'N/A'} guests</span>
        </div>
        <div className="flex items-center gap-2">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          <span className="flex-1">{deliveryAddress ?? 'N/A'}</span>
          {deliveryAddress && (
            <button onClick={copyAddress} className="text-muted-foreground hover:text-foreground"><Copy className="h-3 w-3" /></button>
          )}
        </div>
        {specialInstructions ? (
          <div className="flex items-start gap-2 pt-1 border-t">
            <Clock className="h-4 w-4 text-muted-foreground mt-0.5" />
            <p>{specialInstructions}</p>
          </div>
        ) : (
          <p className="text-muted-foreground italic text-xs pt-1 border-t">No special instructions</p>
        )}
      </CardContent>
    </Card>
  )
}
