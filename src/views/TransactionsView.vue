<script setup>
import { ref } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'

const activeFilter = ref('all')

const filters = ['all', 'income', 'expense']

const transactions = [
  { id: 1, name: 'Salary', category: 'Income', amount: 50000, type: 'income', date: 'Aug 1', icon: '💼' },
  { id: 2, name: 'Freelance', category: 'Income', amount: 8000, type: 'income', date: 'Aug 15', icon: '💻' },
  { id: 3, name: 'Amazon', category: 'Shopping', amount: -1200, type: 'expense', date: 'Aug 28', icon: '🛍️' },
  { id: 4, name: 'Swiggy', category: 'Food', amount: -450, type: 'expense', date: 'Aug 28', icon: '🍔' },
  { id: 5, name: 'Uber', category: 'Transport', amount: -180, type: 'expense', date: 'Aug 27', icon: '🚗' },
  { id: 6, name: 'Movie Tickets', category: 'Entertainment', amount: -350, type: 'expense', date: 'Aug 25', icon: '🎬' },
  { id: 7, name: 'Groceries', category: 'Food', amount: -850, type: 'expense', date: 'Aug 24', icon: '🛒' },
  { id: 8, name: 'Electricity Bill', category: 'Rent', amount: -1200, type: 'expense', date: 'Aug 20', icon: '💡' },
  { id: 9, name: 'Netflix', category: 'Subscriptions', amount: -649, type: 'expense', date: 'Aug 18', icon: '📱' },
  { id: 10, name: 'Gym', category: 'Health', amount: -1500, type: 'expense', date: 'Aug 15', icon: '💪' },
]

const filtered = ref(transactions)

function setFilter(f) {
  activeFilter.value = f
  filtered.value = f === 'all' ? transactions : transactions.filter((t) => t.type === f)
}

const totalIncome = transactions.filter((t) => t.type === 'income').reduce((s, t) => s + t.amount, 0)
const totalExpense = transactions.filter((t) => t.type === 'expense').reduce((s, t) => s + Math.abs(t.amount), 0)
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <div class="page-header">
        <button class="primary-btn">+ Add Transaction</button>
      </div>

      <div class="stats-row">
        <div class="stat-card">
          <p class="stat-label">Total Income</p>
          <p class="stat-value green">+₹{{ totalIncome.toLocaleString() }}</p>
        </div>
        <div class="stat-card">
          <p class="stat-label">Total Expenses</p>
          <p class="stat-value red">-₹{{ totalExpense.toLocaleString() }}</p>
        </div>
        <div class="stat-card">
          <p class="stat-label">Net Balance</p>
          <p class="stat-value">₹{{ (totalIncome - totalExpense).toLocaleString() }}</p>
        </div>
      </div>

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
        </div>

        <div class="tx-list">
          <div v-for="tx in filtered" :key="tx.id" class="tx-row">
            <div class="tx-left">
              <span class="tx-icon">{{ tx.icon }}</span>
              <div class="tx-info">
                <span class="tx-name">{{ tx.name }}</span>
                <span class="tx-cat">{{ tx.category }}</span>
              </div>
            </div>
            <div class="tx-right">
              <span class="tx-amt" :class="{ income: tx.type === 'income' }">
                {{ tx.type === 'income' ? '+' : '-' }}₹{{ Math.abs(tx.amount).toLocaleString() }}
              </span>
              <span class="tx-date">{{ tx.date }}</span>
            </div>
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
  align-items: flex-start;
  justify-content: space-between;
}

.page-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text);
}

.page-subtitle {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
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

.stat-value.green {
  color: #2e7d32;
}

.stat-value.red {
  color: #d32f2f;
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
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

.filter-btn:hover {
  color: var(--color-text);
}

.filter-btn.active {
  background: var(--color-graphite);
  color: var(--color-surface);
}

.tx-list {
  display: flex;
  flex-direction: column;
}

.tx-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--color-bg);
}

.tx-row:last-child {
  border-bottom: none;
}

.tx-left {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.tx-icon {
  font-size: 1.25rem;
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg);
  border-radius: var(--radius);
}

.tx-info {
  display: flex;
  flex-direction: column;
}

.tx-name {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text);
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
}

.tx-amt {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.tx-amt.income {
  color: #2e7d32;
}

.tx-date {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}
</style>
