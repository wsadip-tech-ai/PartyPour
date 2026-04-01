'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Subcategory } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Card, CardContent } from '@/components/ui/card'
import { ImageUpload } from '@/components/image-upload'
import { toast } from 'sonner'

export default function NewProductPage() {
  const supabase = createClient()
  const router = useRouter()
  const [subcategories, setSubcategories] = useState<Subcategory[]>([])
  const [name, setName] = useState('')
  const [subcategoryId, setSubcategoryId] = useState('')
  const [origin, setOrigin] = useState<'local' | 'imported'>('local')
  const [description, setDescription] = useState('')
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => { supabase.from('subcategories').select('*').order('name').then(({ data }) => setSubcategories(data ?? [])) }, [])

  const handleSave = async () => {
    setSaving(true)
    const { data, error } = await supabase.from('products').insert({ name, subcategory_id: subcategoryId, origin, description: description || null, image_url: imageUrl }).select().single()
    if (error) { toast.error(error.message); setSaving(false); return }
    toast.success('Product created')
    router.push(`/products/${data.id}`)
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-3xl font-bold mb-8">New Product</h1>
      <Card><CardContent className="pt-6 space-y-4">
        <div><Label>Product Name</Label><Input value={name} onChange={(e) => setName(e.target.value)} /></div>
        <div><Label>Subcategory</Label>
          <Select value={subcategoryId} onValueChange={setSubcategoryId}><SelectTrigger><SelectValue placeholder="Select subcategory" /></SelectTrigger><SelectContent>{subcategories.map(s => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent></Select>
        </div>
        <div><Label>Origin</Label>
          <Select value={origin} onValueChange={(v) => setOrigin(v as 'local' | 'imported')}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="local">Local</SelectItem><SelectItem value="imported">Imported</SelectItem></SelectContent></Select>
        </div>
        <div><Label>Description</Label><Textarea value={description} onChange={(e) => setDescription(e.target.value)} /></div>
        <div><Label>Image</Label><ImageUpload currentUrl={imageUrl} onUpload={setImageUrl} /></div>
        <Button onClick={handleSave} disabled={saving || !name || !subcategoryId} className="w-full">{saving ? 'Saving...' : 'Create Product'}</Button>
      </CardContent></Card>
    </div>
  )
}
