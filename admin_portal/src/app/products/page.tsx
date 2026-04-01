'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Product } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Plus, Pencil, Search } from 'lucide-react'

export default function ProductsPage() {
  const supabase = createClient()
  const [products, setProducts] = useState<Product[]>([])
  const [search, setSearch] = useState('')

  useEffect(() => {
    const fetch = async () => {
      let query = supabase.from('products').select('*, variants(*), subcategories!inner(name)').order('name')
      if (search) query = query.ilike('name', `%${search}%`)
      const { data } = await query
      setProducts(data ?? [])
    }
    fetch()
  }, [search])

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Products</h1>
        <Button asChild><Link href="/products/new"><Plus className="h-4 w-4 mr-2" /> Add Product</Link></Button>
      </div>
      <div className="mb-4 relative">
        <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
        <Input placeholder="Search products..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-10" />
      </div>
      <Table>
        <TableHeader><TableRow>
          <TableHead>Name</TableHead><TableHead>Category</TableHead><TableHead>Origin</TableHead><TableHead>Variants</TableHead><TableHead>Status</TableHead><TableHead></TableHead>
        </TableRow></TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="font-medium">{product.name}</TableCell>
              <TableCell>{(product as any).subcategories?.name}</TableCell>
              <TableCell><Badge variant={product.origin === 'local' ? 'default' : 'secondary'}>{product.origin}</Badge></TableCell>
              <TableCell>{product.variants?.length ?? 0}</TableCell>
              <TableCell><Badge variant={product.is_active ? 'default' : 'destructive'}>{product.is_active ? 'Active' : 'Inactive'}</Badge></TableCell>
              <TableCell><Button variant="ghost" size="icon" asChild><Link href={`/products/${product.id}`}><Pencil className="h-4 w-4" /></Link></Button></TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
