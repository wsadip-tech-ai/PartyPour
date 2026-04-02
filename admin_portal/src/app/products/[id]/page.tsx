'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Product, Variant, Subcategory } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { ImageUpload } from '@/components/image-upload'
import { toast } from 'sonner'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default function EditProductPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const [product, setProduct] = useState<Product | null>(null)
  const [subcategories, setSubcategories] = useState<Subcategory[]>([])
  const [name, setName] = useState('')
  const [subcategoryId, setSubcategoryId] = useState('')
  const [origin, setOrigin] = useState<'local' | 'imported'>('local')
  const [description, setDescription] = useState('')
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [isActive, setIsActive] = useState(true)
  const [variantDialog, setVariantDialog] = useState(false)
  const [editingVariant, setEditingVariant] = useState<Variant | null>(null)
  const [vSize, setVSize] = useState('')
  const [vUnitPrice, setVUnitPrice] = useState('')
  const [vCaseSize, setVCaseSize] = useState('')
  const [vCasePrice, setVCasePrice] = useState('')
  const [vMrp, setVMrp] = useState('')

  const fetchProduct = async () => {
    const { data, error } = await supabase.from('products').select('*, variants(*)').eq('id', id).single()
    if (error) { console.error('fetchProduct error:', error); toast.error('Failed to load product: ' + error.message); return }
    if (data) { setProduct(data); setName(data.name); setSubcategoryId(data.subcategory_id); setOrigin(data.origin); setDescription(data.description ?? ''); setImageUrl(data.image_url); setIsActive(data.is_active) }
  }

  useEffect(() => {
    const init = async () => {
      // Check auth first
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) { console.error('Not authenticated'); toast.error('Please log in first'); return }

      const { data: subs } = await supabase.from('subcategories').select('*').order('name')
      setSubcategories(subs ?? [])
      await fetchProduct()
    }
    init()
  }, [])

  const saveProduct = async () => {
    await supabase.from('products').update({ name, subcategory_id: subcategoryId, origin, description: description || null, image_url: imageUrl, is_active: isActive }).eq('id', id)
    toast.success('Product updated'); fetchProduct()
  }

  const openVariantForm = (variant?: Variant) => {
    setEditingVariant(variant ?? null); setVSize(variant?.size ?? ''); setVUnitPrice(variant?.unit_price?.toString() ?? '')
    setVCaseSize(variant?.case_size?.toString() ?? ''); setVCasePrice(variant?.case_price?.toString() ?? ''); setVMrp(variant?.mrp?.toString() ?? ''); setVariantDialog(true)
  }

  const saveVariant = async () => {
    const data = { product_id: id, size: vSize, unit_price: parseFloat(vUnitPrice), case_size: vCaseSize ? parseInt(vCaseSize) : null, case_price: vCasePrice ? parseFloat(vCasePrice) : null, mrp: vMrp ? parseFloat(vMrp) : null }
    if (editingVariant) { await supabase.from('variants').update(data).eq('id', editingVariant.id) }
    else { await supabase.from('variants').insert(data) }
    toast.success(editingVariant ? 'Variant updated' : 'Variant added'); setVariantDialog(false); fetchProduct()
  }

  const deleteVariant = async (variantId: string) => {
    if (!confirm('Delete this variant?')) return
    await supabase.from('variants').delete().eq('id', variantId)
    toast.success('Variant deleted'); fetchProduct()
  }

  if (!product) return <div className="flex items-center justify-center h-64"><p className="text-muted-foreground">Loading product...</p></div>

  return (
    <div className="max-w-4xl space-y-8">
      <h1 className="text-3xl font-bold">Edit Product</h1>
      <Card>
        <CardHeader><CardTitle>Product Details</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div><Label>Name</Label><Input value={name} onChange={(e) => setName(e.target.value)} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div><Label>Subcategory</Label>{subcategories.length > 0 && subcategoryId ? (
              <Select value={subcategoryId} onValueChange={(v) => setSubcategoryId(v ?? '')}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent>{subcategories.map(s => <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}</SelectContent></Select>
            ) : <p className="text-sm text-muted-foreground">Loading...</p>}</div>
            <div><Label>Origin</Label><Select value={origin} onValueChange={(v) => v && setOrigin(v as 'local' | 'imported')}><SelectTrigger><SelectValue /></SelectTrigger><SelectContent><SelectItem value="local">Local</SelectItem><SelectItem value="imported">Imported</SelectItem></SelectContent></Select></div>
          </div>
          <div><Label>Description</Label><Textarea value={description} onChange={(e) => setDescription(e.target.value)} /></div>
          <div><Label>Image</Label><ImageUpload currentUrl={imageUrl} onUpload={setImageUrl} /></div>
          <div className="flex items-center gap-2"><input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} /><Label>Active</Label></div>
          <Button onClick={saveProduct} className="w-full">Save Product</Button>
        </CardContent>
      </Card>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Variants & Pricing</CardTitle>
          <Button size="sm" onClick={() => openVariantForm()}><Plus className="h-4 w-4 mr-2" /> Add Variant</Button>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader><TableRow><TableHead>Size</TableHead><TableHead>Unit Price</TableHead><TableHead>Case Size</TableHead><TableHead>Case Price</TableHead><TableHead>MRP</TableHead><TableHead></TableHead></TableRow></TableHeader>
            <TableBody>
              {product.variants?.map((v) => (
                <TableRow key={v.id}>
                  <TableCell>{v.size}</TableCell><TableCell>NPR {v.unit_price}</TableCell><TableCell>{v.case_size ?? '-'}</TableCell>
                  <TableCell>{v.case_price ? `NPR ${v.case_price}` : '-'}</TableCell><TableCell>{v.mrp ? `NPR ${v.mrp}` : '-'}</TableCell>
                  <TableCell className="flex gap-1">
                    <Button variant="ghost" size="icon" onClick={() => openVariantForm(v)}><Pencil className="h-4 w-4" /></Button>
                    <Button variant="ghost" size="icon" onClick={() => deleteVariant(v.id)}><Trash2 className="h-4 w-4 text-destructive" /></Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      <Dialog open={variantDialog} onOpenChange={setVariantDialog}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editingVariant ? 'Edit' : 'Add'} Variant</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div><Label>Size (e.g., 750ml, 20L Keg)</Label><Input value={vSize} onChange={(e) => setVSize(e.target.value)} /></div>
            <div><Label>Unit Price (NPR)</Label><Input type="number" value={vUnitPrice} onChange={(e) => setVUnitPrice(e.target.value)} /></div>
            <div className="grid grid-cols-2 gap-4">
              <div><Label>Case Size (optional)</Label><Input type="number" value={vCaseSize} onChange={(e) => setVCaseSize(e.target.value)} /></div>
              <div><Label>Case Price (optional)</Label><Input type="number" value={vCasePrice} onChange={(e) => setVCasePrice(e.target.value)} /></div>
            </div>
            <div><Label>MRP (optional)</Label><Input type="number" value={vMrp} onChange={(e) => setVMrp(e.target.value)} /></div>
            <Button onClick={saveVariant} className="w-full" disabled={!vSize || !vUnitPrice}>Save Variant</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
