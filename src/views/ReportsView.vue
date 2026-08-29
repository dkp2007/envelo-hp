<script setup>
import { ref, computed } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { jsPDF } from 'jspdf'
import 'jspdf-autotable'
import * as XLSX from 'xlsx'
import { Bar, Line, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  ArcElement,
  Tooltip,
  Legend,
  CategoryScale,
  LinearScale,
  BarElement,
  PointElement,
  LineElement,
  Filler,
} from 'chart.js'

ChartJS.register(ArcElement, Tooltip, Legend, CategoryScale, LinearScale, BarElement, PointElement, LineElement, Filler)

/* ─── Data ─── */
const months = [
  { name: 'August 2025', short: 'Aug', income: 58000, expenses: 28450, saved: 29550 },
  { name: 'July 2025', short: 'Jul', income: 51000, expenses: 34000, saved: 17000 },
  { name: 'June 2025', short: 'Jun', income: 47000, expenses: 36000, saved: 11000 },
  { name: 'May 2025', short: 'May', income: 55000, expenses: 40000, saved: 15000 },
  { name: 'April 2025', short: 'Apr', income: 50000, expenses: 33000, saved: 17000 },
  { name: 'March 2025', short: 'Mar', income: 52000, expenses: 38000, saved: 14000 },
]

const topExpenses = [
  { name: 'Rent', amount: 12000, pct: 42, color: '#202124' },
  { name: 'Food', amount: 2750, pct: 10, color: '#D7F34A' },
  { name: 'Entertainment', amount: 1500, pct: 5, color: '#4285F4' },
  { name: 'Shopping', amount: 1200, pct: 4, color: '#a78bfa' },
  { name: 'Utilities', amount: 1000, pct: 4, color: '#fb923c' },
]

const budgetActual = [
  { category: 'Rent', budget: 20000, actual: 12000, icon: '🏠' },
  { category: 'Food', budget: 5000, actual: 2750, icon: '🍔' },
  { category: 'Fun', budget: 8000, actual: 4250, icon: '🎮' },
  { category: 'Savings', budget: 12000, actual: 8000, icon: '💰' },
]

const selectedRange = ref('6m')

/* ─── Computed Metrics ─── */
const totalIncome = computed(() => months.reduce((s, m) => s + m.income, 0))
const totalExpenses = computed(() => months.reduce((s, m) => s + m.expenses, 0))
const totalSaved = computed(() => months.reduce((s, m) => s + m.saved, 0))
const avgIncome = computed(() => Math.round(totalIncome.value / months.length))
const avgExpenses = computed(() => Math.round(totalExpenses.value / months.length))
const avgSavingsRate = computed(() => Math.round(totalSaved.value / totalIncome.value * 100))
const highestExpenseMonth = computed(() => [...months].sort((a, b) => b.expenses - a.expenses)[0])
const bestSavingsMonth = computed(() => [...months].sort((a, b) => (b.saved / b.income) - (a.saved / a.income))[0])

/* ─── Charts ─── */
const chartTooltipStyle = {
  backgroundColor: '#202124',
  titleFont: { family: 'Inter', size: 12 },
  bodyFont: { family: 'Inter', size: 12 },
  padding: 10,
  cornerRadius: 8,
}

const reversedMonths = computed(() => [...months].reverse())

// Income vs Expenses bar chart
const barData = computed(() => ({
  labels: reversedMonths.value.map(m => m.short),
  datasets: [
    {
      label: 'Income',
      data: reversedMonths.value.map(m => m.income),
      backgroundColor: '#2e7d32',
      borderRadius: 4,
    },
    {
      label: 'Expenses',
      data: reversedMonths.value.map(m => m.expenses),
      backgroundColor: '#d32f2f',
      borderRadius: 4,
    },
  ],
}))

const barOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: {
      position: 'top',
      labels: { usePointStyle: true, pointStyle: 'circle', padding: 16, font: { family: 'Inter', size: 11 } },
    },
    tooltip: {
      ...chartTooltipStyle,
      callbacks: { label: (ctx) => ` ${ctx.dataset.label}: ₹${ctx.parsed.y.toLocaleString()}` },
    },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: {
      grid: { color: 'rgba(0,0,0,0.04)' },
      ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' },
    },
  },
}

