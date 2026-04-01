# RaksiChaiyo — Plan 3: Web Admin Portal

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the web-based admin portal for managing the RaksiChaiyo product catalog, pricing, discounts, orders, and equipment inventory. Connects to the same Supabase backend from Plan 1.

**Architecture:** Next.js 14 (App Router) with TypeScript, Tailwind CSS for styling, and Supabase JS client for data access. Server-side rendering for dashboard, client components for interactive CRUD forms.

**Tech Stack:** Next.js 14, TypeScript, Tailwind CSS, shadcn/ui components, Supabase JS SDK

**Depends on:** Plan 1 (Supabase backend) must be complete.

---

## File Structure

```
root_RaksiChaiyo/
├── admin_portal/
│   ├── package.json
│   ├── next.config.js
│   ├── tailwind.config.ts
│   ├── tsconfig.json
│   ├── .env.local                     # NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY
│   ├── src/
│   │   ├── lib/
│   │   │   ├── supabase/
│   │   │   │   ├── client.ts          # Browser Supabase client
│   │   │   │   └── server.ts          # Server Supabase client
│   │   │   └── types.ts              # Database types
│   │   ├── app/
│   │   │   ├── layout.tsx             # Root layout with sidebar nav
│   │   │   ├── page.tsx               # Redirect to /dashboard
│   │   │   ├── login/
│   │   │   │   └── page.tsx           # Admin login
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx           # Overview stats
│   │   │   ├── categories/
│   │   │   │   ├── page.tsx           # List categories + subcategories
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx       # Edit category
│   │   │   ├── products/
│   │   │   │   ├── page.tsx           # Product list with filters
│   │   │   │   ├── new/
│   │   │   │   │   └── page.tsx       # Create product
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx       # Edit product + variants
│   │   │   ├── discounts/
│   │   │   │   ├── page.tsx           # Discount list
│   │   │   │   └── new/
│   │   │   │       └── page.tsx       # Create discount
│   │   │   ├── orders/
│   │   │   │   ├── page.tsx           # Order list with status filter
│   │   │   │   └── [id]/
│   │   │   │       └── page.tsx       # Order detail + status update
│   │   │   └── equipment/
│   │   │       └── page.tsx           # Equipment inventory
│   │   └── components/
│   │       ├── sidebar.tsx            # Navigation sidebar
│   │       ├── data-table.tsx         # Reusable data table
│   │       ├── stat-card.tsx          # Dashboard stat card
│   │       └── image-upload.tsx       # Product image upload
```

---

### Task 1: Initialize Next.js Project

**Files:**
- Create: `admin_portal/` (Next.js scaffold)

- [ ] **Step 1: Create Next.js project**

```bash
cd root_RaksiChaiyo
npx create-next-app@latest admin_portal --typescript --tailwind --eslint --app --src-dir --use-npm
```

- [ ] **Step 2: Install additional dependencies**

```bash
cd admin_portal
npm install @supabase/supabase-js @supabase/ssr
npx shadcn@latest init -d
npx shadcn@latest add button card input label select table dialog badge dropdown-menu tabs textarea toast
```

- [ ] **Step 3: Create .env.local**

```
NEXT_PUBLIC_SUPABASE_URL=YOUR_SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

- [ ] **Step 4: Commit**

```bash
cd ..
git add admin_portal/
git commit -m "chore: initialize Next.js admin portal with shadcn/ui"
```

---

### Task 2: Supabase Clients + Types

**Files:**
- Create: `admin_portal/src/lib/supabase/client.ts`
- Create: `admin_portal/src/lib/supabase/server.ts`
- Create: `admin_portal/src/lib/types.ts`

- [ ] **Step 1: Create client.ts (browser client)**

```typescript
// src/lib/supabase/client.ts

import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

- [ ] **Step 2: Create server.ts (server client)**

```typescript
// src/lib/supabase/server.ts

import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createServerSupabase() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value, options }) => {
            cookieStore.set(name, value, options)
          })
        },
      },
    }
  )
}
```

- [ ] **Step 3: Create types.ts**

```typescript
// src/lib/types.ts

export interface Category {
  id: string
  name: string
  slug: string
  sort_order: number
  image_url: string | null
  created_at: string
}

export interface Subcategory {
  id: string
  category_id: string
  name: string
  slug: string
  sort_order: number
  image_url: string | null
  created_at: string
}

export interface Product {
  id: string
  subcategory_id: string
  name: string
  origin: 'local' | 'imported'
  description: string | null
  image_url: string | null
  is_active: boolean
  tags: string[]
  created_at: string
  updated_at: string
  variants?: Variant[]
  subcategory?: Subcategory
}

export interface Variant {
  id: string
  product_id: string
  size: string
  unit_price: number
  case_size: number | null
  case_price: number | null
  mrp: number | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface Discount {
  id: string
  variant_id: string | null
  type: 'percentage' | 'flat'
  value: number
  valid_from: string
  valid_until: string
  is_active: boolean
  created_at: string
}

export interface Order {
  id: string
  user_id: string
  event_type: string | null
  event_date: string | null
  guest_count: number | null
  delivery_address: string | null
  contact_phone: string | null
  special_instructions: string | null
  status: 'pending' | 'confirmed' | 'dispatched' | 'delivered' | 'cancelled'
  total_amount: number
  discount_amount: number
  final_amount: number
  created_at: string
  updated_at: string
  order_items?: OrderItem[]
  profiles?: { full_name: string; email: string; phone: string }
}

export interface OrderItem {
  id: string
  order_id: string
  variant_id: string
  quantity: number
  unit_type: 'unit' | 'case'
  unit_price: number
  total_price: number
  variant?: Variant & { product?: Product }
}
```

