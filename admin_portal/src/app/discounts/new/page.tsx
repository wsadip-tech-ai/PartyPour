'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Card, CardContent } from '@/components/ui/card'
import { toast } from 'sonner'

export default function NewDiscountPage() {
  const supabase = createClient()
  const router = useRouter()
  const [variants, setVariants] = useState<any[]>([])
  const [variantId, setVariantId] = useState<string>('')
  const [type, setType] = useState<'percentage' | 'flat'>('percentage')
  const [value, setValue] = useState('')
  const [validFrom, setValidFrom] = useState('')
  const [validUntil, setValidUntil] = useState('')

  useEffect(() => { supabase.from('variants').select('*, products(name)').eq('is_active', true).order('size').then(({ data }: { data: any }) => setVariants(data ?? [])) }, [])

  const handleSave = async () => {
    const { error } = await supabase.from('discounts').insert({ variant_id: variantId || null, type, value: parseFloat(value), valid_from: new Date(validFrom).toISOString(), valid_until: new Date(validUntil).toISOString() })
    if (error) { toast.error(error.message); return }
    toast.success('Discount created'); router.push('/discounts')
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-3xl font-bold mb-8">New Discount</h1>
      <Card><CardContent className="pt-6 space-y-4">
        <div><Label>Product Variant (leave empty for event-wide)</Label>
          <Select value={variantId} onValueChange={(v) => setVariantId(v ?? '')}><SelectTrigger><SelectValue placeholder="Select variant (optional)" /></SelectTrigger><SelectContent>{variants.map((v: any) => <SelectItem key={v.id} value={v.id}>{v.products.name} — {v.size}</SelectItem>)}</SelectContent></Select>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div><Label>Type</Label><Select value={type} onValueChange={(v) => v && setType(v as 'percentage' | 'flat')}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="percentage">Percentage (%)</SelectItem><SelectItem value="flat">Flat (NPR)</SelectItem></SelectContent></Select></div>
          <div><Label>Value</Label><Input type="number" value={value} onChange={(e) => setValue(e.target.value)} /></div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div><Label>Valid From</Label><Input type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} /></div>
          <div><Label>Valid Until</Label><Input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} /></div>
        </div>
        <Button onClick={handleSave} className="w-full" disabled={!value || !validFrom || !validUntil}>Create Discount</Button>
      </CardContent></Card>
    </div>
  )
}
