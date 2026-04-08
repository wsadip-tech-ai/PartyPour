'use client'

import Link from 'next/link'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Copy, ExternalLink } from 'lucide-react'
import { toast } from 'sonner'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

interface CustomerCardProps {
  profile: { full_name: string | null; email: string | null; phone: string | null } | null
  contactPhone: string | null
  orderCount: number
  userId: string
}

export function CustomerCard({ profile, contactPhone, orderCount, userId }: CustomerCardProps) {
  const name = profile?.full_name
  const email = profile?.email
  const phone = contactPhone ?? profile?.phone
  const initials = getInitials(name, email)
  const color = getAvatarColor(name, email)

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text)
    toast.success(`${label} copied`)
  }

  return (
    <Card>
      <CardHeader><CardTitle>Customer</CardTitle></CardHeader>
      <CardContent>
        <div className="flex items-start gap-4">
          <div className={`h-12 w-12 rounded-full ${color} text-white flex items-center justify-center text-lg font-bold shrink-0`}>
            {initials}
          </div>
          <div className="space-y-1 text-sm min-w-0">
            <p className="font-semibold text-base">{name ?? 'Unknown'}</p>
            {email && (
              <p className="text-muted-foreground flex items-center gap-1">
                {email}
                <button onClick={() => copyToClipboard(email, 'Email')} className="hover:text-foreground"><Copy className="h-3 w-3" /></button>
              </p>
            )}
            {phone && (
              <p className="text-muted-foreground flex items-center gap-1">
                {phone}
                <button onClick={() => copyToClipboard(phone, 'Phone')} className="hover:text-foreground"><Copy className="h-3 w-3" /></button>
              </p>
            )}
            <div className="flex items-center gap-2 pt-1">
              <Badge variant="secondary">{orderCount} order{orderCount !== 1 ? 's' : ''} total</Badge>
              <Link href={`/customers/${userId}`} className="text-xs text-primary hover:underline inline-flex items-center gap-1">
                View profile <ExternalLink className="h-3 w-3" />
              </Link>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
