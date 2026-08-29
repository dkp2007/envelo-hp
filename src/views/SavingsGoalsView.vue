<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { supabase } from '@/lib/supabase.js'
import { useFinance } from '@/composables/useFinance.js'
import { useToast } from '@/composables/useToast.js'

const toast = useToast()
const { loading, fetchAll, savingsGoals } = useFinance()

onMounted(() => { fetchAll() })

// ── Goal CRUD ──
const showModal = ref(false)
const editingId = ref(null)
const saving = ref(false)
const deletingId = ref(null)

const form = ref({ name: '', target: '', current: '', icon: '🎯', deadline: '' })
const iconOptions = ['🎯', '💻', '🏖️', '🚗', '🏠', '📱', '🎓', '🛡️', '💍', '✈️', '🏋️', '🎵']

function openAdd() {
  editingId.value = null
  form.value = { name: '', target: '', current: '0', icon: '🎯', deadline: '' }
  showModal.value = true
}

function openEdit(g) {
  editingId.value = g.id
  form.value = {
    name: g.name,
    target: g.target,
    current: g.current,
    icon: g.icon || '🎯',
    deadline: g.deadline || '',
  }
  showModal.value = true
}

async function saveGoal() {
  if (!form.value.name || !form.value.target) {
    toast.error('Please enter a name and target amount')
    return
  }
  saving.value = true
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) throw new Error('Not authenticated')

    const payload = {
      name: form.value.name,
      target: Number(form.value.target),
      current: Number(form.value.current) || 0,
      icon: form.value.icon,
      deadline: form.value.deadline || null,
    }

    if (editingId.value) {
      const { error } = await supabase.from('savings_goals').update(payload).eq('id', editingId.value)
      if (error) throw error
      toast.success('Goal updated')
    } else {
      const { error } = await supabase.from('savings_goals').insert({ ...payload, user_id: user.id })
      if (error) throw error
      toast.success('Goal created')
    }
    showModal.value = false
    await fetchAll()
  } catch (e) {
    toast.error(e.message || 'Failed to save goal')
  } finally {
    saving.value = false
  }
}

async function confirmDeleteGoal() {
  try {
    const { error } = await supabase.from('savings_goals').delete().eq('id', deletingId.value)
    if (error) throw error
    toast.success('Goal deleted')
    deletingId.value = null
    await fetchAll()
  } catch {
    toast.error('Failed to delete goal')
  }
}

const goals = computed(() =>
  savingsGoals.value.map(g => ({
    name: g.name,
    target: Number(g.target),
    current: Number(g.current),
    icon: g.icon || '🎯',
    deadline: g.deadline ? new Date(g.deadline).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' }) : 'No deadline',
    color: '#D7F34A',
  }))
)

