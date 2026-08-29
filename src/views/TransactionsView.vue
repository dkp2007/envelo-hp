<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useFinance } from '@/composables/useFinance.js'
import { useRouter } from 'vue-router'

const router = useRouter()
const { transactions, loading, fetchAll, deleteTransaction, totalIncome, totalExpenses, netBalance, getCategoryColor } = useFinance()

const searchQuery = ref('')
const activeFilter = ref('all')
const filters = ['all', 'income', 'expense']
const confirmDelete = ref(null)

onMounted(() => { fetchAll() })

function setFilter(f) {
  activeFilter.value = f
}

const filtered = computed(() => {
  let list = transactions.value
  if (activeFilter.value !== 'all') {
    list = list.filter(t => t.type === activeFilter.value)
  }
  if (searchQuery.value.trim()) {
    const q = searchQuery.value.toLowerCase()
    list = list.filter(t =>
      t.name.toLowerCase().includes(q) ||
      t.categories?.name?.toLowerCase().includes(q) ||
      t.merchant?.toLowerCase().includes(q) ||
      String(Math.abs(Number(t.amount))).includes(q)
    )
  }
  return list
})

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}

async function handleDelete(tx) {
  try {
    await deleteTransaction(tx.id)
    confirmDelete.value = null
  } catch (err) {
    console.error('Delete failed:', err)
  }
}

function getCategoryInfo(tx) {
  return {
    name: tx.categories?.name || 'Uncategorized',
    icon: tx.categories?.icon || '📦',
    color: tx.categories?.color || getCategoryColor(tx.categories?.name),
  }
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <div class="page-header">
        <div class="search-wrap">
          <span class="search-icon">🔍</span>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Search transactions..."
            class="search-input"
          />
        </div>
        <button class="primary-btn" @click="router.push('/add-expense')">
          + Add Transaction
        </button>
      </div>

      <!-- Stats -->
      <div class="stats-row">
        <div class="stat-card">
          <p class="stat-label">Total Income</p>
          <p class="stat-value green">+₹{{ totalIncome.toLocaleString() }}</p>
        </div>
        <div class="stat-card">
          <p class="stat-label">Total Expenses</p>
          <p class="stat-value red">-₹{{ totalExpenses.toLocaleString() }}</p>
        </div>
        <div class="stat-card">
          <p class="stat-label">Net Balance</p>
          <p class="stat-value">₹{{ netBalance.toLocaleString() }}</p>
        </div>
      </div>

      <!-- Filters -->
      <div class="card">
        <div class="card-header">
          <div class="filters">
            <button
              v-for="f in filters"
              :key="f"
              class="filter-btn"
              :class="{ active: activeFilter === f }"
              @click="setFilter(f)"
            >
              {{ f.charAt(0).toUpperCase() + f.slice(1) }}
            </button>
          </div>
          <span class="tx-count">{{ filtered.length }} transactions</span>
        </div>

        <!-- Loading -->
        <div v-if="loading" class="tx-loading">
          <span class="spinner"></span>
          <span>Loading transactions...</span>
        </div>

        <!-- Empty -->
        <div v-else-if="filtered.length === 0" class="tx-empty">
          <div class="tx-empty-icon">📋</div>
          <p>{{ searchQuery ? 'No matching transactions' : 'No transactions yet' }}</p>
          <p class="tx-empty-hint">{{ searchQuery ? 'Try a different search' : 'Add your first transaction to get started' }}</p>
        </div>

        <!-- Transaction list -->
        <div v-else class="tx-list">
          <div v-for="tx in filtered" :key="tx.id" class="tx-row">
            <div class="tx-left">
              <span class="tx-icon" :style="{ background: getCategoryInfo(tx).color + '15' }">
                {{ getCategoryInfo(tx).icon }}
              </span>
              <div class="tx-info">
                <span class="tx-name">{{ tx.name }}</span>
                <span class="tx-cat">{{ getCategoryInfo(tx).name }}{{ tx.merchant ? ' · ' + tx.merchant : '' }}</span>
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amt" :class="{ income: tx.type === 'income' }">
                {{ tx.type === 'income' ? '+' : '-' }}₹{{ Math.abs(Number(tx.amount)).toLocaleString() }}
              </span>
              <span class="tx-date">{{ formatDate(tx.date) }}</span>
            </div>
            <div class="tx-actions">
              <button
                v-if="tx.bill_path"
                class="tx-action-btn"
                title="Has receipt"
              >📎</button>
              <button
                class="tx-action-btn delete"
                title="Delete"
                @click="confirmDelete = tx"
              >🗑</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Delete Confirmation -->
      <div v-if="confirmDelete" class="modal-overlay" @click.self="confirmDelete = null">
        <div class="modal-sm">
          <h3 class="modal-sm-title">Delete Transaction</h3>
          <p class="modal-sm-desc">
            Are you sure you want to delete <strong>"{{ confirmDelete.name }}"</strong>?
            This cannot be undone.
          </p>
          <div class="modal-sm-actions">
            <button class="modal-sm-cancel" @click="confirmDelete = null">Cancel</button>
            <button class="modal-sm-delete" @click="handleDelete(confirmDelete)">Delete</button>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.search-wrap {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: var(--color-surface);
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  padding: 0.625rem 1rem;
  flex: 1;
  max-width: 400px;
  transition: border-color 0.2s;
}

.search-wrap:focus-within {
  border-color: var(--color-graphite);
}

.search-icon {
  font-size: 0.875rem;
  flex-shrink: 0;
}

.search-input {
  flex: 1;
  border: none;
  background: none;
  font-size: 0.875rem;
  font-family: var(--font-sans);
  color: var(--color-text);
  outline: none;
}

.search-input::placeholder {
  color: var(--color-grey);
}

.primary-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.2s;
}

