<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { supabase } from '@/lib/supabase.js'
import { useFinance } from '@/composables/useFinance.js'
import { useToast } from '@/composables/useToast.js'

const toast = useToast()
const {
  loading, fetchAll, budgetData, spendingByCategory,
  monthIncome, monthExpenses, monthSavings,
  categories: allCategories,
} = useFinance()

onMounted(() => { fetchAll() })

// ── Envelope CRUD ──
const showModal = ref(false)
const editingId = ref(null)
const saving = ref(false)
const deletingId = ref(null)

const form = ref({
  category_id: '',
  amount: '',
  month: '',
})

// Set default month to current month
function getDefaultMonth() {
  const now = new Date()
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`
}

// Fallback categories when DB has none
const FALLBACK_CATEGORIES = [
  { id: 'fb-rent', name: 'Rent', icon: '🏠', color: '#202124', type: 'expense' },
  { id: 'fb-food', name: 'Food', icon: '🍔', color: '#D7F34A', type: 'expense' },
  { id: 'fb-fun', name: 'Fun', icon: '🎮', color: '#4285F4', type: 'expense' },
  { id: 'fb-savings', name: 'Savings', icon: '💰', color: '#2e7d32', type: 'expense' },
  { id: 'fb-utilities', name: 'Utilities', icon: '💡', color: '#f472b6', type: 'expense' },
  { id: 'fb-transport', name: 'Transport', icon: '🚗', color: '#9c27b0', type: 'expense' },
  { id: 'fb-shopping', name: 'Shopping', icon: '🛍️', color: '#fb923c', type: 'expense' },
  { id: 'fb-entertainment', name: 'Entertainment', icon: '🎬', color: '#a78bfa', type: 'expense' },
]

// Parent expense categories (not subcategories) + fallback
const availableCategories = computed(() => {
  const dbCategories = allCategories.value.filter(c => !c.parent_id && c.type === 'expense')
  if (dbCategories.length > 0) return dbCategories
  return FALLBACK_CATEGORIES
})

function openAddModal() {
  editingId.value = null
  form.value = { category_id: '', amount: '', month: getDefaultMonth() }
  showModal.value = true
}

function openEditModal(budget) {
  editingId.value = budget.id
  form.value = {
    category_id: budget.category_id,
    amount: budget.budget,
    month: budget.month || getDefaultMonth(),
  }
  showModal.value = true
}

async function saveEnvelope() {
  if (!form.value.category_id || !form.value.amount) {
    toast.error('Please select a category and enter an amount')
    return
  }

  saving.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    // Handle fallback category IDs — create in DB first
    let categoryId = form.value.category_id
    if (categoryId.startsWith('fb-')) {
      const fallback = FALLBACK_CATEGORIES.find(c => c.id === categoryId)
      if (fallback) {
        const { data: newCat, error: catErr } = await supabase
          .from('categories')
          .insert({
            user_id: user.id,
            name: fallback.name,
            icon: fallback.icon,
            color: fallback.color,
            type: 'expense',
          })
          .select('id')
          .single()
        if (catErr) throw catErr
        categoryId = newCat.id
      }
    }

    if (editingId.value) {
      // Update existing
      const { error } = await supabase.from('budgets').update({
        category_id: categoryId,
        amount: Number(form.value.amount),
        month: form.value.month,
      }).eq('id', editingId.value)
      if (error) throw error
      toast.success('Envelope updated')
    } else {
      // Check if budget already exists for this category+month
      const { data: existing } = await supabase
        .from('budgets')
        .select('id')
        .eq('user_id', user.id)
        .eq('category_id', categoryId)
        .eq('month', form.value.month)
        .maybeSingle()

      if (existing) {
        const { error } = await supabase.from('budgets').update({
          amount: Number(form.value.amount),
        }).eq('id', existing.id)
        if (error) throw error
        toast.success('Envelope updated')
      } else {
        const { error } = await supabase.from('budgets').insert({
          user_id: user.id,
          category_id: categoryId,
          amount: Number(form.value.amount),
          spent: 0,
          month: form.value.month,
        })
        if (error) throw error
        toast.success('Envelope created')
      }
    }

    showModal.value = false
    await fetchAll()
  } catch (e) {
    toast.error(e.message || 'Failed to save envelope')
  } finally {
    saving.value = false
  }
}

async function deleteEnvelope(id) {
  deletingId.value = id
}

async function confirmDelete() {
  try {
    const { error } = await supabase.from('budgets').delete().eq('id', deletingId.value)
    if (error) throw error
    toast.success('Envelope deleted')
    deletingId.value = null
    await fetchAll()
  } catch (e) {
    toast.error('Failed to delete envelope')
  }
}

// ── Display ──
const envelopes = computed(() => {
  return budgetData.value.map(b => {
    const subs = allCategories.value
      .filter(c => c.parent_id === b.category_id)
      .map(sub => {
        const spent = spendingByCategory.value
          .find(s => s.name === sub.name)?.spent || 0
        return { name: sub.name, icon: sub.icon, spent, total: 0 }
      })
    return {
      id: b.id,
      category_id: b.category_id,
      name: b.name,
      icon: b.icon,
      color: b.color,
      spent: b.spent,
      total: b.budget,
      month: b.month,
      subs,
    }
  })
})

const envelopesFromSpending = computed(() => {
  if (budgetData.value.length > 0) return []
  return spendingByCategory.value.map(cat => ({
    id: null,
    category_id: null,
    name: cat.name,
    icon: cat.icon,
    color: cat.color,
    spent: cat.spent,
    total: cat.spent,
    month: null,
    subs: [],
  }))
})

const displayEnvelopes = computed(() =>
  envelopes.value.length > 0 ? envelopes.value : envelopesFromSpending.value
)

const totalBudget = computed(() => displayEnvelopes.value.reduce((s, c) => s + c.total, 0))
const totalSpent = computed(() => displayEnvelopes.value.reduce((s, c) => s + c.spent, 0))
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Loading -->
      <div v-if="loading" class="loading-page">
        <span class="spinner-lg"></span>
        <p>Loading envelopes...</p>
      </div>

      <template v-else>
        <!-- Header with Add button -->
        <div class="page-header">
          <div>
            <h1 class="page-title">Envelopes</h1>
            <p class="page-desc">Set monthly budgets for each category. Track spending against your limits.</p>
          </div>
          <button class="add-btn" @click="openAddModal">+ Add Envelope</button>
        </div>

        <!-- Empty -->
        <div v-if="displayEnvelopes.length === 0" class="empty-state">
          <div class="empty-icon">✉️</div>
          <h3>No envelopes yet</h3>
          <p>Create your first envelope to start budgeting!</p>
          <button class="add-btn" @click="openAddModal">+ Create First Envelope</button>
        </div>

        <template v-else>
          <!-- Overview Bar -->
          <div class="overview-bar">
            <div class="bar-info">
              <span class="bar-label">Total Budget</span>
              <span class="bar-amt">₹{{ totalSpent.toLocaleString() }} / ₹{{ totalBudget.toLocaleString() }}</span>
            </div>
            <div class="bar-track">
              <div class="bar-fill" :style="{ width: Math.min((totalSpent / (totalBudget || 1)) * 100, 100) + '%' }"></div>
            </div>
            <span class="bar-pct">{{ totalBudget ? Math.round(totalSpent / totalBudget * 100) : 0 }}% used</span>
          </div>

          <!-- Envelope Grid -->
          <div class="envelope-grid">
            <div v-for="cat in displayEnvelopes" :key="cat.name" class="card">
              <div class="card-header">
                <div class="card-title-row">
                  <span class="card-icon">{{ cat.icon }}</span>
                  <h2 class="card-title">{{ cat.name }}</h2>
                </div>
                <div class="card-actions">
                  <span class="card-amt">₹{{ cat.spent.toLocaleString() }} / ₹{{ cat.total.toLocaleString() }}</span>
                  <button v-if="cat.id" class="edit-btn" @click="openEditModal(cat)" title="Edit">✏️</button>
                  <button v-if="cat.id" class="del-btn" @click="deleteEnvelope(cat.id)" title="Delete">🗑️</button>
                </div>
              </div>
              <div class="bar-track">
                <div class="bar-fill" :style="{ width: Math.min((cat.spent / (cat.total || 1)) * 100, 100) + '%', background: cat.color }"></div>
              </div>
              <div v-if="cat.subs.length > 0" class="sub-list">
                <div v-for="sub in cat.subs" :key="sub.name" class="sub-row">
                  <span class="sub-name">{{ sub.icon || '' }} {{ sub.name }}</span>
                  <div class="sub-right">
                    <div class="sub-bar-track">
                      <div class="sub-bar-fill" :style="{ width: Math.min((sub.spent / (sub.total || cat.total || 1)) * 100, 100) + '%', background: cat.color }"></div>
                    </div>
                    <span class="sub-amt">₹{{ sub.spent.toLocaleString() }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </template>

      <!-- Add/Edit Modal -->
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <button class="modal-close" @click="showModal = false">✕</button>
          <h3 class="modal-title">{{ editingId ? 'Edit Envelope' : 'New Envelope' }}</h3>
          <p class="modal-sub">Set a monthly budget for a spending category.</p>

          <div class="modal-form">
            <div class="field">
              <label class="label">Category</label>
              <select v-model="form.category_id" class="input select" :disabled="!!editingId">
                <option value="" disabled>Select a category</option>
                <option v-for="cat in availableCategories" :key="cat.id" :value="cat.id">
                  {{ cat.icon }} {{ cat.name }}
                </option>
              </select>
            </div>

            <div class="field">
              <label class="label">Monthly Budget (₹)</label>
              <input v-model="form.amount" type="number" placeholder="e.g. 12000" class="input" min="0" />
            </div>

            <div class="field">
              <label class="label">Month</label>
              <input v-model="form.month" type="month" class="input" />
            </div>

            <button class="save-btn" :disabled="saving || !form.category_id || !form.amount" @click="saveEnvelope">
              {{ saving ? 'Saving...' : editingId ? 'Update Envelope' : 'Create Envelope' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Delete Confirmation -->
      <div v-if="deletingId" class="modal-overlay" @click.self="deletingId = null">
        <div class="modal modal-sm">
          <h3 class="modal-title">Delete Envelope?</h3>
          <p class="modal-sub">This won't delete your transactions — only the budget limit.</p>
          <div class="modal-actions">
            <button class="cancel-btn" @click="deletingId = null">Cancel</button>
            <button class="delete-btn" @click="confirmDelete">Delete</button>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page { display: flex; flex-direction: column; gap: 1.5rem; }

.loading-page {
  display: flex; flex-direction: column; align-items: center;
  gap: 1rem; padding: 4rem 0; color: var(--color-text-muted); font-size: 0.875rem;
}

.spinner-lg {
  width: 32px; height: 32px; border: 3px solid var(--color-border);
  border-top-color: var(--color-graphite); border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.page-header {
  display: flex; align-items: flex-start; justify-content: space-between; gap: 1rem;
}

.page-title { font-size: 1.5rem; font-weight: 700; color: var(--color-text); }
.page-desc { font-size: 0.875rem; color: var(--color-text-muted); margin-top: 0.25rem; }

.add-btn {
  padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 600;
  font-family: var(--font-sans); color: var(--color-graphite);
  background: var(--color-accent); border: none; border-radius: var(--radius);
  cursor: pointer; white-space: nowrap; transition: background 0.2s;
}
.add-btn:hover { background: var(--color-accent-hover); }

.empty-state {
  text-align: center; padding: 4rem 1rem; color: var(--color-text-muted);
  display: flex; flex-direction: column; align-items: center; gap: 0.5rem;
}
.empty-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
.empty-state h3 { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.empty-state p { font-size: 0.8125rem; margin-bottom: 1rem; }

.overview-bar {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex; flex-direction: column; gap: 0.75rem;
}

.bar-info { display: flex; justify-content: space-between; align-items: center; }
.bar-label { font-size: 0.875rem; font-weight: 600; color: var(--color-text); }
.bar-amt { font-size: 0.8125rem; color: var(--color-text-muted); }
.bar-track { height: 8px; background: var(--color-bg); border-radius: 4px; overflow: hidden; }
.bar-fill { height: 100%; background: var(--color-accent); border-radius: 4px; transition: width 0.3s ease; }
.bar-pct { font-size: 0.75rem; color: var(--color-text-muted); text-align: right; }

.envelope-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }

.card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex; flex-direction: column; gap: 1rem;
}

.card-header { display: flex; align-items: center; justify-content: space-between; }
.card-title-row { display: flex; align-items: center; gap: 0.5rem; }
.card-icon { font-size: 1.25rem; }
.card-title { font-size: 1rem; font-weight: 600; color: var(--color-text); }

.card-actions { display: flex; align-items: center; gap: 0.5rem; }
.card-amt { font-size: 0.8125rem; color: var(--color-text-muted); }

.edit-btn, .del-btn {
  background: none; border: none; cursor: pointer; font-size: 0.875rem;
  opacity: 0.4; transition: opacity 0.15s; padding: 0.25rem;
}
.edit-btn:hover, .del-btn:hover { opacity: 1; }

.sub-list { display: flex; flex-direction: column; gap: 0.5rem; }
.sub-row { display: flex; align-items: center; justify-content: space-between; }
.sub-name { font-size: 0.8125rem; color: var(--color-text-muted); min-width: 110px; }
.sub-right { display: flex; align-items: center; gap: 0.75rem; flex: 1; max-width: 220px; }
.sub-bar-track { flex: 1; height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; }
.sub-bar-fill { height: 100%; border-radius: 2px; opacity: 0.6; }
.sub-amt { font-size: 0.6875rem; color: var(--color-text-muted); white-space: nowrap; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0, 0, 0, 0.4);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000; animation: fadeIn 0.15s ease;
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.modal {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 2rem; max-width: 440px; width: 94%; position: relative;
  animation: slideUp 0.2s ease;
}
.modal-sm { max-width: 360px; }
@keyframes slideUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }

.modal-close {
  position: absolute; top: 1.25rem; right: 1.25rem;
  width: 28px; height: 28px; border-radius: 50%; border: none;
  background: var(--color-bg); color: var(--color-text-muted);
  font-size: 0.75rem; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.modal-close:hover { background: rgba(211, 47, 47, 0.1); color: #d32f2f; }

.modal-title { font-size: 1.125rem; font-weight: 700; color: var(--color-text); margin-bottom: 0.25rem; }
.modal-sub { font-size: 0.8125rem; color: var(--color-text-muted); margin-bottom: 1.5rem; }

.modal-form { display: flex; flex-direction: column; gap: 1rem; }
.field { display: flex; flex-direction: column; gap: 0.375rem; }
.label { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }

.input {
  padding: 0.625rem 0.875rem; font-size: 0.875rem; font-family: var(--font-sans);
  color: var(--color-text); background: var(--color-bg);
  border: 1.5px solid var(--color-border); border-radius: var(--radius);
  outline: none; transition: border-color 0.2s;
}
.input:focus { border-color: var(--color-graphite); }
.input:disabled { opacity: 0.6; cursor: not-allowed; }
.select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%23666' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
  background-repeat: no-repeat; background-position: right 0.75rem center; padding-right: 2.25rem;
}

.save-btn {
  padding: 0.75rem; font-size: 0.9375rem; font-weight: 600;
  font-family: var(--font-sans); color: var(--color-graphite);
  background: var(--color-accent); border: none; border-radius: var(--radius);
  cursor: pointer; transition: background 0.2s, opacity 0.2s;
}
.save-btn:hover { background: var(--color-accent-hover); }
.save-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1rem; }

.cancel-btn {
  padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 500;
  font-family: var(--font-sans); color: var(--color-text-muted);
  background: none; border: 1.5px solid var(--color-border); border-radius: var(--radius);
  cursor: pointer;
}
.cancel-btn:hover { border-color: var(--color-graphite); color: var(--color-text); }

.delete-btn {
  padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 600;
  font-family: var(--font-sans); color: #fff; background: #d32f2f;
  border: none; border-radius: var(--radius); cursor: pointer;
}
.delete-btn:hover { background: #b71c1c; }
</style>
