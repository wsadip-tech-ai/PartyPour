import { Check, X } from 'lucide-react'

const steps = [
  { key: 'pending', label: 'Pending' },
  { key: 'confirmed', label: 'Confirmed' },
  { key: 'dispatched', label: 'Dispatched' },
  { key: 'delivered', label: 'Delivered' },
] as const

const statusIndex: Record<string, number> = {
  pending: 0, confirmed: 1, dispatched: 2, delivered: 3, cancelled: -1,
}

const bannerStyles: Record<string, { bg: string; border: string; text: string; label: string }> = {
  pending:    { bg: 'bg-orange-50',  border: 'border-orange-300', text: 'text-orange-800', label: 'Awaiting Confirmation' },
  confirmed:  { bg: 'bg-green-50',   border: 'border-green-300',  text: 'text-green-800',  label: 'Order Confirmed' },
  dispatched: { bg: 'bg-blue-50',    border: 'border-blue-300',   text: 'text-blue-800',   label: 'Out for Delivery' },
  delivered:  { bg: 'bg-purple-50',  border: 'border-purple-300', text: 'text-purple-800', label: 'Delivered' },
  cancelled:  { bg: 'bg-red-50',     border: 'border-red-300',    text: 'text-red-800',    label: 'Order Cancelled' },
}

export function OrderProgress({ status }: { status: string }) {
  const current = statusIndex[status] ?? 0
  const isCancelled = status === 'cancelled'
  const banner = bannerStyles[status] ?? bannerStyles['pending']

  return (
    <div className={`rounded-lg border-2 px-5 py-4 ${banner.bg} ${banner.border}`}>
      <div className="flex items-center justify-between mb-3">
        <div>
          <p className={`text-xs font-semibold uppercase tracking-widest ${banner.text} opacity-70`}>Current Status</p>
          <p className={`text-2xl font-bold mt-0.5 ${banner.text}`}>{banner.label}</p>
        </div>
        <span className={`rounded-full border ${banner.border} ${banner.bg} ${banner.text} px-3 py-1 text-sm font-semibold capitalize`}>
          {status}
        </span>
      </div>

      {/* Progress bar */}
      <div className="flex items-center gap-1">
        {steps.map((step, i) => {
          const completed = !isCancelled && i <= current
          const isCurrent = !isCancelled && i === current
          return (
            <div key={step.key} className="flex-1 flex flex-col items-center gap-1">
              <div className={`w-full h-2 rounded-full transition-colors ${
                isCancelled ? 'bg-red-200' :
                completed ? 'bg-green-500' : 'bg-gray-200'
              }`} />
              <div className="flex items-center gap-1">
                {isCancelled ? (
                  <X className="h-3 w-3 text-red-400" />
                ) : completed ? (
                  <Check className="h-3 w-3 text-green-600" />
                ) : null}
                <span className={`text-xs ${
                  isCurrent ? 'font-semibold text-foreground' :
                  completed ? 'text-green-700' : 'text-muted-foreground'
                }`}>{step.label}</span>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