- [ ] **Step 4: Commit**

```bash
git add admin_portal/src/lib/
git commit -m "feat: add Supabase clients and TypeScript types"
```

---

### Task 3: Layout + Sidebar Navigation

**Files:**
- Create: `admin_portal/src/components/sidebar.tsx`
- Modify: `admin_portal/src/app/layout.tsx`
- Create: `admin_portal/src/app/page.tsx`

- [ ] **Step 1: Create sidebar.tsx**

```tsx
// src/components/sidebar.tsx

'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  FolderTree,
  Package,
  Percent,
  ShoppingCart,
  Wrench,
  LogOut,
} from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import { useRouter } from 'next/navigation'

const navItems = [
  { href: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { href: '/categories', label: 'Categories', icon: FolderTree },
  { href: '/products', label: 'Products', icon: Package },
  { href: '/discounts', label: 'Discounts', icon: Percent },
  { href: '/orders', label: 'Orders', icon: ShoppingCart },
  { href: '/equipment', label: 'Equipment', icon: Wrench },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()

  const handleSignOut = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
  }

  return (
    <aside className="w-64 border-r bg-card h-screen flex flex-col">
      <div className="p-6">
        <h1 className="text-xl font-bold text-primary">RaksiChaiyo</h1>
        <p className="text-xs text-muted-foreground">Admin Portal</p>
      </div>
      <nav className="flex-1 px-4 space-y-1">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              'flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors',
              pathname.startsWith(item.href)
                ? 'bg-primary text-primary-foreground'
                : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
            )}
          >
            <item.icon className="h-4 w-4" />
            {item.label}
          </Link>
        ))}
      </nav>
      <div className="p-4 border-t">
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 rounded-lg px-3 py-2 text-sm text-muted-foreground hover:bg-accent w-full"
        >
          <LogOut className="h-4 w-4" />
          Sign Out
        </button>
      </div>
    </aside>
  )
}
```

- [ ] **Step 2: Update layout.tsx**

```tsx
// src/app/layout.tsx

import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { Sidebar } from '@/components/sidebar'
import { Toaster } from '@/components/ui/toaster'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'RaksiChaiyo Admin',
  description: 'Admin portal for RaksiChaiyo beverage service',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <div className="flex h-screen">
          <Sidebar />
          <main className="flex-1 overflow-auto p-8">{children}</main>
        </div>
        <Toaster />
      </body>
    </html>
  )
}
```

- [ ] **Step 3: Create root page.tsx (redirect)**

```tsx
// src/app/page.tsx

import { redirect } from 'next/navigation'

export default function Home() {
  redirect('/dashboard')
}
```

- [ ] **Step 4: Commit**

```bash
git add admin_portal/src/components/sidebar.tsx admin_portal/src/app/layout.tsx admin_portal/src/app/page.tsx
git commit -m "feat: add admin layout with sidebar navigation"
```

---

### Task 4: Admin Login

**Files:**
- Create: `admin_portal/src/app/login/page.tsx`

- [ ] **Step 1: Create login page**

```tsx
// src/app/login/page.tsx

'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    const supabase = createClient()
    const { error: authError } = await supabase.auth.signInWithPassword({ email, password })

    if (authError) {
      setError(authError.message)
      setLoading(false)
      return
    }

    // Verify admin role
    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', (await supabase.auth.getUser()).data.user?.id ?? '')
      .single()

    if (profile?.role !== 'admin') {
      await supabase.auth.signOut()
      setError('Access denied. Admin privileges required.')
      setLoading(false)
      return
    }

    router.push('/dashboard')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">RaksiChaiyo Admin</CardTitle>
          <CardDescription>Sign in to manage your beverage catalog</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin_portal/src/app/login/
git commit -m "feat: add admin login with role verification"
```

---

### Task 5: Dashboard

**Files:**
- Create: `admin_portal/src/components/stat-card.tsx`
- Create: `admin_portal/src/app/dashboard/page.tsx`

- [ ] **Step 1: Create stat-card.tsx**

```tsx
// src/components/stat-card.tsx

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { type LucideIcon } from 'lucide-react'

interface StatCardProps {
  title: string
  value: string | number
  icon: LucideIcon
  description?: string
}

export function StatCard({ title, value, icon: Icon, description }: StatCardProps) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value}</div>
        {description && <p className="text-xs text-muted-foreground mt-1">{description}</p>}
      </CardContent>
    </Card>
  )
}
```

- [ ] **Step 2: Create dashboard page**

