interface FunnelStep {
  label: string
  count: number
}

export function FunnelChart({ steps }: { steps: FunnelStep[] }) {
  const maxCount = steps[0]?.count || 1

  return (
    <div className="space-y-3">
      {steps.map((step, i) => {
        const prevCount = i > 0 ? steps[i - 1].count : step.count
        const dropOff = prevCount > 0 ? ((prevCount - step.count) / prevCount * 100).toFixed(1) : '0'
        const widthPct = Math.max((step.count / maxCount) * 100, 8)
        const isFirst = i === 0

        return (
          <div key={step.label}>
            {!isFirst && prevCount > step.count && (
              <div className="flex items-center gap-2 ml-4 mb-1">
                <span className="text-xs text-red-500 font-medium">↓ {dropOff}% drop-off ({prevCount - step.count} users)</span>
              </div>
            )}
            <div className="flex items-center gap-3">
              <span className="text-sm font-medium w-32 text-right shrink-0">{step.label}</span>
              <div className="flex-1">
                <div
                  className="h-10 rounded-md flex items-center px-3 text-sm font-bold text-white transition-all"
                  style={{
                    width: `${widthPct}%`,
                    backgroundColor: `hsl(${150 - (i * 20)}, 70%, ${45 + (i * 5)}%)`,
                  }}
                >
                  {step.count}
                </div>
              </div>
              <span className="text-xs text-muted-foreground w-16 shrink-0">
                {i > 0 ? `${((step.count / (steps[0]?.count || 1)) * 100).toFixed(0)}%` : '100%'}
              </span>
            </div>
          </div>
        )
      })}
    </div>
  )
}
