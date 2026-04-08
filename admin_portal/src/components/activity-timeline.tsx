import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

interface TimelineEvent {
  id: string
  title: string
  message: string
  created_at: string
}

const dotColors: Record<string, string> = {
  'Confirmed': 'bg-green-500',
  'Dispatched': 'bg-blue-500',
  'Delivered': 'bg-purple-500',
  'Cancelled': 'bg-red-500',
  'Placed': 'bg-orange-500',
}

function getDotColor(title: string): string {
  for (const [key, color] of Object.entries(dotColors)) {
    if (title.toLowerCase().includes(key.toLowerCase())) return color
  }
  return 'bg-gray-400'
}

function timeAgo(dateStr: string): string {
  const now = new Date()
  const date = new Date(dateStr)
  const diffMs = now.getTime() - date.getTime()
  const mins = Math.floor(diffMs / 60000)
  if (mins < 1) return 'just now'
  if (mins < 60) return `${mins}m ago`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `${hrs}h ago`
  const days = Math.floor(hrs / 24)
  if (days < 7) return `${days}d ago`
  return date.toLocaleDateString()
}

export function ActivityTimeline({ events }: { events: TimelineEvent[] }) {
  return (
    <Card>
      <CardHeader><CardTitle>Activity</CardTitle></CardHeader>
      <CardContent>
        {events.length === 0 ? (
          <p className="text-sm text-muted-foreground">No activity yet</p>
        ) : (
          <div className="space-y-3">
            {events.map((event) => (
              <div key={event.id} className="flex items-start gap-3">
                <div className={`mt-1.5 h-2.5 w-2.5 rounded-full shrink-0 ${getDotColor(event.title)}`} />
                <div className="min-w-0">
                  <p className="text-sm font-medium">{event.title}</p>
                  <p className="text-xs text-muted-foreground">{event.message}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">
                    {new Date(event.created_at).toLocaleString()} · {timeAgo(event.created_at)}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