```tsx
// src/app/dashboard/page.tsx

import { createServerSupabase } from '@/lib/supabase/server'
import { StatCard } from '@/components/stat-card'
import { ShoppingCart, Package, DollarSign, Users } from 'lucide-react'

export default async function DashboardPage() {
  const supabase = await createServerSupabase()

  const [
    { count: orderCount },
    { count: productCount },
    { data: revenueData },
    { data: pendingOrders },
  ] = await Promise.all([
    supabase.from('orders').select('*', { count: 'exact', head: true }),
    supabase.from('products').select('*', { count: 'exact', head: true }),
    supabase.from('orders').select('final_amount').eq('status', 'delivered'),
    supabase.from('orders').select('id').eq('status', 'pending'),
  ])

  const totalRevenue = revenueData?.reduce((sum, o) => sum + (o.final_amount || 0), 0) ?? 0

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Total Orders"
          value={orderCount ?? 0}
          icon={ShoppingCart}
        />
        <StatCard
          title="Products"
          value={productCount ?? 0}
          icon={Package}
        />
        <StatCard
          title="Revenue"
          value={`NPR ${totalRevenue.toLocaleString()}`}
          icon={DollarSign}
          description="From delivered orders"
        />
        <StatCard
          title="Pending Orders"
          value={pendingOrders?.length ?? 0}
          icon={Users}
          description="Awaiting confirmation"
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add admin_portal/src/components/stat-card.tsx admin_portal/src/app/dashboard/
git commit -m "feat: add admin dashboard with stats"
```

---

### Task 6: Category Management

**Files:**
- Create: `admin_portal/src/app/categories/page.tsx`

- [ ] **Step 1: Create categories page**

```tsx
// src/app/categories/page.tsx

'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Category, Subcategory } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { useToast } from '@/hooks/use-toast'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default function CategoriesPage() {
  const supabase = createClient()
  const { toast } = useToast()
  const [categories, setCategories] = useState<(Category & { subcategories: Subcategory[] })[]>([])
  const [loading, setLoading] = useState(true)

  // Form state
  const [editingCategory, setEditingCategory] = useState<Category | null>(null)
  const [categoryName, setCategoryName] = useState('')
  const [dialogOpen, setDialogOpen] = useState(false)

  const [subDialogOpen, setSubDialogOpen] = useState(false)
  const [editingSub, setEditingSub] = useState<Subcategory | null>(null)
  const [subName, setSubName] = useState('')
  const [subCategoryId, setSubCategoryId] = useState('')

  const fetchCategories = async () => {
    const { data } = await supabase
      .from('categories')
      .select('*, subcategories(*)')
      .order('sort_order')
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
    toast({ title: editingCategory ? 'Category updated' : 'Category created' })
    setDialogOpen(false)
    setCategoryName('')
    setEditingCategory(null)
    fetchCategories()
  }

  const deleteCategory = async (id: string) => {
    if (!confirm('Delete this category and all its subcategories?')) return
    await supabase.from('categories').delete().eq('id', id)
    toast({ title: 'Category deleted' })
    fetchCategories()
  }

  const saveSubcategory = async () => {
    const slug = subName.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    if (editingSub) {
      await supabase.from('subcategories').update({ name: subName, slug }).eq('id', editingSub.id)
    } else {
      const parent = categories.find(c => c.id === subCategoryId)
      const maxOrder = Math.max(0, ...(parent?.subcategories.map(s => s.sort_order) ?? [0]))
      await supabase.from('subcategories').insert({
        name: subName, slug, category_id: subCategoryId, sort_order: maxOrder + 1,
      })
    }
    toast({ title: editingSub ? 'Subcategory updated' : 'Subcategory created' })
    setSubDialogOpen(false)
    setSubName('')
    setEditingSub(null)
    fetchCategories()
  }

  const deleteSubcategory = async (id: string) => {
    if (!confirm('Delete this subcategory and all its products?')) return
    await supabase.from('subcategories').delete().eq('id', id)
    toast({ title: 'Subcategory deleted' })
    fetchCategories()
  }

  if (loading) return <p>Loading...</p>

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Categories</h1>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={() => { setEditingCategory(null); setCategoryName('') }}>
              <Plus className="h-4 w-4 mr-2" /> Add Category
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editingCategory ? 'Edit' : 'New'} Category</DialogTitle>
            </DialogHeader>
            <div className="space-y-4">
              <div>
                <Label>Name</Label>
                <Input value={categoryName} onChange={(e) => setCategoryName(e.target.value)} />
              </div>
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
                <Button variant="ghost" size="icon" onClick={() => {
                  setEditingCategory(cat); setCategoryName(cat.name); setDialogOpen(true)
                }}>
                  <Pencil className="h-4 w-4" />
                </Button>
                <Button variant="ghost" size="icon" onClick={() => deleteCategory(cat.id)}>
                  <Trash2 className="h-4 w-4 text-destructive" />
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {cat.subcategories?.map((sub) => (
                  <div key={sub.id} className="flex items-center justify-between p-2 rounded bg-muted">
                    <span>{sub.name}</span>
                    <div className="flex gap-1">
                      <Button variant="ghost" size="sm" onClick={() => {
                        setEditingSub(sub); setSubName(sub.name); setSubCategoryId(cat.id); setSubDialogOpen(true)
                      }}>
                        <Pencil className="h-3 w-3" />
                      </Button>
                      <Button variant="ghost" size="sm" onClick={() => deleteSubcategory(sub.id)}>
                        <Trash2 className="h-3 w-3 text-destructive" />
                      </Button>
                    </div>
                  </div>
                ))}
                <Button variant="outline" size="sm" onClick={() => {
                  setEditingSub(null); setSubName(''); setSubCategoryId(cat.id); setSubDialogOpen(true)
                }}>
                  <Plus className="h-3 w-3 mr-1" /> Add Subcategory
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Dialog open={subDialogOpen} onOpenChange={setSubDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingSub ? 'Edit' : 'New'} Subcategory</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Name</Label>
              <Input value={subName} onChange={(e) => setSubName(e.target.value)} />
            </div>
            <Button onClick={saveSubcategory} className="w-full">Save</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin_portal/src/app/categories/
git commit -m "feat: add category and subcategory CRUD management"
```

