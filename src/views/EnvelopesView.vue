<script setup>
import { computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useFinance } from '@/composables/useFinance.js'

const {
  loading, fetchAll, budgetData, spendingByCategory,
  monthIncome, monthExpenses, monthSavings,
  categories: allCategories,
} = useFinance()

onMounted(() => { fetchAll() })

// Build envelope data from budgets + spending
const envelopes = computed(() => {
  return budgetData.value.map(b => {
    // Find subcategories
    const subs = allCategories.value
      .filter(c => c.parent_id === b.category_id)
      .map(sub => {
        // Sum transactions for this subcategory this month
        const spent = spendingByCategory.value
          .find(s => s.name === sub.name)?.spent || 0
        // Find budget for sub or use parent budget divided
        const budgetForSub = Math.round(b.budget / (budgetData.value.find(x => x.category_id === b.category_id)?.subCount || 1))
        return {
          name: sub.name,
          icon: sub.icon,
          spent,
          total: budgetForSub,
        }
      })
    return {
      name: b.name,
      icon: b.icon,
      color: b.color,
      spent: b.spent,
      total: b.budget,
      subs,
    }
  })
})

// If no budgets, build from spending alone
const envelopesFromSpending = computed(() => {
  if (budgetData.value.length > 0) return []
  return spendingByCategory.value.map(cat => ({
    name: cat.name,
    icon: cat.icon,
    color: cat.color,
    spent: cat.spent,
    total: cat.spent, // no budget set
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
        <!-- Empty -->
        <div v-if="displayEnvelopes.length === 0" class="empty-state">
          <div class="empty-icon">✉️</div>
          <h3>No envelopes yet</h3>
          <p>Add transactions and budgets to see your envelopes here!</p>
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
                <span class="card-amt">₹{{ cat.spent.toLocaleString() }} / ₹{{ cat.total.toLocaleString() }}</span>
              </div>
              <div class="bar-track">
                <div class="bar-fill" :style="{ width: Math.min((cat.spent / (cat.total || 1)) * 100, 100) + '%', background: cat.color }"></div>
              </div>
              <div v-if="cat.subs.length > 0" class="sub-list">
                <div v-for="sub in cat.subs" :key="sub.name" class="sub-row">
                  <span class="sub-name">{{ sub.icon || '' }} {{ sub.name }}</span>
                  <div class="sub-right">
                    <div class="sub-bar-track">
                      <div class="sub-bar-fill" :style="{ width: Math.min((sub.spent / (sub.total || 1)) * 100, 100) + '%', background: cat.color }"></div>
                    </div>
                    <span class="sub-amt">₹{{ sub.spent.toLocaleString() }} / ₹{{ sub.total.toLocaleString() }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </template>
      </template>
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

.empty-state { text-align: center; padding: 4rem 1rem; color: var(--color-text-muted); }
.empty-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
.empty-state h3 { font-size: 1rem; font-weight: 600; color: var(--color-text); margin-bottom: 0.25rem; }
.empty-state p { font-size: 0.8125rem; }

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
.card-amt { font-size: 0.8125rem; color: var(--color-text-muted); }

.sub-list { display: flex; flex-direction: column; gap: 0.5rem; }
.sub-row { display: flex; align-items: center; justify-content: space-between; }
.sub-name { font-size: 0.8125rem; color: var(--color-text-muted); min-width: 110px; }
.sub-right { display: flex; align-items: center; gap: 0.75rem; flex: 1; max-width: 220px; }
.sub-bar-track { flex: 1; height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; }
.sub-bar-fill { height: 100%; border-radius: 2px; opacity: 0.6; }
.sub-amt { font-size: 0.6875rem; color: var(--color-text-muted); white-space: nowrap; }
</style>
