export interface Category {
  id: string; name: string; slug: string; sort_order: number; image_url: string | null; created_at: string
}

export interface Subcategory {
  id: string; category_id: string; name: string; slug: string; sort_order: number; image_url: string | null; created_at: string
}

export interface Product {
  id: string; subcategory_id: string; name: string; origin: 'local' | 'imported'; description: string | null
  image_url: string | null; is_active: boolean; tags: string[]; created_at: string; updated_at: string
  variants?: Variant[]; subcategories?: Subcategory
}

export interface Variant {
  id: string; product_id: string; size: string; unit_price: number; case_size: number | null
  case_price: number | null; mrp: number | null; is_active: boolean; created_at: string; updated_at: string
}

export interface Discount {
  id: string; variant_id: string | null; type: 'percentage' | 'flat'; value: number
  valid_from: string; valid_until: string; is_active: boolean; created_at: string
}

export interface Order {
  id: string; user_id: string; event_type: string | null; event_date: string | null
  guest_count: number | null; delivery_address: string | null; contact_phone: string | null
  special_instructions: string | null; status: 'pending' | 'confirmed' | 'dispatched' | 'delivered' | 'cancelled'
  total_amount: number; discount_amount: number; final_amount: number
  created_at: string; updated_at: string; order_items?: OrderItem[]
  profiles?: { full_name: string; email: string; phone: string }
}

export interface OrderItem {
  id: string; order_id: string; variant_id: string; quantity: number
  unit_type: 'unit' | 'case'; unit_price: number; total_price: number
  variants?: Variant & { products?: Product }
}