---

### Task 7: Product Management (List + Create/Edit)

**Files:**
- Create: `admin_portal/src/app/products/page.tsx`
- Create: `admin_portal/src/app/products/new/page.tsx`
- Create: `admin_portal/src/app/products/[id]/page.tsx`
- Create: `admin_portal/src/components/image-upload.tsx`

- [ ] **Step 1: Create image-upload.tsx**

```tsx
// src/components/image-upload.tsx

'use client'

import { useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Upload } from 'lucide-react'

interface ImageUploadProps {
  currentUrl?: string | null
  onUpload: (url: string) => void
}

export function ImageUpload({ currentUrl, onUpload }: ImageUploadProps) {
  const [uploading, setUploading] = useState(false)

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    setUploading(true)
    const supabase = createClient()
    const fileName = `${Date.now()}-${file.name}`
    const { data, error } = await supabase.storage
      .from('product-images')
      .upload(fileName, file)

    if (error) {
      alert(`Upload failed: ${error.message}`)
      setUploading(false)
      return
    }

    const { data: { publicUrl } } = supabase.storage
      .from('product-images')
      .getPublicUrl(data.path)

    onUpload(publicUrl)
    setUploading(false)
  }

  return (
    <div className="space-y-2">
      {currentUrl && (
        <img src={currentUrl} alt="Product" className="w-32 h-32 object-contain rounded border" />
      )}
      <Button variant="outline" size="sm" disabled={uploading} asChild>
        <label className="cursor-pointer">
          <Upload className="h-4 w-4 mr-2" />
          {uploading ? 'Uploading...' : 'Upload Image'}
          <input type="file" accept="image/*" onChange={handleUpload} className="hidden" />
        </label>
      </Button>
    </div>
  )
}
```

- [ ] **Step 2: Create products list page**

```tsx
// src/app/products/page.tsx

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
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      let query = supabase
        .from('products')
        .select('*, variants(*), subcategories!inner(name)')
        .order('name')

      if (search) query = query.ilike('name', `%${search}%`)

      const { data } = await query
      setProducts(data ?? [])
      setLoading(false)
    }
    fetch()
  }, [search])

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Products</h1>
        <Button asChild>
          <Link href="/products/new"><Plus className="h-4 w-4 mr-2" /> Add Product</Link>
        </Button>
      </div>

      <div className="mb-4 relative">
        <Search className="absolute left-3 top-3 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search products..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="pl-10"
        />
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Category</TableHead>
            <TableHead>Origin</TableHead>
            <TableHead>Variants</TableHead>
            <TableHead>Status</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {products.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="font-medium">{product.name}</TableCell>
              <TableCell>{(product as any).subcategories?.name}</TableCell>
              <TableCell>
                <Badge variant={product.origin === 'local' ? 'default' : 'secondary'}>
                  {product.origin}
                </Badge>
              </TableCell>
              <TableCell>{product.variants?.length ?? 0}</TableCell>
              <TableCell>
                <Badge variant={product.is_active ? 'default' : 'destructive'}>
                  {product.is_active ? 'Active' : 'Inactive'}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="icon" asChild>
                  <Link href={`/products/${product.id}`}><Pencil className="h-4 w-4" /></Link>
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
```

- [ ] **Step 3: Create new product page**

