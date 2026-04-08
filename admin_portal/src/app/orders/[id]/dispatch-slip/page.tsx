import { createServerSupabase } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'

export default async function DispatchSlipPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const supabase = await createServerSupabase()
  const { data: order } = await supabase
    .from('orders')
    .select('*, profiles(full_name, email, phone), order_items(*, variants(size, unit_price, products(name)))')
    .eq('id', id)
    .single()

  if (!order) return notFound()

  const profile = (order as any).profiles
  const items = (order.order_items ?? []) as any[]

  const css = `
    * { margin: 0; padding: 0; box-sizing: border-box; }
    .slip-root { font-family: Arial, sans-serif; padding: 40px; color: #000; background: #fff; font-size: 14px; min-height: 100vh; }
    .slip-header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #000; padding-bottom: 16px; margin-bottom: 24px; }
    .slip-logo { font-size: 24px; font-weight: bold; }
    .slip-logo span { font-size: 12px; font-weight: normal; display: block; color: #666; }
    .slip-title { font-size: 20px; font-weight: bold; text-transform: uppercase; letter-spacing: 2px; }
    .slip-meta { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px; }
    .slip-meta-section h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #666; margin-bottom: 8px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
    .slip-meta-section p { margin-bottom: 4px; }
    .slip-meta-section p strong { display: inline-block; width: 100px; }
    .slip-table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
    .slip-table th { background: #f5f5f5; text-align: left; padding: 8px 12px; border: 1px solid #ddd; font-size: 12px; text-transform: uppercase; letter-spacing: 0.5px; }
    .slip-table td { padding: 8px 12px; border: 1px solid #ddd; }
    .slip-total-row td { font-weight: bold; font-size: 16px; background: #f9f9f9; }
    .slip-instructions { background: #f9f9f9; border: 1px solid #ddd; padding: 12px; margin-bottom: 24px; border-radius: 4px; }
    .slip-instructions h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #666; margin-bottom: 8px; }
    .slip-signoff { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 24px; margin-top: 40px; padding-top: 24px; border-top: 1px solid #ddd; }
    .slip-signoff div { border-bottom: 1px solid #000; padding-bottom: 30px; }
    .slip-signoff label { font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #666; }
    .slip-print-btn { position: fixed; top: 16px; right: 16px; background: #000; color: #fff; border: none; padding: 10px 24px; font-size: 14px; cursor: pointer; border-radius: 6px; z-index: 1000; }
    .slip-print-btn:hover { background: #333; }
    /* Escape root layout padding and sidebar gap */
    .slip-escape { margin: -32px -32px -32px -32px; }
    @media print {
      .slip-print-btn { display: none; }
      .slip-escape { margin: 0; }
      .slip-root { padding: 20px; }
    }
  `

  return (
    <div className="slip-escape">
      <style dangerouslySetInnerHTML={{ __html: css }} />
      <button className="slip-print-btn" onClick={undefined} id="slip-print-btn">
        Print / Save PDF
      </button>
      <script dangerouslySetInnerHTML={{ __html: `document.getElementById('slip-print-btn').onclick = function(){ window.print(); }` }} />

      <div className="slip-root">
        {/* Header */}
        <div className="slip-header">
          <div className="slip-logo">
            PartyPour
            <span>Beverage Service</span>
          </div>
          <div className="slip-title">Dispatch Slip</div>
        </div>

        {/* Order + Customer */}
        <div className="slip-meta">
          <div className="slip-meta-section">
            <h3>Order Information</h3>
            <p><strong>Order ID:</strong> #{order.id.substring(0, 8)}</p>
            <p><strong>Order Date:</strong> {new Date(order.created_at).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
            <p><strong>Status:</strong> {String(order.status).toUpperCase()}</p>
          </div>
          <div className="slip-meta-section">
            <h3>Customer</h3>
            <p><strong>Name:</strong> {profile?.full_name ?? 'N/A'}</p>
            <p><strong>Phone:</strong> {order.contact_phone ?? profile?.phone ?? 'N/A'}</p>
            <p><strong>Address:</strong> {order.delivery_address ?? 'N/A'}</p>
          </div>
        </div>

        {/* Event */}
        <div className="slip-meta" style={{ gridTemplateColumns: '1fr' }}>
          <div className="slip-meta-section">
            <h3>Event</h3>
            <p><strong>Type:</strong> {order.event_type ?? 'N/A'}</p>
            <p><strong>Date:</strong> {order.event_date ?? 'N/A'}</p>
            <p><strong>Guests:</strong> {order.guest_count ?? 'N/A'}</p>
          </div>
        </div>

        {/* Items table */}
        <table className="slip-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Product</th>
              <th>Size</th>
              <th>Qty</th>
              <th>Type</th>
              <th style={{ textAlign: 'right' }}>Total</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item: any, i: number) => (
              <tr key={item.id}>
                <td>{i + 1}</td>
                <td>{item.variants?.products?.name ?? 'N/A'}</td>
                <td>{item.variants?.size ?? 'N/A'}</td>
                <td>{item.quantity}</td>
                <td>{item.unit_type}</td>
                <td style={{ textAlign: 'right' }}>NPR {item.total_price.toLocaleString()}</td>
              </tr>
            ))}
            <tr className="slip-total-row">
              <td colSpan={5} style={{ textAlign: 'right' }}>TOTAL</td>
              <td style={{ textAlign: 'right' }}>NPR {order.final_amount.toLocaleString()}</td>
            </tr>
          </tbody>
        </table>

        {/* Special instructions */}
        {order.special_instructions && (
          <div className="slip-instructions">
            <h3>Special Instructions</h3>
            <p>{order.special_instructions}</p>
          </div>
        )}

        {/* Sign-off */}
        <div className="slip-signoff">
          <div><label>Prepared by</label></div>
          <div><label>Checked by</label></div>
          <div><label>Date</label></div>
        </div>
      </div>
    </div>
  )
}
