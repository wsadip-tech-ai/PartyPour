// src/app/customers/page.tsx
'use client'

import { useEffect, useState, useCallback } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { CustomerWithStats } from '@/lib/types'
import { StatCard } from '@/components/stat-card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Users, UserCheck, UserX } from 'lucide-react'
import { getInitials, getAvatarColor } from '@/lib/utils/avatar'

export default function CustomersPage() {
  const supabase = createClient()
  const [customers, setCustomers] = useState<CustomerWithStats[]>([])
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')

  const fetchCustomers = useCallback(async () => {
    const { data: profiles } = await supabase
      .from('profiles')
      .select('id, full_name, email, phone, role, created_at')
      .eq('role', 'customer')
      .order('created_at', { ascending: false })

    if (!profiles) { setCustomers([]); return }

    const { data: orders } = await supabase
      .from('orders')
      .select('user_id, final_amount')

    const orderMap = new Map<string, { count: number; total: number }>()
    for (const o of orders ?? []) {
      const existing = orderMap.get(o.user_id) ?? { count: 0, total: 0 }
      existing.count++
      existing.total += o.final_amount ?? 0
      orderMap.set(o.user_id, existing)
    }

    const { data: wizardEvents } = await supabase
      .from('analytics_events')
      .select('user_id, properties')
      .eq('event_name', 'wizard_step_entered')
      .order('created_at', { ascending: false })

    const wizardMap = new Map<string, number>()
    for (const e of wizardEvents ?? []) {
      if (!wizardMap.has((e as any).user_id)) {
        wizardMap.set((e as any).user_id, (e.properties as any)?.step ?? 0)
      }
    }

    const result: CustomerWithStats[] = profiles.map((p: any) => {
      const stats = orderMap.get(p.id) ?? { count: 0, total: 0 }
      return {
        ...p,
        order_count: stats.count,
        total_spent: stats.total,
        last_order_date: null,
        last_wizard_step: wizardMap.get(p.id) ?? null,
      }
    })

    setCustomers(result)
  }, [])

  useEffect(() => { fetchCustomers() }, [fetchCustomers])

  const filtered = customers.filter((c) => {
    const matchesSearch = !search ||
      (c.full_name?.toLowerCase().includes(search.toLowerCase())) ||
      (c.email?.toLowerCase().includes(search.toLowerCase()))
    const matchesStatus = statusFilter === 'all' ||
      (statusFilter === 'converted' && c.order_count > 0) ||
      (statusFilter === 'not_converted' && c.order_count === 0)
    return matchesSearch && matchesStatus
  })

  const totalUsers = customers.length
  const converted = customers.filter((c) => c.order_count > 0).length
  const notConverted = totalUsers - converted

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Customers</h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <StatCard title="Total Users" value={totalUsers} icon={Users} />
        <StatCard title="Converted" value={converted} icon={UserCheck} description="Placed at least 1 order" />
        <StatCard title="Not Converted" value={notConverted} icon={UserX} description="Signed up but no orders" />
      </div>

      <div className="flex items-center gap-4 mb-6">
        <Input
          placeholder="Search by name or email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="max-w-sm"
        />
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v ?? 'all')}>
          <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Customers</SelectItem>
            <SelectItem value="converted">Converted</SelectItem>
            <SelectItem value="not_converted">Not Converted</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Customer</TableHead>
            <TableHead>Status</TableHead>
            <TableHead className="text-center">Last Step</TableHead>
            <TableHead className="text-center">Orders</TableHead>
            <TableHead className="text-right">Total Spent</TableHead>
            <TableHead>Joined</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {filtered.map((c) => (
            <TableRow key={c.id} className="cursor-pointer hover:bg-muted/50">
              <TableCell>
                <Link href={`/customers/${c.id}`} className="flex items-center gap-3">
                  <div className={`h-8 w-8 rounded-full ${getAvatarColor(c.full_name, c.email)} text-white flex items-center justify-center text-sm font-bold shrink-0`}>
                    {getInitials(c.full_name, c.email)}
                  </div>
                  <div>
                    <p className="font-medium">{c.full_name || 'Unknown'}</p>
                    <p className="text-xs text-muted-foreground">{c.email || 'No email'}</p>
                  </div>
                </Link>
              </TableCell>
              <TableCell>
                {c.order_count > 0 ? (
                  <Badge className="bg-green-100 text-green-800 hover:bg-green-100">Converted</Badge>
                ) : (c as any).last_wizard_step ? (
                  <Badge className="bg-orange-100 text-orange-800 hover:bg-orange-100">Step {(c as any).last_wizard_step}</Badge>
                ) : (
                  <Badge variant="outline" className="text-muted-foreground">Not Converted</Badge>
                )}
              </TableCell>
              <TableCell className="text-center text-sm">
                {(c as any).last_wizard_step ? `Step ${(c as any).last_wizard_step}` : '—'}
              </TableCell>
              <TableCell className="text-center font-medium">{c.order_count}</TableCell>
              <TableCell className="text-right">{c.total_spent > 0 ? `NPR ${c.total_spent.toLocaleString()}` : '—'}</TableCell>
              <TableCell className="text-muted-foreground text-sm">{new Date(c.created_at).toLocaleDateString()}</TableCell>
            </TableRow>
          ))}
          {filtered.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="text-center text-muted-foreground py-8">No customers found</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}