const totalTarget = computed(() => goals.value.reduce((s, g) => s + g.target, 0))
const totalSaved = computed(() => goals.value.reduce((s, g) => s + g.current, 0))
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Loading -->
      <div v-if="loading" class="loading-page">
        <span class="spinner-lg"></span>
        <p>Loading savings goals...</p>
      </div>

      <template v-else>
        <!-- Header -->
        <div class="page-header">
          <div>
            <h1 class="page-title">Savings Goals</h1>
            <p class="page-desc">Track progress toward your financial targets.</p>
          </div>
          <button class="add-btn" @click="openAdd">+ Add Goal</button>
        </div>

        <!-- Empty -->
        <div v-if="goals.length === 0" class="empty-state">
          <div class="empty-icon">🎯</div>
          <h3>No savings goals yet</h3>
          <p>Create your first goal to start tracking progress!</p>
          <button class="add-btn" @click="openAdd">+ Create First Goal</button>
        </div>

        <template v-else>
          <!-- Stats -->
          <div class="stats-row">
            <div class="stat-card">
              <p class="stat-label">Total Saved</p>
              <p class="stat-value">₹{{ totalSaved.toLocaleString() }}</p>
            </div>
            <div class="stat-card">
              <p class="stat-label">Total Target</p>
              <p class="stat-value">₹{{ totalTarget.toLocaleString() }}</p>
            </div>
            <div class="stat-card">
              <p class="stat-label">Overall Progress</p>
              <p class="stat-value accent">{{ totalTarget ? Math.round(totalSaved / totalTarget * 100) : 0 }}%</p>
            </div>
          </div>

          <!-- Goals Grid -->
          <div class="goals-grid">
            <div v-for="goal in goals" :key="goal.name" class="card">
              <div class="card-top">
                <span class="card-icon">{{ goal.icon }}</span>
                <span class="card-deadline">{{ goal.deadline }}</span>
              </div>
              <h3 class="card-name">{{ goal.name }}</h3>
              <div class="card-amounts">
                <span class="card-current">₹{{ goal.current.toLocaleString() }}</span>
                <span class="card-target">of ₹{{ goal.target.toLocaleString() }}</span>
              </div>
              <div class="goal-bar-track">
                <div class="goal-bar-fill" :style="{ width: Math.min(Math.round(goal.current / (goal.target || 1) * 100), 100) + '%', background: goal.color }"></div>
              </div>
              <div class="card-footer">
                <span class="card-pct">{{ goal.target ? Math.round(goal.current / goal.target * 100) : 0 }}% completed</span>
              <span class="card-left">₹{{ Math.max(goal.target - goal.current, 0).toLocaleString() }} left</span>
              </div>
              <div class="card-btns">
                <button class="edit-btn" @click="openEdit(savingsGoals[goals.indexOf(goal)])">✏️ Edit</button>
                <button class="del-btn" @click="deletingId = savingsGoals[goals.indexOf(goal)]?.id">🗑️</button>
              </div>
            </div>
          </div>
        </template>
      </template>

      <!-- Add/Edit Modal -->
      <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
        <div class="modal">
          <button class="modal-close" @click="showModal = false">✕</button>
          <h3 class="modal-title">{{ editingId ? 'Edit Goal' : 'New Savings Goal' }}</h3>
          <p class="modal-sub">Set a target and track your progress.</p>
          <div class="modal-form">
            <div class="field">
              <label class="label">Goal Name</label>
              <input v-model="form.name" type="text" placeholder="e.g. New Laptop" class="input" />
            </div>
            <div class="field-row">
              <div class="field">
                <label class="label">Target Amount (₹)</label>
                <input v-model="form.target" type="number" placeholder="80000" class="input" min="0" />
              </div>
              <div class="field">
                <label class="label">Already Saved (₹)</label>
                <input v-model="form.current" type="number" placeholder="0" class="input" min="0" />
              </div>
            </div>
            <div class="field">
              <label class="label">Deadline (optional)</label>
              <input v-model="form.deadline" type="date" class="input" />
            </div>
            <div class="field">
              <label class="label">Icon</label>
              <div class="icon-grid">
                <button v-for="ic in iconOptions" :key="ic" type="button" class="icon-btn" :class="{ active: form.icon === ic }" @click="form.icon = ic">{{ ic }}</button>
              </div>
            </div>
            <button class="save-btn" :disabled="saving || !form.name || !form.target" @click="saveGoal">
              {{ saving ? 'Saving...' : editingId ? 'Update Goal' : 'Create Goal' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Delete Confirmation -->
      <div v-if="deletingId" class="modal-overlay" @click.self="deletingId = null">
        <div class="modal modal-sm">
          <h3 class="modal-title">Delete Goal?</h3>
          <p class="modal-sub">This cannot be undone.</p>
          <div class="modal-actions">
            <button class="cancel-btn" @click="deletingId = null">Cancel</button>
            <button class="delete-btn" @click="confirmDeleteGoal">Delete</button>
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

.empty-state { text-align: center; padding: 4rem 1rem; color: var(--color-text-muted); display: flex; flex-direction: column; align-items: center; gap: 0.5rem; }
.empty-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
.empty-state h3 { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.empty-state p { font-size: 0.8125rem; margin-bottom: 0.75rem; }

.stats-row { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }

.stat-card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.25rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.stat-label { font-size: 0.8125rem; color: var(--color-text-muted); margin-bottom: 0.5rem; }
.stat-value { font-size: 1.375rem; font-weight: 700; color: var(--color-text); }
.stat-value.accent { color: var(--color-accent-hover); }

.goals-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; }

.card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex; flex-direction: column; gap: 0.75rem;
}

.card-top { display: flex; align-items: center; justify-content: space-between; }
.card-icon { font-size: 1.5rem; }

.card-deadline {
  font-size: 0.6875rem; color: var(--color-text-muted);
  background: var(--color-bg); padding: 0.25rem 0.625rem; border-radius: 999px;
}

.card-name { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.card-amounts { display: flex; align-items: baseline; gap: 0.375rem; }
.card-current { font-size: 1.25rem; font-weight: 700; color: var(--color-text); }
.card-target { font-size: 0.8125rem; color: var(--color-text-muted); }

.goal-bar-track { height: 6px; background: var(--color-bg); border-radius: 3px; overflow: hidden; }
.goal-bar-fill { height: 100%; border-radius: 3px; transition: width 0.3s ease; }

.card-footer { display: flex; justify-content: space-between; }
.card-pct { font-size: 0.75rem; color: var(--color-text-muted); }
.card-left { font-size: 0.75rem; color: var(--color-text-muted); }

.card-btns { display: flex; gap: 0.5rem; margin-top: 0.25rem; }
.edit-btn, .del-btn { background: none; border: none; cursor: pointer; font-size: 0.8125rem; opacity: 0.5; transition: opacity 0.15s; padding: 0.25rem; }
.edit-btn:hover, .del-btn:hover { opacity: 1; }

.page-header { display: flex; align-items: flex-start; justify-content: space-between; gap: 1rem; }
.page-title { font-size: 1.5rem; font-weight: 700; color: var(--color-text); }
.page-desc { font-size: 0.875rem; color: var(--color-text-muted); margin-top: 0.25rem; }
.add-btn { padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 600; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-accent); border: none; border-radius: var(--radius); cursor: pointer; white-space: nowrap; transition: background 0.2s; }
.add-btn:hover { background: var(--color-accent-hover); }

.modal-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.4); display: flex; align-items: center; justify-content: center; z-index: 1000; animation: fadeIn 0.15s ease; }
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
.modal { background: var(--color-surface); border-radius: var(--radius-lg); padding: 2rem; max-width: 480px; width: 94%; position: relative; animation: slideUp 0.2s ease; }
.modal-sm { max-width: 360px; }
@keyframes slideUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }
.modal-close { position: absolute; top: 1.25rem; right: 1.25rem; width: 28px; height: 28px; border-radius: 50%; border: none; background: var(--color-bg); color: var(--color-text-muted); font-size: 0.75rem; cursor: pointer; display: flex; align-items: center; justify-content: center; }
.modal-close:hover { background: rgba(211, 47, 47, 0.1); color: #d32f2f; }
.modal-title { font-size: 1.125rem; font-weight: 700; color: var(--color-text); margin-bottom: 0.25rem; }
.modal-sub { font-size: 0.8125rem; color: var(--color-text-muted); margin-bottom: 1.5rem; }
.modal-form { display: flex; flex-direction: column; gap: 1rem; }
.field { display: flex; flex-direction: column; gap: 0.375rem; }
.field-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.label { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }
.input { padding: 0.625rem 0.875rem; font-size: 0.875rem; font-family: var(--font-sans); color: var(--color-text); background: var(--color-bg); border: 1.5px solid var(--color-border); border-radius: var(--radius); outline: none; transition: border-color 0.2s; }
.input:focus { border-color: var(--color-graphite); }
.icon-grid { display: flex; flex-wrap: wrap; gap: 0.5rem; }
.icon-btn { width: 36px; height: 36px; border-radius: var(--radius); border: 1.5px solid var(--color-border); background: var(--color-bg); font-size: 1.125rem; cursor: pointer; transition: all 0.15s; display: flex; align-items: center; justify-content: center; }
.icon-btn.active { border-color: var(--color-graphite); background: var(--color-surface); box-shadow: 0 0 0 2px var(--color-accent); }
.save-btn { padding: 0.75rem; font-size: 0.9375rem; font-weight: 600; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-accent); border: none; border-radius: var(--radius); cursor: pointer; transition: background 0.2s, opacity 0.2s; }
.save-btn:hover { background: var(--color-accent-hover); }
.save-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.modal-actions { display: flex; gap: 0.75rem; justify-content: flex-end; margin-top: 1rem; }
.cancel-btn { padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 500; font-family: var(--font-sans); color: var(--color-text-muted); background: none; border: 1.5px solid var(--color-border); border-radius: var(--radius); cursor: pointer; }
.cancel-btn:hover { border-color: var(--color-graphite); color: var(--color-text); }
.delete-btn { padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 600; font-family: var(--font-sans); color: #fff; background: #d32f2f; border: none; border-radius: var(--radius); cursor: pointer; }
.delete-btn:hover { background: #b71c1c; }
</style>