// Savings trend line chart
const lineData = computed(() => ({
  labels: reversedMonths.value.map(m => m.short),
  datasets: [{
    label: 'Savings',
    data: reversedMonths.value.map(m => m.saved),
    borderColor: '#D7F34A',
    backgroundColor: 'rgba(215, 243, 74, 0.15)',
    fill: true,
    tension: 0.35,
    pointRadius: 5,
    pointBackgroundColor: '#D7F34A',
    pointBorderColor: '#fff',
    pointBorderWidth: 2,
  }],
}))

const lineOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      ...chartTooltipStyle,
      callbacks: { label: (ctx) => ` ₹${ctx.parsed.y.toLocaleString()}` },
    },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: {
      grid: { color: 'rgba(0,0,0,0.04)' },
      ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' },
    },
  },
}

// Budget vs Actual doughnut
const budgetActualData = computed(() => ({
  labels: budgetActual.map(b => b.category),
  datasets: [{
    data: budgetActual.map(b => b.budget - b.actual),
    backgroundColor: budgetActual.map(b => b.actual <= b.budget * 0.6 ? '#2e7d32' : b.actual <= b.budget * 0.85 ? '#D7F34A' : '#fb923c'),
    borderWidth: 0,
    hoverOffset: 4,
  }],
}))

const budgetActualOptions = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '65%',
  plugins: {
    legend: { display: false },
    tooltip: {
      ...chartTooltipStyle,
      callbacks: { label: (ctx) => ` ₹${ctx.parsed.toLocaleString()} remaining` },
    },
  },
}

/* ─── Exports ─── */
function exportPDF() {
  const doc = new jsPDF()

  doc.setFontSize(20)
  doc.setFont('helvetica', 'bold')
  doc.text('Financial Report', 14, 22)
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(120)
  doc.text('Generated on ' + new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }), 14, 30)

  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(0)
  doc.text('Monthly Overview', 14, 44)

  doc.autoTable({
    startY: 48,
    head: [['Month', 'Income', 'Expenses', 'Saved', 'Savings Rate']],
    body: months.map(m => [
      m.name,
      '₹' + m.income.toLocaleString(),
      '₹' + m.expenses.toLocaleString(),
      '₹' + m.saved.toLocaleString(),
      Math.round(m.saved / m.income * 100) + '%',
    ]),
    theme: 'grid',
    headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 },
    alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: 14 },
  })

  const y1 = doc.lastAutoTable.finalY + 14
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('Budget vs Actual', 14, y1)

  doc.autoTable({
    startY: y1 + 4,
    head: [['Category', 'Budget', 'Actual', 'Remaining', 'Status']],
    body: budgetActual.map(b => [
      b.icon + ' ' + b.category,
      '₹' + b.budget.toLocaleString(),
      '₹' + b.actual.toLocaleString(),
      '₹' + (b.budget - b.actual).toLocaleString(),
      b.actual <= b.budget * 0.6 ? 'Under budget' : b.actual <= b.budget * 0.85 ? 'On track' : 'Watch spending',
    ]),
    theme: 'grid',
    headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 },
    alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: 14 },
  })

  const y2 = doc.lastAutoTable.finalY + 14
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('Top Expenses This Month', 14, y2)

  doc.autoTable({
    startY: y2 + 4,
    head: [['Category', 'Amount', '% of Total']],
    body: topExpenses.map(e => [e.name, '₹' + e.amount.toLocaleString(), e.pct + '%']),
    theme: 'grid',
    headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 },
    alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: 14 },
  })

  const y3 = doc.lastAutoTable.finalY + 14
  doc.setFontSize(14)
  doc.setFont('helvetica', 'bold')
  doc.text('Key Metrics', 14, y3)

  doc.autoTable({
    startY: y3 + 4,
    head: [['Metric', 'Value']],
    body: [
      ['Average Monthly Income', '₹' + avgIncome.value.toLocaleString()],
      ['Average Monthly Expense', '₹' + avgExpenses.value.toLocaleString()],
      ['Average Savings Rate', avgSavingsRate.value + '%'],
      ['Total Saved (6 months)', '₹' + totalSaved.value.toLocaleString()],
      ['Highest Expense Month', highestExpenseMonth.value.name],
      ['Best Savings Month', bestSavingsMonth.value.name],
    ],
    theme: 'grid',
    headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 },
    alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: 14 },
  })

  doc.save('Envelo_Financial_Report.pdf')
}

