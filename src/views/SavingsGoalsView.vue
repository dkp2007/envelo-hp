<script setup>
import { computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useFinance } from '@/composables/useFinance.js'

const { loading, fetchAll, savingsGoals } = useFinance()

onMounted(() => { fetchAll() })

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
        <!-- Empty -->
        <div v-if="goals.length === 0" class="empty-state">
          <div class="empty-icon">🎯</div>
          <h3>No savings goals yet</h3>
          <p>Create a goal in your settings to start tracking progress!</p>
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
</style>
