'use client'

import { useEffect, useState } from 'react'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Textarea } from '@/components/ui/textarea'
import { toast } from 'sonner'
import { Pencil } from 'lucide-react'

interface EstimationRule {
  id: string; subcategory_slug: string; label: string; icon_name: string | null
  drinks_per_guest: number; servings_per_bottle: number; event_multipliers: Record<string, number>
  children_factor: number; is_active: boolean; sort_order: number
}

export default function EstimationRulesPage() {
  const supabase = createClient()
  const [rules, setRules] = useState<EstimationRule[]>([])
  const [editDialog, setEditDialog] = useState(false)
  const [editing, setEditing] = useState<EstimationRule | null>(null)
  const [drinksPerGuest, setDrinksPerGuest] = useState('')
  const [servingsPerBottle, setServingsPerBottle] = useState('')
  const [childrenFactor, setChildrenFactor] = useState('')
  const [multipliers, setMultipliers] = useState('')

  const fetchRules = async () => {
    const { data } = await supabase.from('estimation_rules').select('*').order('sort_order')
    setRules(data ?? [])
  }

  useEffect(() => { fetchRules() }, [])

  const openEdit = (rule: EstimationRule) => {
    setEditing(rule)
    setDrinksPerGuest(rule.drinks_per_guest.toString())
    setServingsPerBottle(rule.servings_per_bottle.toString())
    setChildrenFactor(rule.children_factor.toString())
    setMultipliers(JSON.stringify(rule.event_multipliers, null, 2))
    setEditDialog(true)
  }

  const saveRule = async () => {
    if (!editing) return
    let parsedMultipliers
    try { parsedMultipliers = JSON.parse(multipliers) }
    catch { toast.error('Invalid JSON for event multipliers'); return }

    const { error } = await supabase.from('estimation_rules').update({
      drinks_per_guest: parseFloat(drinksPerGuest),
      servings_per_bottle: parseFloat(servingsPerBottle),
      children_factor: parseFloat(childrenFactor),
      event_multipliers: parsedMultipliers,
    }).eq('id', editing.id)

    if (error) { toast.error(error.message); return }
    toast.success(`${editing.label} updated`)
    setEditDialog(false)
    fetchRules()
  }

  const toggleActive = async (id: string, current: boolean) => {
    await supabase.from('estimation_rules').update({ is_active: !current }).eq('id', id)
    toast.success(`Rule ${current ? 'deactivated' : 'activated'}`)
    fetchRules()
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold">Estimation Rules</h1>
          <p className="text-muted-foreground mt-1">Configure beverage quantity formulas for the customer wizard</p>
        </div>
      </div>

      <Card className="mb-6">
        <CardHeader><CardTitle className="text-sm">Formula</CardTitle></CardHeader>
        <CardContent>
          <code className="text-xs bg-muted p-2 rounded block">
            effective_guests = (total_pax - children) + (children × children_factor)<br/>
            total_servings = effective_guests × drinks_per_guest × event_multiplier<br/>
            bottles_needed = ceil(total_servings / servings_per_bottle)
          </code>
        </CardContent>
      </Card>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Type</TableHead><TableHead>Drinks/Guest</TableHead><TableHead>Servings/Bottle</TableHead>
            <TableHead>Children Factor</TableHead><TableHead>Status</TableHead><TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {rules.map((rule) => (
            <TableRow key={rule.id}>
              <TableCell className="font-medium">{rule.label}</TableCell>
              <TableCell>{rule.drinks_per_guest}</TableCell>
              <TableCell>{rule.servings_per_bottle}</TableCell>
              <TableCell>{rule.children_factor}</TableCell>
              <TableCell>
                <Badge variant={rule.is_active ? 'default' : 'destructive'} className="cursor-pointer"
                  onClick={() => toggleActive(rule.id, rule.is_active)}>
                  {rule.is_active ? 'Active' : 'Inactive'}
                </Badge>
              </TableCell>
              <TableCell>
                <Button variant="ghost" size="icon" onClick={() => openEdit(rule)}><Pencil className="h-4 w-4" /></Button>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Dialog open={editDialog} onOpenChange={setEditDialog}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit: {editing?.label}</DialogTitle></DialogHeader>
          <div className="space-y-4">
            <div><Label>Drinks Per Guest</Label><Input type="number" step="0.1" value={drinksPerGuest} onChange={(e) => setDrinksPerGuest(e.target.value)} /></div>
            <div><Label>Servings Per Bottle</Label><Input type="number" step="0.1" value={servingsPerBottle} onChange={(e) => setServingsPerBottle(e.target.value)} /></div>
            <div><Label>Children Factor (0 = exclude children)</Label><Input type="number" step="0.1" value={childrenFactor} onChange={(e) => setChildrenFactor(e.target.value)} /></div>
            <div>
              <Label>Event Multipliers (JSON)</Label>
              <Textarea rows={6} value={multipliers} onChange={(e) => setMultipliers(e.target.value)} className="font-mono text-xs" />
            </div>
            <Button onClick={saveRule} className="w-full">Save</Button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
