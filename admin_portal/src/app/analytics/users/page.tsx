'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { SendNotificationModal } from '@/components/send-notification-modal'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'
import { Bell } from 'lucide-react'

interface AnalyticsUser {
  id: string
  full_name: string | null
  email: string | null
  order_count: number
  last_wizard_step: number | null
  last_active: string | null
  segment: string
}

export default function AnalyticsUsersPage() {
  const supabase = createClient()
  const [users, setUsers] = useState<AnalyticsUser[]>([])
  const [search, setSearch] = useState('')
  const [segment, setSegment] = useState('all')
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set())
  const [modalOpen, setModalOpen] = useState(false)

  const fetchUsers = useCallback(async () => {
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, full_name, email, role')
      .eq('role', 'customer')

    if (!profiles) { setUsers([]); return }

    const { data: orders } = await supabase.from('orders').select('user_id')
    const orderCounts = new Map<string, number>()
    for (const o of orders ?? []) {
      orderCounts.set(o.user_id, (orderCounts.get(o.user_id) ?? 0) + 1)
    }

    const { data: wizardEvents } = await supabase
      .from('analytics_events')
      .select('user_id, properties, created_at')
      .eq('event_name', 'wizard_step_entered')
      .order('created_at', { ascending: false })

    const lastWizardStep = new Map<string, number>()
    for (const e of wizardEvents ?? []) {
      if (!lastWizardStep.has((e as any).user_id)) {
        lastWizardStep.set((e as any).user_id, (e.properties as any)?.step ?? 0)
      }
    }

    const { data: lastActivity } = await supabase
      .from('analytics_events')
      .select('user_id, created_at')
      .order('created_at', { ascending: false })

    const lastActiveMap = new Map<string, string>()
    for (const e of lastActivity ?? []) {
      if (!lastActiveMap.has((e as any).user_id)) {
        lastActiveMap.set((e as any).user_id, e.created_at)
      }
    }

    const result: AnalyticsUser[] = (profiles as any[]).map((p) => {
      const oc = orderCounts.get(p.id) ?? 0
      const ws = lastWizardStep.get(p.id)
      let seg = 'signed_up_only'
      if (oc > 0) seg = 'converted'
      else if (ws) seg = `dropped_step_${ws}`

      return {
        id: p.id, full_name: p.full_name, email: p.email,
        order_count: oc, last_wizard_step: ws ?? null,
        last_active: lastActiveMap.get(p.id) ?? null, segment: seg,
      }
    })

    setUsers(result)
  }, [])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  const filtered = users.filter((u) => {
    const matchesSearch = !search ||
      u.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      u.email?.toLowerCase().includes(search.toLowerCase())
    const matchesSegment = segment === 'all' || u.segment === segment ||
      (segment === 'dropped_any' && u.segment.startsWith('dropped_step_'))
    return matchesSearch && matchesSegment
  })

  const toggleSelect = (id: string) => {
    const next = new Set(selectedIds)
    if (next.has(id)) next.delete(id); else next.add(id)
    setSelectedIds(next)
  }

  const selectAllFiltered = () => {
    if (selectedIds.size === filtered.length) setSelectedIds(new Set())
    else setSelectedIds(new Set(filtered.map((u) => u.id)))
  }

  const segmentLabel = (seg: string) => {
    if (seg === 'converted') return { text: 'Converted', className: 'bg-green-100 text-green-800' }
    if (seg === 'signed_up_only') return { text: 'Signed Up Only', className: 'bg-gray-100 text-gray-600' }
    if (seg.startsWith('dropped_step_')) {
      const step = seg.replace('dropped_step_', '')
      return { text: `Dropped Step ${step}`, className: 'bg-orange-100 text-orange-800' }
    }
    return { text: seg, className: '' }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4 flex-wrap">
        <Input placeholder="Search name or email..." value={search} onChange={(e) => setSearch(e.target.value)} className="max-w-sm" />
        <Select value={segment} onValueChange={(v) => { setSegment(v ?? 'all'); setSelectedIds(new Set()) }}>
          <SelectTrigger className="w-52"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Users</SelectItem>
            <SelectItem value="converted">Converted</SelectItem>
            <SelectItem value="dropped_any">Dropped (any step)</SelectItem>
            <SelectItem value="dropped_step_1">Dropped Step 1</SelectItem>
            <SelectItem value="dropped_step_2">Dropped Step 2</SelectItem>
            <SelectItem value="dropped_step_3">Dropped Step 3</SelectItem>
            <SelectItem value="dropped_step_4">Dropped Step 4</SelectItem>
            <SelectItem value="dropped_step_5">Dropped Step 5</SelectItem>
            <SelectItem value="dropped_step_6">Dropped Step 6</SelectItem>
            <SelectItem value="signed_up_only">Signed Up Only</SelectItem>
          </SelectContent>
        </Select>
        {selectedIds.size > 0 && (
          <Button className="gap-2" onClick={() => setModalOpen(true)}>
            <Bell className="h-4 w-4" /> Send Notification ({selectedIds.size})
          </Button>
        )}
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead className="w-10">
              <input type="checkbox" checked={selectedIds.size === filtered.length && filtered.length > 0} onChange={selectAllFiltered} className="rounded" />
            </TableHead>
            <TableHead>Customer</TableHead>
            <TableHead>Segment</TableHead>
            <TableHead className="text-center">Last Step</TableHead>
            <TableHead className="text-center">Orders</TableHead>
            <TableHead>Last Active</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {filtered.map((u) => {
            const sl = segmentLabel(u.segment)
            return (
              <TableRow key={u.id}>
                <TableCell>
                  <input type="checkbox" checked={selectedIds.has(u.id)} onChange={() => toggleSelect(u.id)} className="rounded" />
                </TableCell>
                <TableCell>
                  <Link href={`/customers/${u.id}`} className="flex items-center gap-3">
                    <div className={`h-8 w-8 rounded-full ${getAvatarColor(u.full_name, u.email)} text-white flex items-center justify-center text-sm font-bold shrink-0`}>
                      {getInitials(u.full_name, u.email)}
                    </div>
                    <div>
                      <p className="font-medium">{u.full_name ?? 'Unknown'}</p>
                      <p className="text-xs text-muted-foreground">{u.email ?? 'No email'}</p>
                    </div>
                  </Link>
                </TableCell>
                <TableCell>
                  <Badge className={sl.className + ' hover:' + sl.className}>{sl.text}</Badge>
                </TableCell>
                <TableCell className="text-center">{u.last_wizard_step ? `Step ${u.last_wizard_step}` : '—'}</TableCell>
                <TableCell className="text-center font-medium">{u.order_count}</TableCell>
                <TableCell className="text-sm text-muted-foreground">
                  {u.last_active ? new Date(u.last_active).toLocaleDateString() : '—'}
                </TableCell>
              </TableRow>
            )
          })}
          {filtered.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="text-center text-muted-foreground py-8">No users found</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      <SendNotificationModal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        userIds={Array.from(selectedIds)}
        userCount={selectedIds.size}
      />
    </div>
  )
}
