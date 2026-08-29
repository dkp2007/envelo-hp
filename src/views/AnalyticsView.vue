<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { Doughnut, Bar, Line, PolarArea, Radar } from 'vue-chartjs'
import {
  Chart as ChartJS,
  ArcElement, Tooltip, Legend, CategoryScale, LinearScale,
  BarElement, PointElement, LineElement, RadialLinearScale,
  PolarAreaController, Filler,
} from 'chart.js'
import { useFinance } from '@/composables/useFinance.js'

ChartJS.register(
  ArcElement, Tooltip, Legend, CategoryScale, LinearScale,
  BarElement, PointElement, LineElement, RadialLinearScale,
  PolarAreaController, Filler,
)

const { loading, fetchAll, monthlyData, categoryAggForMonths, spendingByCategory, monthIncome, monthExpenses, monthSavings, monthSavingsRate } = useFinance()

onMounted(() => { fetchAll() })

const categoryColors = {
  Rent: '#202124', Food: '#D7F34A', Fun: '#4285F4', Savings: '#2e7d32',
  Entertainment: '#a78bfa', Shopping: '#fb923c', Utilities: '#f472b6',
  default: '#9e9e9e',
}

function getColor(name) { return categoryColors[name] || categoryColors.default }

// Controls
const selectedRange = ref('all')
const graphType = ref('doughnut')

const rangeOptions = [
  { value: '1m', label: '1 Month' },
  { value: '3m', label: '3 Months' },
  { value: '6m', label: '6 Months' },
  { value: 'all', label: 'All Time' },
]

const graphOptions = [
  { value: 'doughnut', label: '🍩 Doughnut', icon: '🍩' },
  { value: 'polar', label: '🎯 Polar', icon: '🎯' },
  { value: 'bar', label: '📊 Bar', icon: '📊' },
  { value: 'line', label: '📈 Line', icon: '📈' },
  { value: 'radar', label: '🕸️ Radar', icon: '🕸️' },
]

// Filtered monthly data
const filteredMonths = computed(() => {
  const len = monthlyData.value.length
  switch (selectedRange.value) {
    case '1m': return monthlyData.value.slice(len - 1)
    case '3m': return monthlyData.value.slice(len - 3)
    case '6m': return monthlyData.value.slice(len - 6)
    default: return monthlyData.value
  }
})

// Shared tooltip style
const tooltipStyle = {
  backgroundColor: '#202124',
  titleFont: { family: 'Inter', size: 12 },
  bodyFont: { family: 'Inter', size: 12 },
  padding: 10,
  cornerRadius: 8,
  displayColors: true,
}

// Category Breakdown
const categoryAgg = computed(() => categoryAggForMonths(filteredMonths.value))

const categoryChartData = computed(() => ({
  labels: Object.keys(categoryAgg.value),
  datasets: [{
    data: Object.values(categoryAgg.value),
    backgroundColor: Object.keys(categoryAgg.value).map(k => getColor(k)),
    borderWidth: 0,
    hoverOffset: 6,
  }],
}))

const categoryLineData = computed(() => ({
  labels: Object.keys(categoryAgg.value),
  datasets: [{
    label: 'Amount',
    data: Object.values(categoryAgg.value),
    borderColor: '#202124',
    backgroundColor: 'rgba(215,243,74,0.2)',
    fill: true,
    tension: 0.35,
    pointRadius: 6,
    pointBackgroundColor: Object.keys(categoryAgg.value).map(k => getColor(k)),
    pointBorderColor: '#fff',
    pointBorderWidth: 2,
  }],
}))