function exportExcel() {
  const wb = XLSX.utils.book_new()

  const ws1 = XLSX.utils.json_to_sheet(months.map(m => ({
    Month: m.name,
    Income: m.income,
    Expenses: m.expenses,
    Saved: m.saved,
    'Savings Rate (%)': Math.round(m.saved / m.income * 100),
  })))
  ws1['!cols'] = [{ wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }]
  XLSX.utils.book_append_sheet(wb, ws1, 'Monthly Overview')

  const ws2 = XLSX.utils.json_to_sheet(budgetActual.map(b => ({
    Category: b.category,
    Budget: b.budget,
    Actual: b.actual,
    Remaining: b.budget - b.actual,
    'Status': b.actual <= b.budget * 0.6 ? 'Under budget' : b.actual <= b.budget * 0.85 ? 'On track' : 'Watch spending',
  })))
  ws2['!cols'] = [{ wch: 16 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }]
  XLSX.utils.book_append_sheet(wb, ws2, 'Budget vs Actual')

  const ws3 = XLSX.utils.json_to_sheet(topExpenses.map(e => ({
    Category: e.name,
    Amount: e.amount,
    '% of Total': e.pct,
  })))
  ws3['!cols'] = [{ wch: 18 }, { wch: 14 }, { wch: 12 }]
  XLSX.utils.book_append_sheet(wb, ws3, 'Top Expenses')

  const ws4 = XLSX.utils.json_to_sheet([
    { Metric: 'Average Monthly Income', Value: '₹' + avgIncome.value.toLocaleString() },
    { Metric: 'Average Monthly Expense', Value: '₹' + avgExpenses.value.toLocaleString() },
    { Metric: 'Average Savings Rate', Value: avgSavingsRate.value + '%' },
    { Metric: 'Total Saved (6 months)', Value: '₹' + totalSaved.value.toLocaleString() },
    { Metric: 'Highest Expense Month', Value: highestExpenseMonth.value.name },
    { Metric: 'Best Savings Month', Value: bestSavingsMonth.value.name },
  ])
  ws4['!cols'] = [{ wch: 30 }, { wch: 22 }]
  XLSX.utils.book_append_sheet(wb, ws4, 'Key Metrics')

  XLSX.writeFile(wb, 'Envelo_Financial_Report.xlsx')
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Top Actions -->
      <div class="page-header">
        <div class="range-tabs">
          <button v-for="r in ['3m', '6m', '1y']" :key="r" class="range-tab" :class="{ active: selectedRange === r }" @click="selectedRange = r">
            {{ r === '3m' ? '3 Months' : r === '6m' ? '6 Months' : '1 Year' }}
          </button>
        </div>
        <div class="export-btns">
          <button class="export-btn pdf-btn" @click="exportPDF">📄 Export PDF</button>
          <button class="export-btn excel-btn" @click="exportExcel">📊 Export Excel</button>
        </div>
      </div>

      <!-- Key Metrics -->
      <div class="metrics-row">
        <div class="metric-card">
          <div class="metric-icon green-bg">📈</div>
          <div>
            <p class="metric-label">Total Income</p>
            <p class="metric-value green">₹{{ totalIncome.toLocaleString() }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-icon red-bg">📉</div>
          <div>
            <p class="metric-label">Total Expenses</p>
            <p class="metric-value red">₹{{ totalExpenses.toLocaleString() }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-icon accent-bg">💰</div>
          <div>
            <p class="metric-label">Total Saved</p>
            <p class="metric-value">₹{{ totalSaved.toLocaleString() }}</p>
          </div>
        </div>
        <div class="metric-card">
          <div class="metric-icon accent-bg">📊</div>
          <div>
            <p class="metric-label">Avg Savings Rate</p>
            <p class="metric-value">{{ avgSavingsRate }}%</p>
          </div>
        </div>
      </div>

      <!-- Charts Row: Bar + Line -->
      <div class="charts-row">
        <div class="card chart-card-wide">
          <div class="card-header">
            <h2 class="card-title">Income vs Expenses</h2>
          </div>
          <div class="chart-tall">
            <Bar :data="barData" :options="barOptions" />
          </div>
        </div>
        <div class="card chart-card-narrow">
          <div class="card-header">
            <h2 class="card-title">Savings Trend</h2>
          </div>
          <div class="chart-tall">
            <Line :data="lineData" :options="lineOptions" />
          </div>
        </div>
      </div>

      <!-- Budget vs Actual + Top Expenses -->
      <div class="bottom-grid">
        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Budget vs Actual</h2>
          </div>
          <div class="budget-grid">
            <div class="budget-chart-wrap">
              <Doughnut :data="budgetActualData" :options="budgetActualOptions" />
            </div>
            <div class="budget-list">
              <div v-for="b in budgetActual" :key="b.category" class="budget-row">
                <span class="budget-icon">{{ b.icon }}</span>
                <div class="budget-info">
                  <div class="budget-top-row">
                    <span class="budget-name">{{ b.category }}</span>
                    <span class="budget-status" :class="b.actual <= b.budget * 0.6 ? 'green' : b.actual <= b.budget * 0.85 ? 'accent' : 'red'">
                      {{ b.actual <= b.budget * 0.6 ? 'Under budget' : b.actual <= b.budget * 0.85 ? 'On track' : 'Watch spending' }}
                    </span>
                  </div>
                  <div class="budget-bar-track">
                    <div class="budget-bar-fill" :style="{ width: Math.min((b.actual / b.budget) * 100, 100) + '%', background: b.actual <= b.budget * 0.6 ? '#2e7d32' : b.actual <= b.budget * 0.85 ? '#D7F34A' : '#fb923c' }"></div>
                  </div>
                  <span class="budget-amts">₹{{ b.actual.toLocaleString() }} / ₹{{ b.budget.toLocaleString() }}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Top Expenses</h2>
          </div>
          <div class="expense-list">
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
      </div>

      <!-- Monthly Table -->
      <div class="card">
        <div class="card-header">
          <h2 class="card-title">Monthly Breakdown</h2>
        </div>
        <div class="table-wrap">
          <table class="table">
            <thead>
              <tr>
                <th>Month</th>
                <th>Income</th>
                <th>Expenses</th>
                <th>Saved</th>
                <th>Savings Rate</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="m in months" :key="m.name">
                <td class="td-name">{{ m.name }}</td>
                <td class="td-green">+₹{{ m.income.toLocaleString() }}</td>
                <td class="td-red">-₹{{ m.expenses.toLocaleString() }}</td>
                <td class="td-bold">₹{{ m.saved.toLocaleString() }}</td>
                <td>
                  <div class="rate-cell">
                    <div class="rate-bar-track">
                      <div class="rate-bar-fill" :style="{ width: Math.round(m.saved / m.income * 100) + '%' }"></div>
                    </div>
                    <span class="rate-pct">{{ Math.round(m.saved / m.income * 100) }}%</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
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
}

.range-tabs {
  display: flex;
  gap: 0.25rem;
  background: var(--color-surface);
  border-radius: var(--radius);
  padding: 0.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.range-tab {
  padding: 0.5rem 1rem;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.15s;
}

.range-tab:hover {
  color: var(--color-text);
}

.range-tab.active {
  background: var(--color-graphite);
  color: var(--color-surface);
  font-weight: 600;
}

.export-btns {
  display: flex;
  gap: 0.5rem;
}

.export-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
}

.export-btn:hover {
  transform: translateY(-1px);
}

.pdf-btn {
  color: #fff;
  background: #d32f2f;
}

.pdf-btn:hover {
  background: #b71c1c;
}

.excel-btn {
  color: #fff;
  background: #2e7d32;
}

.excel-btn:hover {
  background: #1b5e20;
}

/* ─── Key Metrics ─── */
.metrics-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}

.metric-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.125rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.metric-icon {
  width: 40px;
  height: 40px;
  border-radius: var(--radius);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.125rem;
  flex-shrink: 0;
}

.green-bg {
  background: rgba(46, 125, 50, 0.1);
}

.red-bg {
  background: rgba(211, 47, 47, 0.1);
}

.accent-bg {
  background: rgba(215, 243, 74, 0.2);
}

.metric-label {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.metric-value {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--color-text);
}

.metric-value.green {
  color: #2e7d32;
}

.metric-value.red {
  color: #d32f2f;
}

/* ─── Charts ─── */
.charts-row {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: 1.5rem;
}

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
  margin-bottom: 1.25rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.chart-tall {
  height: 260px;
}

/* ─── Budget vs Actual ─── */
.budget-grid {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.budget-chart-wrap {
  width: 170px;
  height: 170px;
  flex-shrink: 0;
  padding: 12px;
  margin: -12px;
}

.budget-list {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 0.875rem;
}

.budget-row {
  display: flex;
  align-items: flex-start;
  gap: 0.625rem;
}

.budget-icon {
  font-size: 1.125rem;
  width: 24px;
  text-align: center;
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.budget-info {
  flex: 1;
  min-width: 0;
}

.budget-top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.25rem;
}

.budget-name {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
}

.budget-status {
  font-size: 0.6875rem;
  font-weight: 500;
  padding: 0.125rem 0.5rem;
  border-radius: 999px;
}

.budget-status.green {
  color: #2e7d32;
  background: rgba(46, 125, 50, 0.1);
}

.budget-status.accent {
  color: #7a8a1e;
  background: rgba(215, 243, 74, 0.2);
}

.budget-status.red {
  color: #d32f2f;
  background: rgba(211, 47, 47, 0.1);
}

.budget-bar-track {
  height: 4px;
  background: var(--color-bg);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 0.25rem;
}

.budget-bar-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s ease;
}

.budget-amts {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
}

/* ─── Top Expenses ─── */
.expense-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.expense-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.exp-left {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.exp-rank {
  font-size: 0.75rem;
  font-weight: 600;
  color: var(--color-text-muted);
  width: 16px;
  text-align: center;
}

.exp-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  flex-shrink: 0;
}

.exp-name {
  font-size: 0.8125rem;
  color: var(--color-text);
}

.exp-right {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex: 1;
  max-width: 200px;
}

.exp-bar-track {
  flex: 1;
  height: 4px;
  background: var(--color-bg);
  border-radius: 2px;
  overflow: hidden;
}

.exp-bar-fill {
  height: 100%;
  border-radius: 2px;
  transition: width 0.3s ease;
}

.exp-amt {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
  min-width: 60px;
  text-align: right;
}

/* ─── Table ─── */
.table-wrap {
  overflow-x: auto;
}

.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.875rem;
}

.table th {
  text-align: left;
  padding: 0.75rem 1rem;
  font-weight: 500;
  color: var(--color-text-muted);
  border-bottom: 1px solid var(--color-bg);
  font-size: 0.8125rem;
}

.table td {
  padding: 0.875rem 1rem;
  border-bottom: 1px solid var(--color-bg);
}

.table tr:last-child td {
  border-bottom: none;
}

.td-name {
  font-weight: 500;
  color: var(--color-text);
}

.td-green {
  color: #2e7d32;
  font-weight: 500;
}

.td-red {
  color: #d32f2f;
  font-weight: 500;
}

.td-bold {
  font-weight: 600;
  color: var(--color-text);
}

.rate-cell {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.rate-bar-track {
  flex: 1;
  height: 4px;
  background: var(--color-bg);
  border-radius: 2px;
  overflow: hidden;
  max-width: 80px;
}

.rate-bar-fill {
  height: 100%;
  background: var(--color-accent);
  border-radius: 2px;
}

.rate-pct {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
  min-width: 32px;
}

.bottom-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}
</style>
