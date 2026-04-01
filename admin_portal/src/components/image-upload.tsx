'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Upload } from 'lucide-react'

interface ImageUploadProps { currentUrl?: string | null; onUpload: (url: string) => void }

export function ImageUpload({ currentUrl, onUpload }: ImageUploadProps) {
  const [uploading, setUploading] = useState(false)

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    const supabase = createClient()
    const fileName = `${Date.now()}-${file.name}`
    const { data, error } = await supabase.storage.from('product-images').upload(fileName, file)
    if (error) { alert(`Upload failed: ${error.message}`); setUploading(false); return }
    const { data: { publicUrl } } = supabase.storage.from('product-images').getPublicUrl(data.path)
    onUpload(publicUrl)
    setUploading(false)
  }

  return (
    <div className="space-y-2">
      {currentUrl && <img src={currentUrl} alt="Product" className="w-32 h-32 object-contain rounded border" />}
      <label className="inline-flex items-center gap-2 cursor-pointer rounded-lg border border-border bg-background px-2.5 py-1.5 text-sm hover:bg-muted">
        <Upload className="h-4 w-4" />{uploading ? 'Uploading...' : 'Upload Image'}
        <input type="file" accept="image/*" onChange={handleUpload} className="hidden" disabled={uploading} />
      </label>
    </div>
  )
}
