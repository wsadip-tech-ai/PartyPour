'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Product } from '@/lib/types'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { toast } from 'sonner'

export default function EquipmentPage() {
  const supabase = createClient()
  const [equipment, setEquipment] = useState<Product[]>([])

  const fetchEquipment = async () => {
    const { data: subcat } = await supabase.from('subcategories').select('id').eq('slug', 'draught-beer-setup').single()
    if (!subcat) return
    const { data } = await supabase.from('products').select('*, variants(*)').eq('subcategory_id', subcat.id).order('name')
    setEquipment(data ?? [])
  }

  useEffect(() => { fetchEquipment() }, [])

  const toggleActive = async (productId: string, currentStatus: boolean) => {
    await supabase.from('products').update({ is_active: !currentStatus }).eq('id', productId)
    toast.success(`Equipment ${currentStatus ? 'deactivated' : 'activated'}`); fetchEquipment()
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Equipment Inventory</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {equipment.map((item) => (
          <Card key={item.id}>
            <CardHeader><div className="flex items-center justify-between">
              <CardTitle className="text-lg">{item.name}</CardTitle>
              <Badge variant={item.is_active ? 'default' : 'destructive'}>{item.is_active ? 'Available' : 'Unavailable'}</Badge>
            </div></CardHeader>
            <CardContent>
              {item.variants?.map(v => <p key={v.id} className="text-sm">{v.size}: <strong>NPR {v.unit_price}</strong>{v.mrp && <span className="text-muted-foreground ml-2">(MRP: NPR {v.mrp})</span>}</p>)}
              <Button variant="outline" size="sm" className="mt-4" onClick={() => toggleActive(item.id, item.is_active)}>Mark as {item.is_active ? 'Unavailable' : 'Available'}</Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