```tsx
// src/app/products/new/page.tsx

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
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ImageUpload } from '@/components/image-upload'
import { useToast } from '@/hooks/use-toast'

export default function NewProductPage() {
  const supabase = createClient()
  const router = useRouter()
  const { toast } = useToast()
  const [subcategories, setSubcategories] = useState<Subcategory[]>([])
  const [name, setName] = useState('')
  const [subcategoryId, setSubcategoryId] = useState('')
  const [origin, setOrigin] = useState<'local' | 'imported'>('local')
  const [description, setDescription] = useState('')
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    supabase.from('subcategories').select('*').order('name').then(({ data }) => {
      setSubcategories(data ?? [])
    })
  }, [])

  const handleSave = async () => {
    setSaving(true)
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-')
    const { data, error } = await supabase.from('products').insert({
      name, subcategory_id: subcategoryId, origin, description: description || null, image_url: imageUrl,
    }).select().single()

    if (error) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
      setSaving(false)
      return
    }

    toast({ title: 'Product created' })
    router.push(`/products/${data.id}`)
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-3xl font-bold mb-8">New Product</h1>
      <Card>
        <CardContent className="pt-6 space-y-4">
          <div>
            <Label>Product Name</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div>
            <Label>Subcategory</Label>
            <Select value={subcategoryId} onValueChange={setSubcategoryId}>
              <SelectTrigger><SelectValue placeholder="Select subcategory" /></SelectTrigger>
              <SelectContent>
                {subcategories.map(s => (
                  <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label>Origin</Label>
            <Select value={origin} onValueChange={(v) => setOrigin(v as 'local' | 'imported')}>
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="local">Local</SelectItem>
                <SelectItem value="imported">Imported</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div>
            <Label>Description</Label>
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div>
            <Label>Image</Label>
            <ImageUpload currentUrl={imageUrl} onUpload={setImageUrl} />
          </div>
          <Button onClick={handleSave} disabled={saving || !name || !subcategoryId} className="w-full">
            {saving ? 'Saving...' : 'Create Product'}
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 4: Create edit product page (with variant management)**

```tsx
// src/app/products/[id]/page.tsx

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
import { useToast } from '@/hooks/use-toast'
import { Plus, Pencil, Trash2 } from 'lucide-react'

