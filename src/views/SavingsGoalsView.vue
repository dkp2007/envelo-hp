<script setup>
import DashboardLayout from '@/layouts/DashboardLayout.vue'

const goals = [
  { name: 'New Laptop', target: 80000, current: 32000, icon: '💻', deadline: 'Dec 2025', color: '#4285F4' },
  { name: 'Emergency Fund', target: 100000, current: 45000, icon: '🛡️', deadline: 'Jun 2026', color: '#2e7d32' },
  { name: 'Vacation', target: 50000, current: 12000, icon: '✈️', deadline: 'Mar 2026', color: '#e91e63' },
  { name: 'New Phone', target: 60000, current: 28000, icon: '📱', deadline: 'Jan 2026', color: '#9c27b0' },
  { name: 'Car Down Payment', target: 200000, current: 45000, icon: '🚗', deadline: 'Dec 2026', color: '#ff9800' },
]

const totalTarget = goals.reduce((s, g) => s + g.target, 0)
const totalSaved = goals.reduce((s, g) => s + g.current, 0)
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <div class="page-header">
        <button class="primary-btn">+ New Goal</button>
      </div>

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
          <p class="stat-value accent">{{ Math.round(totalSaved / totalTarget * 100) }}%</p>
        </div>
      </div>

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
            <div class="goal-bar-fill" :style="{ width: Math.round(goal.current / goal.target * 100) + '%', background: goal.color }"></div>
          </div>
          <div class="card-footer">
            <span class="card-pct">{{ Math.round(goal.current / goal.target * 100) }}% completed</span>
            <span class="card-left">₹{{ (goal.target - goal.current).toLocaleString() }} left</span>
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

.stat-value.accent {
  color: var(--color-accent-hover);
}

.goals-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.card-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-icon {
  font-size: 1.5rem;
}

.card-deadline {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  background: var(--color-bg);
  padding: 0.25rem 0.625rem;
  border-radius: 999px;
}

.card-name {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.card-amounts {
  display: flex;
  align-items: baseline;
  gap: 0.375rem;
}

.card-current {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-text);
}

.card-target {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.goal-bar-track {
  height: 6px;
  background: var(--color-bg);
  border-radius: 3px;
  overflow: hidden;
}

.goal-bar-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.3s ease;
}

.card-footer {
  display: flex;
  justify-content: space-between;
}

.card-pct {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.card-left {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}
</style>
