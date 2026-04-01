'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Discount } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { toast } from 'sonner'
import { Plus, Trash2 } from 'lucide-react'

export default function DiscountsPage() {
  const supabase = createClient()
  const [discounts, setDiscounts] = useState<any[]>([])

  const fetchDiscounts = async () => {
    const { data } = await supabase.from('discounts').select('*, variants(size, products(name))').order('created_at', { ascending: false })
    setDiscounts(data ?? [])
  }

  useEffect(() => { fetchDiscounts() }, [])

  const deleteDiscount = async (id: string) => {
    if (!confirm('Delete this discount?')) return
    await supabase.from('discounts').delete().eq('id', id)
    toast.success('Discount deleted'); fetchDiscounts()
  }

  const isExpired = (d: Discount) => new Date(d.valid_until) < new Date()

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Discounts</h1>
        <Link href="/discounts/new"><Plus className="h-4 w-4 mr-2" /> New Discount</Link>
      </div>
      <Table>
        <TableHeader><TableRow><TableHead>Product</TableHead><TableHead>Variant</TableHead><TableHead>Type</TableHead><TableHead>Value</TableHead><TableHead>Valid Until</TableHead><TableHead>Status</TableHead><TableHead></TableHead></TableRow></TableHeader>
        <TableBody>
          {discounts.map((d) => (
            <TableRow key={d.id}>
              <TableCell>{d.variants?.products?.name ?? 'Event-wide'}</TableCell>
              <TableCell>{d.variants?.size ?? '-'}</TableCell>
              <TableCell>{d.type}</TableCell>
              <TableCell>{d.type === 'percentage' ? `${d.value}%` : `NPR ${d.value}`}</TableCell>
              <TableCell>{new Date(d.valid_until).toLocaleDateString()}</TableCell>
              <TableCell><Badge variant={isExpired(d) ? 'destructive' : d.is_active ? 'default' : 'secondary'}>{isExpired(d) ? 'Expired' : d.is_active ? 'Active' : 'Inactive'}</Badge></TableCell>
              <TableCell><Button variant="ghost" size="icon" onClick={() => deleteDiscount(d.id)}><Trash2 className="h-4 w-4 text-destructive" /></Button></TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