export default function EditProductPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const { toast } = useToast()

  const [product, setProduct] = useState<Product | null>(null)
  const [subcategories, setSubcategories] = useState<Subcategory[]>([])
  const [name, setName] = useState('')
  const [subcategoryId, setSubcategoryId] = useState('')
  const [origin, setOrigin] = useState<'local' | 'imported'>('local')
  const [description, setDescription] = useState('')
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [isActive, setIsActive] = useState(true)

  // Variant form
  const [variantDialog, setVariantDialog] = useState(false)
  const [editingVariant, setEditingVariant] = useState<Variant | null>(null)
  const [vSize, setVSize] = useState('')
  const [vUnitPrice, setVUnitPrice] = useState('')
  const [vCaseSize, setVCaseSize] = useState('')
  const [vCasePrice, setVCasePrice] = useState('')
  const [vMrp, setVMrp] = useState('')

  const fetchProduct = async () => {
    const { data } = await supabase
      .from('products')
      .select('*, variants(*)')
      .eq('id', id)
      .single()
    if (data) {
      setProduct(data)
      setName(data.name)
      setSubcategoryId(data.subcategory_id)
      setOrigin(data.origin)
      setDescription(data.description ?? '')
      setImageUrl(data.image_url)
      setIsActive(data.is_active)
    }
  }

  useEffect(() => {
    fetchProduct()
    supabase.from('subcategories').select('*').order('name').then(({ data }) => {
      setSubcategories(data ?? [])
    })
  }, [])

  const saveProduct = async () => {
    await supabase.from('products').update({
      name, subcategory_id: subcategoryId, origin,
      description: description || null, image_url: imageUrl, is_active: isActive,
    }).eq('id', id)
    toast({ title: 'Product updated' })
    fetchProduct()
  }

  const openVariantForm = (variant?: Variant) => {
    setEditingVariant(variant ?? null)
    setVSize(variant?.size ?? '')
    setVUnitPrice(variant?.unit_price?.toString() ?? '')
    setVCaseSize(variant?.case_size?.toString() ?? '')
    setVCasePrice(variant?.case_price?.toString() ?? '')
    setVMrp(variant?.mrp?.toString() ?? '')
    setVariantDialog(true)
  }

  const saveVariant = async () => {
    const data = {
      product_id: id,
      size: vSize,
      unit_price: parseFloat(vUnitPrice),
      case_size: vCaseSize ? parseInt(vCaseSize) : null,
      case_price: vCasePrice ? parseFloat(vCasePrice) : null,
      mrp: vMrp ? parseFloat(vMrp) : null,
    }
    if (editingVariant) {
      await supabase.from('variants').update(data).eq('id', editingVariant.id)
    } else {
      await supabase.from('variants').insert(data)
    }
    toast({ title: editingVariant ? 'Variant updated' : 'Variant added' })
    setVariantDialog(false)
    fetchProduct()
  }

  const deleteVariant = async (variantId: string) => {
    if (!confirm('Delete this variant?')) return
    await supabase.from('variants').delete().eq('id', variantId)
    toast({ title: 'Variant deleted' })
    fetchProduct()
  }

  if (!product) return <p>Loading...</p>

  return (
    <div className="max-w-4xl space-y-8">
      <h1 className="text-3xl font-bold">Edit Product</h1>

      <Card>
        <CardHeader><CardTitle>Product Details</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Name</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Subcategory</Label>
              <Select value={subcategoryId} onValueChange={setSubcategoryId}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {subcategories.map(s => (
                    <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Origin</Label>
              <Select value={origin} onValueChange={(v) => setOrigin(v as 'local' | 'imported')}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="local">Local</SelectItem>
                  <SelectItem value="imported">Imported</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
          <div>
            <Label>Description</Label>
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)} />
          </div>
          <div>
            <Label>Image</Label>
            <ImageUpload currentUrl={imageUrl} onUpload={setImageUrl} />
          </div>
          <div className="flex items-center gap-2">
            <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} />
            <Label>Active</Label>
          </div>
          <Button onClick={saveProduct} className="w-full">Save Product</Button>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Variants & Pricing</CardTitle>
          <Button size="sm" onClick={() => openVariantForm()}>
            <Plus className="h-4 w-4 mr-2" /> Add Variant
          </Button>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Size</TableHead>
                <TableHead>Unit Price</TableHead>
                <TableHead>Case Size</TableHead>
                <TableHead>Case Price</TableHead>
                <TableHead>MRP</TableHead>
                <TableHead></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {product.variants?.map((v) => (
                <TableRow key={v.id}>
                  <TableCell>{v.size}</TableCell>
                  <TableCell>NPR {v.unit_price}</TableCell>
                  <TableCell>{v.case_size ?? '-'}</TableCell>
                  <TableCell>{v.case_price ? `NPR ${v.case_price}` : '-'}</TableCell>
                  <TableCell>{v.mrp ? `NPR ${v.mrp}` : '-'}</TableCell>
                  <TableCell className="flex gap-1">
                    <Button variant="ghost" size="icon" onClick={() => openVariantForm(v)}>
                      <Pencil className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => deleteVariant(v.id)}>
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Dialog open={variantDialog} onOpenChange={setVariantDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editingVariant ? 'Edit' : 'Add'} Variant</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Size (e.g., 750ml, 20L Keg)</Label>
              <Input value={vSize} onChange={(e) => setVSize(e.target.value)} />
            </div>
            <div>
              <Label>Unit Price (NPR)</Label>
              <Input type="number" value={vUnitPrice} onChange={(e) => setVUnitPrice(e.target.value)} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label>Case Size (optional)</Label>
                <Input type="number" value={vCaseSize} onChange={(e) => setVCaseSize(e.target.value)} />
              </div>
              <div>
                <Label>Case Price (optional)</Label>
                <Input type="number" value={vCasePrice} onChange={(e) => setVCasePrice(e.target.value)} />
              </div>
            </div>
            <div>
              <Label>MRP (optional)</Label>
              <Input type="number" value={vMrp} onChange={(e) => setVMrp(e.target.value)} />
            </div>
            <Button onClick={saveVariant} className="w-full" disabled={!vSize || !vUnitPrice}>Save Variant</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
```

- [ ] **Step 5: Commit**

```bash
git add admin_portal/src/app/products/ admin_portal/src/components/image-upload.tsx
git commit -m "feat: add product CRUD with variant and pricing management"
```

---

### Task 8: Discount Management

**Files:**
- Create: `admin_portal/src/app/discounts/page.tsx`
- Create: `admin_portal/src/app/discounts/new/page.tsx`

- [ ] **Step 1: Create discounts list page**

```tsx
// src/app/discounts/page.tsx

'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Discount } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useToast } from '@/hooks/use-toast'
import { Plus, Trash2 } from 'lucide-react'

export default function DiscountsPage() {
  const supabase = createClient()
  const { toast } = useToast()
  const [discounts, setDiscounts] = useState<(Discount & { variants?: { size: string; products?: { name: string } } })[]>([])

  const fetchDiscounts = async () => {
    const { data } = await supabase
      .from('discounts')
      .select('*, variants(size, products(name))')
      .order('created_at', { ascending: false })
    setDiscounts(data ?? [])
  }

  useEffect(() => { fetchDiscounts() }, [])

  const deleteDiscount = async (id: string) => {
    if (!confirm('Delete this discount?')) return
    await supabase.from('discounts').delete().eq('id', id)
    toast({ title: 'Discount deleted' })
    fetchDiscounts()
  }

  const isExpired = (d: Discount) => new Date(d.valid_until) < new Date()

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Discounts</h1>
        <Button asChild>
          <Link href="/discounts/new"><Plus className="h-4 w-4 mr-2" /> New Discount</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Product</TableHead>
            <TableHead>Variant</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Value</TableHead>
            <TableHead>Valid Until</TableHead>
            <TableHead>Status</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {discounts.map((d) => (
            <TableRow key={d.id}>
              <TableCell>{(d.variants as any)?.products?.name ?? 'Event-wide'}</TableCell>
              <TableCell>{(d.variants as any)?.size ?? '-'}</TableCell>
              <TableCell>{d.type}</TableCell>
              <TableCell>{d.type === 'percentage' ? `${d.value}%` : `NPR ${d.value}`}</TableCell>
              <TableCell>{new Date(d.valid_until).toLocaleDateString()}</TableCell>
              <TableCell>
                <Badge variant={isExpired(d) ? 'destructive' : d.is_active ? 'default' : 'secondary'}>
                  {isExpired(d) ? 'Expired' : d.is_active ? 'Active' : 'Inactive'}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="icon" onClick={() => deleteDiscount(d.id)}>
                  <Trash2 className="h-4 w-4 text-destructive" />
                </Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
```

- [ ] **Step 2: Create new discount page**

```tsx
// src/app/discounts/new/page.tsx

'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Variant } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Card, CardContent } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'

export default function NewDiscountPage() {
  const supabase = createClient()
  const router = useRouter()
  const { toast } = useToast()

  const [variants, setVariants] = useState<(Variant & { products: { name: string } })[]>([])
  const [variantId, setVariantId] = useState<string>('')
  const [type, setType] = useState<'percentage' | 'flat'>('percentage')
  const [value, setValue] = useState('')
  const [validFrom, setValidFrom] = useState('')
  const [validUntil, setValidUntil] = useState('')

  useEffect(() => {
    supabase
      .from('variants')
      .select('*, products(name)')
      .eq('is_active', true)
      .order('size')
      .then(({ data }) => setVariants(data ?? []))
  }, [])

  const handleSave = async () => {
    const { error } = await supabase.from('discounts').insert({
      variant_id: variantId || null,
      type,
      value: parseFloat(value),
      valid_from: new Date(validFrom).toISOString(),
      valid_until: new Date(validUntil).toISOString(),
    })

    if (error) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' })
      return
    }

    toast({ title: 'Discount created' })
    router.push('/discounts')
  }

  return (
    <div className="max-w-2xl">
      <h1 className="text-3xl font-bold mb-8">New Discount</h1>
      <Card>
        <CardContent className="pt-6 space-y-4">
          <div>
            <Label>Product Variant (leave empty for event-wide)</Label>
            <Select value={variantId} onValueChange={setVariantId}>
              <SelectTrigger><SelectValue placeholder="Select variant (optional)" /></SelectTrigger>
              <SelectContent>
                {variants.map(v => (
                  <SelectItem key={v.id} value={v.id}>
                    {(v as any).products.name} — {v.size}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Type</Label>
              <Select value={type} onValueChange={(v) => setType(v as 'percentage' | 'flat')}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="percentage">Percentage (%)</SelectItem>
                  <SelectItem value="flat">Flat (NPR)</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Value</Label>
              <Input type="number" value={value} onChange={(e) => setValue(e.target.value)} />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Valid From</Label>
              <Input type="date" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />
            </div>
            <div>
              <Label>Valid Until</Label>
              <Input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} />
            </div>
          </div>
          <Button onClick={handleSave} className="w-full" disabled={!value || !validFrom || !validUntil}>
            Create Discount
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add admin_portal/src/app/discounts/
git commit -m "feat: add discount list and creation pages"
```

---

### Task 9: Order Management

**Files:**
- Create: `admin_portal/src/app/orders/page.tsx`
- Create: `admin_portal/src/app/orders/[id]/page.tsx`

- [ ] **Step 1: Create orders list page**

```tsx
// src/app/orders/page.tsx

'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Badge } from '@/components/ui/badge'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'

const statusColors: Record<string, 'default' | 'secondary' | 'destructive' | 'outline'> = {
  pending: 'outline',
  confirmed: 'secondary',
  dispatched: 'default',
  delivered: 'default',
  cancelled: 'destructive',
}

export default function OrdersPage() {
  const supabase = createClient()
  const [orders, setOrders] = useState<Order[]>([])
  const [statusFilter, setStatusFilter] = useState<string>('all')

  useEffect(() => {
    const fetch = async () => {
      let query = supabase
        .from('orders')
        .select('*, profiles(full_name, email)')
        .order('created_at', { ascending: false })

      if (statusFilter !== 'all') query = query.eq('status', statusFilter)

      const { data } = await query
      setOrders(data ?? [])
    }
    fetch()
  }, [statusFilter])

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-3xl font-bold">Orders</h1>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-48"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="confirmed">Confirmed</SelectItem>
            <SelectItem value="dispatched">Dispatched</SelectItem>
            <SelectItem value="delivered">Delivered</SelectItem>
            <SelectItem value="cancelled">Cancelled</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Order ID</TableHead>
            <TableHead>Customer</TableHead>
            <TableHead>Event</TableHead>
            <TableHead>Amount</TableHead>
            <TableHead>Status</TableHead>
            <TableHead>Date</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {orders.map((order) => (
            <TableRow key={order.id} className="cursor-pointer">
              <TableCell>
                <Link href={`/orders/${order.id}`} className="text-primary hover:underline">
                  #{order.id.substring(0, 8)}
                </Link>
              </TableCell>
              <TableCell>{(order as any).profiles?.full_name ?? 'Unknown'}</TableCell>
              <TableCell>{order.event_type ?? '-'}</TableCell>
              <TableCell>NPR {order.final_amount.toLocaleString()}</TableCell>
              <TableCell>
                <Badge variant={statusColors[order.status] ?? 'default'}>
                  {order.status}
                </Badge>
              </TableCell>
              <TableCell>{new Date(order.created_at).toLocaleDateString()}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}
```

- [ ] **Step 2: Create order detail page with status update**

```tsx
// src/app/orders/[id]/page.tsx

'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Order } from '@/lib/types'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { useToast } from '@/hooks/use-toast'

const statusFlow = ['pending', 'confirmed', 'dispatched', 'delivered', 'cancelled'] as const

export default function OrderDetailPage() {
  const { id } = useParams<{ id: string }>()
  const supabase = createClient()
  const { toast } = useToast()
  const [order, setOrder] = useState<Order | null>(null)
  const [newStatus, setNewStatus] = useState('')

  const fetchOrder = async () => {
    const { data } = await supabase
      .from('orders')
      .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
      .eq('id', id)
      .single()
    if (data) {
      setOrder(data)
      setNewStatus(data.status)
    }
  }

  useEffect(() => { fetchOrder() }, [])

  const updateStatus = async () => {
    await supabase.from('orders').update({ status: newStatus }).eq('id', id)
    toast({ title: `Order status updated to ${newStatus}` })
    fetchOrder()
  }

  if (!order) return <p>Loading...</p>

  const profile = (order as any).profiles

  return (
    <div className="max-w-4xl space-y-6">
      <h1 className="text-3xl font-bold">Order #{order.id.substring(0, 8)}</h1>

      <div className="grid grid-cols-2 gap-6">
        <Card>
          <CardHeader><CardTitle>Customer</CardTitle></CardHeader>
          <CardContent className="space-y-1 text-sm">
            <p><strong>Name:</strong> {profile?.full_name ?? 'N/A'}</p>
            <p><strong>Email:</strong> {profile?.email ?? 'N/A'}</p>
            <p><strong>Phone:</strong> {order.contact_phone ?? profile?.phone ?? 'N/A'}</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader><CardTitle>Event Details</CardTitle></CardHeader>
          <CardContent className="space-y-1 text-sm">
            <p><strong>Type:</strong> {order.event_type ?? 'N/A'}</p>
            <p><strong>Date:</strong> {order.event_date ?? 'N/A'}</p>
            <p><strong>Guests:</strong> {order.guest_count ?? 'N/A'}</p>
            <p><strong>Address:</strong> {order.delivery_address ?? 'N/A'}</p>
            {order.special_instructions && (
              <p><strong>Notes:</strong> {order.special_instructions}</p>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>Status</CardTitle>
          <div className="flex items-center gap-2">
            <Select value={newStatus} onValueChange={setNewStatus}>
              <SelectTrigger className="w-40"><SelectValue /></SelectTrigger>
              <SelectContent>
                {statusFlow.map(s => (
                  <SelectItem key={s} value={s}>{s}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button onClick={updateStatus} disabled={newStatus === order.status} size="sm">
              Update
            </Button>
          </div>
        </CardHeader>
      </Card>

      <Card>
        <CardHeader><CardTitle>Items</CardTitle></CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Product</TableHead>
                <TableHead>Size</TableHead>
                <TableHead>Qty</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Unit Price</TableHead>
                <TableHead>Total</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {order.order_items?.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{(item as any).variants?.products?.name ?? 'N/A'}</TableCell>
                  <TableCell>{(item as any).variants?.size ?? 'N/A'}</TableCell>
                  <TableCell>{item.quantity}</TableCell>
                  <TableCell>{item.unit_type}</TableCell>
                  <TableCell>NPR {item.unit_price}</TableCell>
                  <TableCell>NPR {item.total_price}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
          <div className="mt-4 text-right space-y-1">
            <p>Subtotal: NPR {order.total_amount.toLocaleString()}</p>
            <p>Discount: - NPR {order.discount_amount.toLocaleString()}</p>
            <p className="text-lg font-bold">Total: NPR {order.final_amount.toLocaleString()}</p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
git add admin_portal/src/app/orders/
git commit -m "feat: add order list and detail pages with status management"
```

---

### Task 10: Equipment Inventory Page

**Files:**
- Create: `admin_portal/src/app/equipment/page.tsx`

- [ ] **Step 1: Create equipment page**

```tsx
// src/app/equipment/page.tsx

'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Product } from '@/lib/types'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'

export default function EquipmentPage() {
  const supabase = createClient()
  const { toast } = useToast()
  const [equipment, setEquipment] = useState<Product[]>([])

  const fetchEquipment = async () => {
    // Get equipment category, then its products
    const { data: subcat } = await supabase
      .from('subcategories')
      .select('id')
      .eq('slug', 'draught-beer-setup')
      .single()

    if (!subcat) return

    const { data } = await supabase
      .from('products')
      .select('*, variants(*)')
      .eq('subcategory_id', subcat.id)
      .order('name')

    setEquipment(data ?? [])
  }

  useEffect(() => { fetchEquipment() }, [])

  const toggleActive = async (productId: string, currentStatus: boolean) => {
    await supabase.from('products').update({ is_active: !currentStatus }).eq('id', productId)
    toast({ title: `Equipment ${currentStatus ? 'deactivated' : 'activated'}` })
    fetchEquipment()
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Equipment Inventory</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {equipment.map((item) => (
          <Card key={item.id}>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg">{item.name}</CardTitle>
                <Badge variant={item.is_active ? 'default' : 'destructive'}>
                  {item.is_active ? 'Available' : 'Unavailable'}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              {item.variants?.map(v => (
                <p key={v.id} className="text-sm">
                  {v.size}: <strong>NPR {v.unit_price}</strong>
                  {v.mrp && <span className="text-muted-foreground ml-2">(MRP: NPR {v.mrp})</span>}
                </p>
              ))}
              <Button
                variant="outline"
                size="sm"
                className="mt-4"
                onClick={() => toggleActive(item.id, item.is_active)}
              >
                Mark as {item.is_active ? 'Unavailable' : 'Available'}
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
git add admin_portal/src/app/equipment/
git commit -m "feat: add equipment inventory page"
```

- [ ] **Step 3: Final tag**

```bash
git tag v0.3.0-admin-portal
```
