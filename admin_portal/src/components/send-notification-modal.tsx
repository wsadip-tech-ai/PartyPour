'use client'

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog'
import { createClient } from '@/lib/supabase/client'
import { toast } from 'sonner'

interface SendNotificationModalProps {
  open: boolean
  onClose: () => void
  userIds: string[]
  userCount: number
}

export function SendNotificationModal({ open, onClose, userIds, userCount }: SendNotificationModalProps) {
  const supabase = createClient()
  const [title, setTitle] = useState('')
  const [message, setMessage] = useState('')
  const [sending, setSending] = useState(false)

  const handleSend = async () => {
    if (!title.trim() || !message.trim()) {
      toast.error('Title and message are required')
      return
    }

    setSending(true)

    const notifications = userIds.map((userId) => ({
      user_id: userId,
      title: title.trim(),
      message: message.trim(),
    }))

    const { error: notifError } = await supabase.from('notifications').insert(notifications)
    if (notifError) {
      toast.error('Failed to send in-app notifications')
      setSending(false)
      return
    }

    try {
      await supabase.functions.invoke('send-push-notification', {
        body: { user_ids: userIds, title: title.trim(), message: message.trim() },
      })
    } catch {
      console.warn('Push notification delivery failed — FCM may not be configured')
    }

    toast.success(`Notification sent to ${userCount} user${userCount !== 1 ? 's' : ''}`)
    setTitle('')
    setMessage('')
    setSending(false)
    onClose()
  }

  return (
    <Dialog open={open} onOpenChange={(v) => !v && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Send Notification</DialogTitle>
        </DialogHeader>
        <p className="text-sm text-muted-foreground mb-4">
          Sending to <strong>{userCount}</strong> user{userCount !== 1 ? 's' : ''}. They will receive an in-app notification and push notification (if enabled).
        </p>
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="notif-title">Title</Label>
            <Input id="notif-title" placeholder="e.g. Complete your order!" value={title} onChange={(e) => setTitle(e.target.value)} />
          </div>
          <div className="space-y-2">
            <Label htmlFor="notif-message">Message</Label>
            <Textarea id="notif-message" placeholder="e.g. You left your beverage selection incomplete — come back and finish!" value={message} onChange={(e) => setMessage(e.target.value)} rows={3} />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" onClick={onClose} disabled={sending}>Cancel</Button>
          <Button onClick={handleSend} disabled={sending || !title.trim() || !message.trim()}>
            {sending ? 'Sending...' : `Send to ${userCount} user${userCount !== 1 ? 's' : ''}`}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
