<script setup>
import DashboardLayout from '@/layouts/DashboardLayout.vue'

const categories = [
  {
    name: 'Rent',
    icon: '🏠',
    color: '#202124',
    spent: 12000,
    total: 20000,
    subs: [
      { name: 'Housing', spent: 8000, total: 12000 },
      { name: 'Utilities', spent: 2500, total: 4000 },
      { name: 'Internet', spent: 1000, total: 1500 },
      { name: 'Maintenance', spent: 500, total: 2500 },
    ],
  },
  {
    name: 'Food',
    icon: '🍔',
    color: '#D7F34A',
    spent: 2750,
    total: 5000,
    subs: [
      { name: 'Groceries', spent: 1200, total: 2000 },
      { name: 'Dining Out', spent: 800, total: 1500 },
      { name: 'Delivery', spent: 500, total: 1000 },
      { name: 'Coffee', spent: 250, total: 500 },
    ],
  },
  {
    name: 'Fun',
    icon: '🎮',
    color: '#4285F4',
    spent: 4250,
    total: 8000,
    subs: [
      { name: 'Entertainment', spent: 1500, total: 3000 },
      { name: 'Shopping', spent: 1200, total: 2500 },
      { name: 'Travel', spent: 800, total: 1500 },
      { name: 'Subscriptions', spent: 750, total: 1000 },
    ],
  },
  {
    name: 'Savings',
    icon: '💰',
    color: '#2e7d32',
    spent: 8000,
    total: 12000,
    subs: [
      { name: 'Emergency Fund', spent: 3500, total: 5000 },
      { name: 'Investments', spent: 2500, total: 4000 },
      { name: 'Goals', spent: 2000, total: 3000 },
    ],
  },
]

const totalBudget = categories.reduce((s, c) => s + c.total, 0)
const totalSpent = categories.reduce((s, c) => s + c.spent, 0)
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <div class="page-header">
        <button class="primary-btn">+ New Envelope</button>
      </div>

      <div class="overview-bar">
        <div class="bar-info">
          <span class="bar-label">Total Budget</span>
          <span class="bar-amt">₹{{ totalSpent.toLocaleString() }} / ₹{{ totalBudget.toLocaleString() }}</span>
        </div>
        <div class="bar-track">
          <div class="bar-fill" :style="{ width: (totalSpent / totalBudget * 100) + '%' }"></div>
        </div>
        <span class="bar-pct">{{ Math.round(totalSpent / totalBudget * 100) }}% used</span>
      </div>

      <div class="envelope-grid">
        <div v-for="cat in categories" :key="cat.name" class="card">
          <div class="card-header">
            <div class="card-title-row">
              <span class="card-icon">{{ cat.icon }}</span>
              <h2 class="card-title">{{ cat.name }}</h2>
            </div>
            <span class="card-amt">₹{{ cat.spent.toLocaleString() }} / ₹{{ cat.total.toLocaleString() }}</span>
          </div>
          <div class="bar-track">
            <div class="bar-fill" :style="{ width: Math.min((cat.spent / cat.total) * 100, 100) + '%', background: cat.color }"></div>
          </div>
          <div class="sub-list">
            <div v-for="sub in cat.subs" :key="sub.name" class="sub-row">
              <span class="sub-name">{{ sub.name }}</span>
              <div class="sub-right">
                <div class="sub-bar-track">
                  <div class="sub-bar-fill" :style="{ width: Math.min((sub.spent / sub.total) * 100, 100) + '%', background: cat.color }"></div>
                </div>
                <span class="sub-amt">₹{{ sub.spent.toLocaleString() }} / ₹{{ sub.total.toLocaleString() }}</span>
              </div>
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

.overview-bar {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.bar-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.bar-label {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.bar-amt {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.bar-track {
  height: 8px;
  background: var(--color-bg);
  border-radius: 4px;
  overflow: hidden;
}

.bar-fill {
  height: 100%;
  background: var(--color-accent);
  border-radius: 4px;
  transition: width 0.3s ease;
}

.bar-pct {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-align: right;
}

.envelope-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-title-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.card-icon {
  font-size: 1.25rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.card-amt {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.sub-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.sub-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.sub-name {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  min-width: 110px;
}

.sub-right {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  max-width: 220px;
}

.sub-bar-track {
  flex: 1;
  height: 4px;
  background: var(--color-bg);
  border-radius: 2px;
  overflow: hidden;
}

.sub-bar-fill {
  height: 100%;
  border-radius: 2px;
  opacity: 0.6;
}

.sub-amt {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  white-space: nowrap;
}
</style>
