'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { Plus, Pencil, Trash2, FileText, Bot } from 'lucide-react'

interface CompanyDoc {
  id: string
  title: string
  content: string
  category: string
  is_active: boolean
  created_at: string
  updated_at: string
}

const CATEGORIES = ['general', 'delivery', 'returns', 'payment', 'products', 'pricing', 'hours', 'offers', 'faq']

export default function CompanyDocsPage() {
  const supabase = createClient()
  const [docs, setDocs] = useState<CompanyDoc[]>([])
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<CompanyDoc | null>(null)
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [category, setCategory] = useState('general')

  const fetchDocs = async () => {
    const { data } = await supabase.from('company_docs').select('*').order('category').order('title')
    setDocs(data ?? [])
  }

  useEffect(() => { fetchDocs() }, [])

  const openNew = () => {
    setEditing(null)
    setTitle('')
    setContent('')
    setCategory('general')
    setDialogOpen(true)
  }

  const openEdit = (doc: CompanyDoc) => {
    setEditing(doc)
    setTitle(doc.title)
    setContent(doc.content)
    setCategory(doc.category)
    setDialogOpen(true)
  }

  const save = async () => {
    if (!title.trim() || !content.trim()) {
      toast.error('Title and content are required')
      return
    }

    if (editing) {
      const { error } = await supabase.from('company_docs').update({
        title: title.trim(),
        content: content.trim(),
        category,
      }).eq('id', editing.id)
      if (error) { toast.error(error.message); return }
      toast.success('Document updated')
    } else {
      const { error } = await supabase.from('company_docs').insert({
        title: title.trim(),
        content: content.trim(),
        category,
      })
      if (error) { toast.error(error.message); return }
      toast.success('Document added')
    }
    setDialogOpen(false)
    fetchDocs()
  }

  const toggleActive = async (doc: CompanyDoc) => {
    await supabase.from('company_docs').update({ is_active: !doc.is_active }).eq('id', doc.id)
    toast.success(`Document ${doc.is_active ? 'deactivated' : 'activated'}`)
    fetchDocs()
  }

  const deleteDoc = async (doc: CompanyDoc) => {
    if (!confirm(`Delete "${doc.title}"?`)) return
    await supabase.from('company_docs').delete().eq('id', doc.id)
    toast.success('Document deleted')
    fetchDocs()
  }

  // Group by category
  const grouped = docs.reduce<Record<string, CompanyDoc[]>>((acc, doc) => {
    (acc[doc.category] ??= []).push(doc)
    return acc
  }, {})

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">AI Knowledge Base</h1>
          <p className="text-muted-foreground mt-1">
            Manage documents that the AI chatbot uses to answer customer questions
          </p>
        </div>
        <Button onClick={openNew}>
          <Plus className="h-4 w-4 mr-2" />Add Document
        </Button>
      </div>

      <Card className="mb-6">
        <CardHeader>
          <CardTitle className="text-sm flex items-center gap-2">
            <Bot className="h-4 w-4" />How it works
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-muted-foreground">
            The AI chatbot reads all <strong>active</strong> documents below as its knowledge base.
            When a customer asks a question, the AI searches this content to provide accurate answers.
            Keep documents concise and factual. The AI also has access to the live product catalog automatically.
          </p>
        </CardContent>
      </Card>

      {Object.keys(grouped).length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <FileText className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
            <p className="text-muted-foreground">No documents yet. Add your first knowledge base document.</p>
          </CardContent>
        </Card>
      ) : (
        Object.entries(grouped).map(([cat, catDocs]) => (
          <div key={cat} className="mb-6">
            <h2 className="text-sm font-semibold text-muted-foreground uppercase tracking-wider mb-3">
              {cat}
            </h2>
            <div className="space-y-3">
              {catDocs.map((doc) => (
                <Card key={doc.id} className={!doc.is_active ? 'opacity-50' : ''}>
                  <CardContent className="py-4">
                    <div className="flex items-start justify-between">
                      <div className="flex-1 mr-4">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className="font-semibold">{doc.title}</h3>
                          <Badge variant={doc.is_active ? 'default' : 'destructive'} className="text-xs cursor-pointer"
                            onClick={() => toggleActive(doc)}>
                            {doc.is_active ? 'Active' : 'Inactive'}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground whitespace-pre-wrap">{doc.content}</p>
                      </div>
                      <div className="flex gap-1 shrink-0">
                        <Button variant="ghost" size="icon" onClick={() => openEdit(doc)}>
                          <Pencil className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon" onClick={() => deleteDoc(doc)}>
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        ))
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editing ? 'Edit Document' : 'Add Document'}</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Title</Label>
              <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder="e.g. Delivery Policy" />
            </div>
            <div>
              <Label>Category</Label>
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>{c.charAt(0).toUpperCase() + c.slice(1)}</option>
                ))}
              </select>
            </div>
            <div>
              <Label>Content</Label>
              <Textarea
                rows={8}
                value={content}
                onChange={(e) => setContent(e.target.value)}
                placeholder="Write the information the AI should know about this topic..."
              />
              <p className="text-xs text-muted-foreground mt-1">Be factual and concise. The AI will use this text to answer customer questions.</p>
            </div>
            <Button onClick={save} className="w-full">{editing ? 'Save Changes' : 'Add Document'}</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