const categoryLineOptions = {
  responsive: true, maintainAspectRatio: false,
  layout: { padding: 16 },
  plugins: {
    legend: { display: false },
    tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

const categoryBarData = computed(() => ({
  labels: Object.keys(categoryAgg.value),
  datasets: [{
    data: Object.values(categoryAgg.value),
    backgroundColor: Object.keys(categoryAgg.value).map(k => getColor(k)),
    borderRadius: 6,
  }],
}))

const categoryBarOptions = {
  responsive: true, maintainAspectRatio: false,
  layout: { padding: 16 },
  plugins: {
    legend: { display: false },
    tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

const doughnutOptions = {
  responsive: true, maintainAspectRatio: false, cutout: '65%',
  layout: { padding: 8 },
  plugins: { legend: { display: false }, tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.toLocaleString()}` } } },
}

const polarOptions = {
  responsive: true, maintainAspectRatio: false,
  layout: { padding: 8 },
  plugins: { legend: { display: false }, tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.toLocaleString()}` } } },
  scales: { r: { ticks: { display: false }, grid: { color: 'rgba(0,0,0,0.04)' } } },
}

const radarOptions = {
  responsive: true, maintainAspectRatio: false,
  layout: { padding: 8 },
  plugins: { legend: { display: false }, tooltip: tooltipStyle },
  scales: { r: { angleLines: { color: 'rgba(0,0,0,0.06)' }, grid: { color: 'rgba(0,0,0,0.04)' }, pointLabels: { font: { family: 'Inter', size: 12 } }, ticks: { display: false } } },
}

// Monthly Income vs Expenses bar
const barData = computed(() => ({
  labels: filteredMonths.value.map(m => m.short),
  datasets: [
    { label: 'Income', data: filteredMonths.value.map(m => m.income), backgroundColor: '#2e7d32', borderRadius: 4 },
    { label: 'Expenses', data: filteredMonths.value.map(m => m.expenses), backgroundColor: '#d32f2f', borderRadius: 4 },
  ],
}))

const barOptions = {
  responsive: true, maintainAspectRatio: false,
  plugins: {
    legend: { position: 'top', labels: { usePointStyle: true, pointStyle: 'circle', padding: 16, font: { family: 'Inter', size: 11 } } },
    tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ${ctx.dataset.label}: ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

// Spending trend per category over months
const lineData = computed(() => {
  const cats = Object.keys(categoryAgg.value)
  return {
    labels: filteredMonths.value.map(m => m.short),
    datasets: cats.map((cat, i) => ({
      label: cat,
      data: filteredMonths.value.map(m => m.categories[cat] || 0),
      borderColor: getColor(cat),
      backgroundColor: getColor(cat) + '18',
      fill: true, tension: 0.35, pointRadius: 4,
      pointBackgroundColor: getColor(cat), pointBorderColor: '#fff', pointBorderWidth: 2,
    })),
  }
})

const lineOptions = {
  responsive: true, maintainAspectRatio: false,
  interaction: { mode: 'index', intersect: false },
  plugins: {
    legend: { position: 'top', labels: { usePointStyle: true, pointStyle: 'circle', padding: 16, font: { family: 'Inter', size: 11 } } },
    tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ${ctx.dataset.label}: ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

// Stacked bar
const stackedData = computed(() => {
  const cats = Object.keys(categoryAgg.value)
  return {
    labels: filteredMonths.value.map(m => m.short),
    datasets: cats.map(cat => ({
      label: cat,
      data: filteredMonths.value.map(m => m.categories[cat] || 0),
      backgroundColor: getColor(cat),
      borderRadius: 2,
    })),
  }
})

const stackedOptions = {
  responsive: true, maintainAspectRatio: false,
  plugins: {
    legend: { position: 'top', labels: { usePointStyle: true, pointStyle: 'circle', padding: 12, font: { family: 'Inter', size: 11 } } },
    tooltip: { ...tooltipStyle, callbacks: { label: (ctx) => ` ${ctx.dataset.label}: ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { stacked: true, grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { stacked: true, grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

// Legend
const spendingLegend = computed(() => {
  const total = Object.values(categoryAgg.value).reduce((s, v) => s + v, 0)
  return Object.entries(categoryAgg.value).map(([k, v]) => ({
    label: k,
    amount: '₹' + v.toLocaleString(),
    color: getColor(k),
    pct: total ? Math.round(v / total * 100) : 0,
  })).sort((a, b) => b.pct - a.pct)
})

// Top Expenses
const topExpenses = computed(() => {
  const last = filteredMonths.value[filteredMonths.value.length - 1]
  if (!last) return []
  const total = Object.values(last.categories).reduce((s, v) => s + v, 0)
  return Object.entries(last.categories)
    .map(([name, amount]) => ({
      name,
      amount,
      pct: total ? Math.round(amount / total * 100) : 0,
      color: getColor(name),
    }))
    .sort((a, b) => b.amount - a.amount)
})

// Summary Metrics
const metrics = computed(() => {
  const m = filteredMonths.value
  if (m.length === 0) return { avgIncome: 0, avgExpense: 0, avgSavings: 0, savingsRate: 0, bestMonth: null, worstMonth: null }
  const ti = m.reduce((s, x) => s + x.income, 0)
  const te = m.reduce((s, x) => s + x.expenses, 0)
  const ts = m.reduce((s, x) => s + x.saved, 0)
  return {
    avgIncome: Math.round(ti / m.length),
    avgExpense: Math.round(te / m.length),
    avgSavings: Math.round(ts / m.length),
    savingsRate: ti ? Math.round(ts / ti * 100) : 0,
    bestMonth: [...m].sort((a, b) => (b.saved / (b.income || 1)) - (a.saved / (a.income || 1)))[0],
    worstMonth: [...m].sort((a, b) => (a.saved / (a.income || 1)) - (b.saved / (b.income || 1)))[0],
  }
})
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Loading -->
      <div v-if="loading" class="loading-page">
        <span class="spinner-lg"></span>
        <p>Loading analytics...</p>
      </div>

      <template v-else>
        <!-- Controls -->
        <div class="controls">
          <div class="range-tabs">
            <button v-for="r in rangeOptions" :key="r.value" class="range-tab" :class="{ active: selectedRange === r.value }" @click="selectedRange = r.value">
              {{ r.label }}
            </button>
          </div>
          <div class="graph-tabs">
            <button v-for="g in graphOptions" :key="g.value" class="graph-tab" :class="{ active: graphType === g.value }" @click="graphType = g.value" :title="g.label">
              {{ g.icon }}
            </button>
          </div>
        </div>

        <!-- Summary Metrics -->
        <div class="metrics-row">
          <div class="metric-card">
            <div class="metric-icon green-bg">📈</div>
            <div>
              <p class="metric-label">Avg Monthly Income</p>
              <p class="metric-value green">₹{{ metrics.avgIncome.toLocaleString() }}</p>
            </div>
          </div>
          <div class="metric-card">
            <div class="metric-icon red-bg">📉</div>
            <div>
              <p class="metric-label">Avg Monthly Expense</p>
              <p class="metric-value red">₹{{ metrics.avgExpense.toLocaleString() }}</p>
            </div>
          </div>
          <div class="metric-card">
            <div class="metric-icon accent-bg">💰</div>
            <div>
              <p class="metric-label">Avg Monthly Savings</p>
              <p class="metric-value">₹{{ metrics.avgSavings.toLocaleString() }}</p>
            </div>
          </div>
          <div class="metric-card">
            <div class="metric-icon accent-bg">📊</div>
            <div>
              <p class="metric-label">Savings Rate</p>
              <p class="metric-value">{{ metrics.savingsRate }}%</p>
            </div>
          </div>
        </div>

        <!-- Empty state if no data -->
        <div v-if="monthlyData.length === 0" class="empty-state card">
          <div class="empty-icon">📊</div>
          <h3>No data yet</h3>
          <p>Add some transactions to see your analytics!</p>
        </div>

        <template v-else>
          <!-- Charts -->
          <div class="charts-row">
            <div class="card category-card">
              <div class="card-header">
                <h2 class="card-title">Spending by Category</h2>
              </div>
              <div class="category-body">
                <div class="chart-wrap-center">
                  <Doughnut v-if="graphType === 'doughnut'" :data="categoryChartData" :options="doughnutOptions" />
                  <PolarArea v-else-if="graphType === 'polar'" :data="categoryChartData" :options="polarOptions" />
                  <Radar v-else-if="graphType === 'radar'" :data="categoryChartData" :options="radarOptions" />
                  <Line v-else-if="graphType === 'line'" :data="categoryLineData" :options="categoryLineOptions" />
                  <Bar v-else :data="categoryBarData" :options="categoryBarOptions" />
                </div>
                <div class="legend">
                  <div v-for="item in spendingLegend" :key="item.label" class="legend-item">
                    <span class="legend-dot" :style="{ background: item.color }"></span>
                    <span class="legend-label">{{ item.label }}</span>
                    <span class="legend-pct">{{ item.pct }}%</span>
                    <span class="legend-amount">{{ item.amount }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Income vs Expenses</h2>
              </div>
              <div class="chart-tall">
                <Bar :data="barData" :options="barOptions" />
              </div>
            </div>
          </div>

          <div class="charts-row">
            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Spending Trend</h2>
              </div>
              <div class="chart-tall">
                <Line :data="lineData" :options="lineOptions" />
              </div>
            </div>

            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Expense Breakdown</h2>
              </div>
              <div class="chart-tall">
                <Bar :data="stackedData" :options="stackedOptions" />
              </div>
            </div>
          </div>

          <!-- Bottom -->
          <div class="bottom-grid">
            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Top Expenses — {{ filteredMonths[filteredMonths.length - 1]?.short }}</h2>
              </div>
              <div v-if="topExpenses.length === 0" class="empty-state">
                <p>No expenses this period</p>
              </div>
              <div v-else class="expense-list">
                <div v-for="(exp, i) in topExpenses" :key="exp.name" class="expense-row">
                  <div class="exp-left">
                    <span class="exp-rank">{{ i + 1 }}</span>
                    <span class="exp-dot" :style="{ background: exp.color }"></span>
                    <span class="exp-name">{{ exp.name }}</span>
                  </div>
                  <div class="exp-right">
                    <div class="exp-bar-track">
                      <div class="exp-bar-fill" :style="{ width: exp.pct + '%', background: exp.color }"></div>
                    </div>
                    <span class="exp-amt">₹{{ exp.amount.toLocaleString() }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="card highlight-card">
              <div class="card-header">
                <h2 class="card-title">Highlights</h2>
              </div>
              <div class="highlight-list">
                <div class="highlight-row">
                  <div class="hl-icon green-bg">🏆</div>
                  <div>
                    <p class="hl-label">Best Savings Month</p>
                    <p class="hl-value green">{{ metrics.bestMonth?.short }} — {{ metrics.bestMonth ? Math.round((metrics.bestMonth.saved / (metrics.bestMonth.income || 1)) * 100) : 0 }}% saved</p>
                  </div>
                </div>
                <div class="highlight-row">
                  <div class="hl-icon red-bg">⚠️</div>
                  <div>
                    <p class="hl-label">Needs Attention</p>
                    <p class="hl-value red">{{ metrics.worstMonth?.short }} — {{ metrics.worstMonth ? Math.round((metrics.worstMonth.saved / (metrics.worstMonth.income || 1)) * 100) : 0 }}% saved</p>
                  </div>
                </div>
                <div class="highlight-row" v-if="spendingLegend.length">
                  <div class="hl-icon accent-bg">💸</div>
                  <div>
                    <p class="hl-label">Highest Spend Category</p>
                    <p class="hl-value">{{ spendingLegend[0]?.label }} — {{ spendingLegend[0]?.pct }}% of total</p>
                  </div>
                </div>
                <div class="highlight-row" v-if="spendingLegend.length > 1">
                  <div class="hl-icon accent-bg">📉</div>
                  <div>
                    <p class="hl-label">Lowest Spend Category</p>
                    <p class="hl-value">{{ spendingLegend[spendingLegend.length - 1]?.label }} — {{ spendingLegend[spendingLegend.length - 1]?.pct }}% of total</p>
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

.empty-state {
  text-align: center; padding: 3rem 1rem; color: var(--color-text-muted);
}

.empty-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
.empty-state h3 { font-size: 1rem; font-weight: 600; color: var(--color-text); margin-bottom: 0.25rem; }
.empty-state p { font-size: 0.8125rem; }

.controls { display: flex; align-items: center; justify-content: space-between; }

.range-tabs {
  display: flex; gap: 0.25rem; background: var(--color-surface);
  border-radius: var(--radius); padding: 0.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.range-tab {
  padding: 0.5rem 1rem; font-size: 0.8125rem; font-weight: 500;
  font-family: var(--font-sans); color: var(--color-text-muted);
  background: none; border: none; border-radius: 6px; cursor: pointer; transition: all 0.15s;
}

.range-tab:hover { color: var(--color-text); }
.range-tab.active { background: var(--color-graphite); color: var(--color-surface); font-weight: 600; }

.graph-tabs {
  display: flex; gap: 0.25rem; background: var(--color-surface);
  border-radius: var(--radius); padding: 0.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.graph-tab {
  width: 36px; height: 32px; display: flex; align-items: center;
  justify-content: center; font-size: 1rem; background: none;
  border: none; border-radius: 6px; cursor: pointer; transition: all 0.15s;
}

.graph-tab:hover { background: var(--color-bg); }
.graph-tab.active { background: var(--color-accent); }

.metrics-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }

.metric-card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1rem 1.125rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex; align-items: center; gap: 0.75rem;
}

.metric-icon {
  width: 38px; height: 38px; border-radius: var(--radius);
  display: flex; align-items: center; justify-content: center;
  font-size: 1rem; flex-shrink: 0;
}

.green-bg { background: rgba(46, 125, 50, 0.1); }
.red-bg { background: rgba(211, 47, 47, 0.1); }
.accent-bg { background: rgba(215, 243, 74, 0.2); }

.metric-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.metric-value { font-size: 1.0625rem; font-weight: 700; color: var(--color-text); }
.metric-value.green { color: #2e7d32; }
.metric-value.red { color: #d32f2f; }

.charts-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }

.card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
.card-title { font-size: 0.9375rem; font-weight: 600; color: var(--color-text); }

.category-body { display: flex; align-items: center; gap: 1.5rem; }

.chart-wrap-center {
  width: 240px; height: 240px; flex-shrink: 0; position: relative;
  padding: 16px; margin: -16px;
}

.chart-tall { height: 360px; }

.legend { display: flex; flex-direction: column; gap: 0.625rem; flex: 1; }
.legend-item { display: flex; align-items: center; gap: 0.5rem; font-size: 0.875rem; padding: 0.25rem 0; }
.legend-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
.legend-label { color: var(--color-text-muted); flex: 1; }
.legend-pct { font-weight: 600; color: var(--color-text); min-width: 28px; text-align: right; }
.legend-amount { font-weight: 600; color: var(--color-text); min-width: 64px; text-align: right; }

.expense-list { display: flex; flex-direction: column; gap: 0.75rem; }
.expense-row { display: flex; align-items: center; justify-content: space-between; }
.exp-left { display: flex; align-items: center; gap: 0.5rem; }
.exp-rank { font-size: 0.75rem; font-weight: 600; color: var(--color-text-muted); width: 16px; text-align: center; }
.exp-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.exp-name { font-size: 0.8125rem; color: var(--color-text); }
.exp-right { display: flex; align-items: center; gap: 0.75rem; flex: 1; max-width: 200px; }
.exp-bar-track { flex: 1; height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; }
.exp-bar-fill { height: 100%; border-radius: 2px; transition: width 0.3s ease; }
.exp-amt { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); min-width: 60px; text-align: right; }

.highlight-list { display: flex; flex-direction: column; gap: 1rem; }
.highlight-row { display: flex; align-items: flex-start; gap: 0.75rem; }

.hl-icon {
  width: 36px; height: 36px; border-radius: var(--radius);
  display: flex; align-items: center; justify-content: center;
  font-size: 1rem; flex-shrink: 0;
}

.hl-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.hl-value { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); margin-top: 0.125rem; }
.hl-value.green { color: #2e7d32; }
.hl-value.red { color: #d32f2f; }

.bottom-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
</style>
