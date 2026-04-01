'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Category, Subcategory } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { toast } from 'sonner'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default function CategoriesPage() {
  const supabase = createClient()
  const [categories, setCategories] = useState<(Category & { subcategories: Subcategory[] })[]>([])
  const [loading, setLoading] = useState(true)
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [categoryName, setCategoryName] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [subDialogOpen, setSubDialogOpen] = useState(false)
  const [editingSub, setEditingSub] = useState<Subcategory | null>(null)
  const [subName, setSubName] = useState('')
  const [subCategoryId, setSubCategoryId] = useState('')

  const fetchCategories = async () => {
    const { data } = await supabase.from('categories').select('*, subcategories(*)').order('sort_order')
    setCategories(data ?? [])
    setLoading(false)
  }

  useEffect(() => { fetchCategories() }, [])

  const saveCategory = async () => {
    const slug = categoryName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    if (editingCategory) {
      await supabase.from('categories').update({ name: categoryName, slug }).eq('id', editingCategory.id)
    } else {
      const maxOrder = Math.max(0, ...categories.map(c => c.sort_order))
      await supabase.from('categories').insert({ name: categoryName, slug, sort_order: maxOrder + 1 })
    }
    toast.success(editingCategory ? 'Category updated' : 'Category created')
    setDialogOpen(false); setCategoryName(''); setEditingCategory(null); fetchCategories()
  }

  const deleteCategory = async (id: string) => {
    if (!confirm('Delete this category and all its subcategories?')) return
    await supabase.from('categories').delete().eq('id', id)
    toast.success('Category deleted'); fetchCategories()
  }

  const saveSubcategory = async () => {
    const slug = subName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    if (editingSub) {
      await supabase.from('subcategories').update({ name: subName, slug }).eq('id', editingSub.id)
    } else {
      const parent = categories.find(c => c.id === subCategoryId)
      const maxOrder = Math.max(0, ...(parent?.subcategories.map(s => s.sort_order) ?? [0]))
      await supabase.from('subcategories').insert({ name: subName, slug, category_id: subCategoryId, sort_order: maxOrder + 1 })
    }
    toast.success(editingSub ? 'Subcategory updated' : 'Subcategory created')
    setSubDialogOpen(false); setSubName(''); setEditingSub(null); fetchCategories()
  }

  const deleteSubcategory = async (id: string) => {
    if (!confirm('Delete this subcategory and all its products?')) return
    await supabase.from('subcategories').delete().eq('id', id)
    toast.success('Subcategory deleted'); fetchCategories()
  }

  if (loading) return <p>Loading...</p>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Categories</h1>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => { setEditingCategory(null); setCategoryName('') }}><Plus className="h-4 w-4 mr-2" /> Add Category</Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader><DialogTitle>{editingCategory ? 'Edit' : 'New'} Category</DialogTitle></DialogHeader>
            <div className="space-y-4">
              <div><Label>Name</Label><Input value={categoryName} onChange={(e) => setCategoryName(e.target.value)} /></div>
              <Button onClick={saveCategory} className="w-full">Save</Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>
      <div className="space-y-6">
        {categories.map((cat) => (
          <Card key={cat.id}>
            <CardHeader className="flex flex-row items-center justify-between">
              <CardTitle>{cat.name}</CardTitle>
              <div className="flex gap-2">
                <Button variant="ghost" size="icon" onClick={() => { setEditingCategory(cat); setCategoryName(cat.name); setDialogOpen(true) }}><Pencil className="h-4 w-4" /></Button>
                <Button variant="ghost" size="icon" onClick={() => deleteCategory(cat.id)}><Trash2 className="h-4 w-4 text-destructive" /></Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {cat.subcategories?.map((sub) => (
                  <div key={sub.id} className="flex items-center justify-between p-2 rounded bg-muted">
                    <span>{sub.name}</span>
                    <div className="flex gap-1">
                      <Button variant="ghost" size="sm" onClick={() => { setEditingSub(sub); setSubName(sub.name); setSubCategoryId(cat.id); setSubDialogOpen(true) }}><Pencil className="h-3 w-3" /></Button>
                      <Button variant="ghost" size="sm" onClick={() => deleteSubcategory(sub.id)}><Trash2 className="h-3 w-3 text-destructive" /></Button>
                    </div>
                  </div>
                ))}
                <Button variant="outline" size="sm" onClick={() => { setEditingSub(null); setSubName(''); setSubCategoryId(cat.id); setSubDialogOpen(true) }}><Plus className="h-3 w-3 mr-1" /> Add Subcategory</Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
      <Dialog open={subDialogOpen} onOpenChange={setSubDialogOpen}>
        <DialogContent>
          <DialogHeader><DialogTitle>{editingSub ? 'Edit' : 'New'} Subcategory</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div><Label>Name</Label><Input value={subName} onChange={(e) => setSubName(e.target.value)} /></div>
            <Button onClick={saveSubcategory} className="w-full">Save</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