.primary-btn:hover {
  background: var(--color-accent-hover);
}

.stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.stat-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.stat-label {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  margin-bottom: 0.5rem;
}

.stat-value {
  font-size: 1.375rem;
  font-weight: 700;
  color: var(--color-text);
}

.stat-value.green { color: #2e7d32; }
.stat-value.red { color: #d32f2f; }

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
}

.filters {
  display: flex;
  gap: 0.5rem;
}

.filter-btn {
  padding: 0.5rem 1rem;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: var(--color-bg);
  border: 1.5px solid transparent;
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s;
}

.filter-btn:hover { color: var(--color-text); }

.filter-btn.active {
  background: var(--color-graphite);
  color: var(--color-surface);
}

.tx-count {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.tx-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 3rem;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid var(--color-border);
  border-top-color: var(--color-graphite);
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.tx-empty {
  text-align: center;
  padding: 3rem 1rem;
}

.tx-empty-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.tx-empty p {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.tx-empty-hint {
  font-size: 0.75rem !important;
  margin-top: 0.25rem;
  color: var(--color-grey) !important;
}

.tx-list {
  display: flex;
  flex-direction: column;
}

.tx-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--color-bg);
}

.tx-row:last-child { border-bottom: none; }

.tx-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  min-width: 0;
}

.tx-icon {
  font-size: 1.125rem;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: var(--radius);
  flex-shrink: 0;
}

.tx-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.tx-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tx-cat {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.tx-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  flex-shrink: 0;
}

.tx-amt {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.tx-amt.income { color: #2e7d32; }

.tx-date {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.tx-actions {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.15s;
}

.tx-row:hover .tx-actions { opacity: 1; }

.tx-action-btn {
  width: 28px;
  height: 28px;
  border-radius: var(--radius);
  border: none;
  background: none;
  cursor: pointer;
  font-size: 0.75rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s;
}

.tx-action-btn:hover { background: var(--color-bg); }

.tx-action-btn.delete:hover { background: rgba(211, 47, 47, 0.1); }

/* Delete modal */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.15s ease;
}

@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.modal-sm {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  max-width: 400px;
  width: 94%;
  animation: slideUp 0.2s ease;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}

.modal-sm-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.5rem;
}

.modal-sm-desc {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  line-height: 1.5;
  margin-bottom: 1.25rem;
}

.modal-sm-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: flex-end;
}

.modal-sm-cancel {
  padding: 0.5rem 1rem;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: none;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  cursor: pointer;
}

.modal-sm-delete {
  padding: 0.5rem 1rem;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: #fff;
  background: #d32f2f;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.15s;
}

.modal-sm-delete:hover { background: #b71c1c; }
</style>
