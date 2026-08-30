<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { jsPDF } from 'jspdf'
import autoTable from 'jspdf-autotable'
import * as XLSX from 'xlsx'
import { Bar, Line, Doughnut } from 'vue-chartjs'
import {
  Chart as ChartJS,
  ArcElement, Tooltip, Legend, CategoryScale, LinearScale,
  BarElement, PointElement, LineElement, Filler,
} from 'chart.js'
import { useFinance } from '@/composables/useFinance.js'

ChartJS.register(ArcElement, Tooltip, Legend, CategoryScale, LinearScale, BarElement, PointElement, LineElement, Filler)

const { loading, fetchAll, monthlyData, budgetData, topExpenses } = useFinance()

// Chart refs for capturing canvas images
const barChartRef = ref(null)
const lineChartRef = ref(null)
const doughnutChartRef = ref(null)

onMounted(() => { fetchAll() })

const selectedRange = ref('6m')

// Computed metrics from real data
const totalIncome = computed(() => monthlyData.value.reduce((s, m) => s + m.income, 0))
const totalExpenses = computed(() => monthlyData.value.reduce((s, m) => s + m.expenses, 0))
const totalSaved = computed(() => monthlyData.value.reduce((s, m) => s + m.saved, 0))
const avgIncome = computed(() => monthlyData.value.length ? Math.round(totalIncome.value / monthlyData.value.length) : 0)
const avgExpenses = computed(() => monthlyData.value.length ? Math.round(totalExpenses.value / monthlyData.value.length) : 0)
const avgSavingsRate = computed(() => totalIncome.value ? Math.round(totalSaved.value / totalIncome.value * 100) : 0)
const highestExpenseMonth = computed(() => [...monthlyData.value].sort((a, b) => b.expenses - a.expenses)[0])
const bestSavingsMonth = computed(() => [...monthlyData.value].sort((a, b) => (b.saved / (b.income || 1)) - (a.saved / (a.income || 1)))[0])

// Month names for display
const months = computed(() =>
  [...monthlyData.value].reverse().map(m => ({
    name: m.short + ' ' + m.key.split('-')[0],
    short: m.short,
    income: m.income,
    expenses: m.expenses,
    saved: m.saved,
  }))
)

// Charts
const chartTooltipStyle = {
  backgroundColor: '#202124',
  titleFont: { family: 'Inter', size: 12 },
  bodyFont: { family: 'Inter', size: 12 },
  padding: 10,
  cornerRadius: 8,
}

const reversedMonths = computed(() => [...months.value])

const barData = computed(() => ({
  labels: reversedMonths.value.map(m => m.short),
  datasets: [
    { label: 'Income', data: reversedMonths.value.map(m => m.income), backgroundColor: '#2e7d32', borderRadius: 4 },
    { label: 'Expenses', data: reversedMonths.value.map(m => m.expenses), backgroundColor: '#d32f2f', borderRadius: 4 },
  ],
}))

const barOptions = {
  responsive: true, maintainAspectRatio: false,
  plugins: {
    legend: { position: 'top', labels: { usePointStyle: true, pointStyle: 'circle', padding: 16, font: { family: 'Inter', size: 11 } } },
    tooltip: { ...chartTooltipStyle, callbacks: { label: (ctx) => ` ${ctx.dataset.label}: ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

const lineData = computed(() => ({
  labels: reversedMonths.value.map(m => m.short),
  datasets: [{
    label: 'Savings',
    data: reversedMonths.value.map(m => m.saved),
    borderColor: '#D7F34A',
    backgroundColor: 'rgba(215, 243, 74, 0.15)',
    fill: true, tension: 0.35, pointRadius: 5,
    pointBackgroundColor: '#D7F34A', pointBorderColor: '#fff', pointBorderWidth: 2,
  }],
}))

const lineOptions = {
  responsive: true, maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: { ...chartTooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.y.toLocaleString()}` } },
  },
  scales: {
    x: { grid: { display: false }, ticks: { font: { family: 'Inter', size: 11 } } },
    y: { grid: { color: 'rgba(0,0,0,0.04)' }, ticks: { font: { family: 'Inter', size: 11 }, callback: (v) => '₹' + (v / 1000) + 'k' } },
  },
}

// Budget vs Actual doughnut
const budgetActualData = computed(() => ({
  labels: budgetData.value.map(b => b.name),
  datasets: [{
    data: budgetData.value.map(b => Math.max(b.budget - b.spent, 0)),
    backgroundColor: budgetData.value.map(b => b.spent <= b.budget * 0.6 ? '#2e7d32' : b.spent <= b.budget * 0.85 ? '#D7F34A' : '#fb923c'),
    borderWidth: 0, hoverOffset: 4,
  }],
}))

const budgetActualOptions = {
  responsive: true, maintainAspectRatio: false, cutout: '65%',
  plugins: {
    legend: { display: false },
    tooltip: { ...chartTooltipStyle, callbacks: { label: (ctx) => ` ₹${ctx.parsed.toLocaleString()} remaining` } },
  },
}

// Get chart canvas as image data URL
function getChartImage(chartRef, width = 160, height = 100) {
  if (!chartRef.value) return null
  const canvas = chartRef.value.$el?.querySelector('canvas') || chartRef.value.chart?.canvas
  if (!canvas) return null
  // Create a scaled copy for better resolution
  const tmpCanvas = document.createElement('canvas')
  tmpCanvas.width = width * 2
  tmpCanvas.height = height * 2
  const ctx = tmpCanvas.getContext('2d')
  ctx.fillStyle = '#ffffff'
  ctx.fillRect(0, 0, tmpCanvas.width, tmpCanvas.height)
  ctx.drawImage(canvas, 0, 0, tmpCanvas.width, tmpCanvas.height)
  return tmpCanvas.toDataURL('image/png', 1.0)
}

// PDF Export with charts
function exportPDF() {
  const doc = new jsPDF('p', 'mm', 'a4')
  const pageWidth = 210
  const margin = 14
  const now = new Date()
  let y = 20

  // Header
  doc.setFontSize(22)
  doc.setFont('helvetica', 'bold')
  doc.text('Envelo Financial Report', margin, y)
  y += 8
  doc.setFontSize(10)
  doc.setFont('helvetica', 'normal')
  doc.setTextColor(120)
  doc.text('Generated on ' + now.toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }), margin, y)
  y += 4
  doc.setDrawColor(215, 243, 74)
  doc.setLineWidth(0.5)
  doc.line(margin, y, pageWidth - margin, y)
  y += 10

  // ── Income vs Expenses Chart ──
  const barImg = getChartImage(barChartRef, 180, 100)
  if (barImg) {
    doc.setFontSize(13)
    doc.setFont('helvetica', 'bold')
    doc.setTextColor(0)
    doc.text('Income vs Expenses', margin, y)
    y += 5
    doc.addImage(barImg, 'PNG', margin, y, 180, 90)
    y += 95
  }

  // ── Monthly Overview Table ──
  doc.setFontSize(13)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(0)
  doc.text('Monthly Overview', margin, y)
  y += 4

  autoTable(doc, {
    startY: y,
    head: [['Month', 'Income', 'Expenses', 'Saved', 'Rate']],
    body: months.value.map(m => [
      m.name, '₹' + m.income.toLocaleString(), '₹' + m.expenses.toLocaleString(),
      '₹' + m.saved.toLocaleString(), (m.income ? Math.round(m.saved / m.income * 100) : 0) + '%',
    ]),
    theme: 'grid', headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 }, alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: margin },
  })
  y = doc.lastAutoTable.finalY + 12

  // ── Savings Trend Chart ──
  const lineImg = getChartImage(lineChartRef, 180, 100)
  if (lineImg) {
    if (y > 180) { doc.addPage(); y = 20 }
    doc.setFontSize(13)
    doc.setFont('helvetica', 'bold')
    doc.setTextColor(0)
    doc.text('Savings Trend', margin, y)
    y += 5
    doc.addImage(lineImg, 'PNG', margin, y, 180, 90)
    y += 95
  }

  // ── Budget vs Actual ──
  if (budgetData.value.length > 0) {
    if (y > 160) { doc.addPage(); y = 20 }
    doc.setFontSize(13)
    doc.setFont('helvetica', 'bold')
    doc.setTextColor(0)
    doc.text('Budget vs Actual', margin, y)
    y += 4

    autoTable(doc, {
      startY: y,
      head: [['Category', 'Budget', 'Actual', 'Remaining', 'Status']],
      body: budgetData.value.map(b => [
        b.icon + ' ' + b.name, '₹' + b.budget.toLocaleString(), '₹' + b.spent.toLocaleString(),
        '₹' + Math.max(b.budget - b.spent, 0).toLocaleString(),
        b.spent <= b.budget * 0.6 ? 'Under budget' : b.spent <= b.budget * 0.85 ? 'On track' : 'Watch spending',
      ]),
      theme: 'grid', headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
      bodyStyles: { fontSize: 9 }, alternateRowStyles: { fillColor: [245, 245, 240] },
      margin: { left: margin },
    })
    y = doc.lastAutoTable.finalY + 8

    // Doughnut chart next to or below the table
    const doughnutImg = getChartImage(doughnutChartRef, 90, 90)
    if (doughnutImg) {
      if (y > 180) { doc.addPage(); y = 20 }
      doc.addImage(doughnutImg, 'PNG', margin, y, 80, 80)
      y += 85
    }
  }

  // ── Top Expenses ──
  if (topExpenses.value.length > 0) {
    if (y > 200) { doc.addPage(); y = 20 }
    doc.setFontSize(13)
    doc.setFont('helvetica', 'bold')
    doc.setTextColor(0)
    doc.text('Top Expenses This Month', margin, y)
    y += 4

    autoTable(doc, {
      startY: y,
      head: [['Category', 'Amount', '% of Total']],
      body: topExpenses.value.map(e => [e.name, '₹' + e.amount.toLocaleString(), e.pct + '%']),
      theme: 'grid', headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
      bodyStyles: { fontSize: 9 }, alternateRowStyles: { fillColor: [245, 245, 240] },
      margin: { left: margin },
    })
    y = doc.lastAutoTable.finalY + 12
  }

  // ── Key Metrics ──
  if (y > 200) { doc.addPage(); y = 20 }
  doc.setFontSize(13)
  doc.setFont('helvetica', 'bold')
  doc.setTextColor(0)
  doc.text('Key Metrics', margin, y)
  y += 4

  autoTable(doc, {
    startY: y,
    head: [['Metric', 'Value']],
    body: [
      ['Average Monthly Income', '₹' + avgIncome.value.toLocaleString()],
      ['Average Monthly Expense', '₹' + avgExpenses.value.toLocaleString()],
      ['Average Savings Rate', avgSavingsRate.value + '%'],
      ['Total Saved', '₹' + totalSaved.value.toLocaleString()],
      highestExpenseMonth.value ? ['Highest Expense Month', highestExpenseMonth.value.short + ' ' + highestExpenseMonth.value.key.split('-')[0]] : null,
      bestSavingsMonth.value ? ['Best Savings Month', bestSavingsMonth.value.short + ' ' + bestSavingsMonth.value.key.split('-')[0]] : null,
    ].filter(Boolean),
    theme: 'grid', headStyles: { fillColor: [32, 33, 36], fontSize: 9 },
    bodyStyles: { fontSize: 9 }, alternateRowStyles: { fillColor: [245, 245, 240] },
    margin: { left: margin },
  })

  doc.save('Envelo_Financial_Report.pdf')
}

// Excel Export
function exportExcel() {
  const wb = XLSX.utils.book_new()

  const ws1 = XLSX.utils.json_to_sheet(months.value.map(m => ({
    Month: m.name, Income: m.income, Expenses: m.expenses, Saved: m.saved,
    'Savings Rate (%)': m.income ? Math.round(m.saved / m.income * 100) : 0,
  })))
  ws1['!cols'] = [{ wch: 18 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }]
  XLSX.utils.book_append_sheet(wb, ws1, 'Monthly Overview')

  if (budgetData.value.length > 0) {
    const ws2 = XLSX.utils.json_to_sheet(budgetData.value.map(b => ({
      Category: b.name, Budget: b.budget, Actual: b.spent,
      Remaining: Math.max(b.budget - b.spent, 0),
      Status: b.spent <= b.budget * 0.6 ? 'Under budget' : b.spent <= b.budget * 0.85 ? 'On track' : 'Watch spending',
    })))
    ws2['!cols'] = [{ wch: 16 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 16 }]
    XLSX.utils.book_append_sheet(wb, ws2, 'Budget vs Actual')
  }

  if (topExpenses.value.length > 0) {
    const ws3 = XLSX.utils.json_to_sheet(topExpenses.value.map(e => ({
      Category: e.name, Amount: e.amount, '% of Total': e.pct,
    })))
    ws3['!cols'] = [{ wch: 18 }, { wch: 14 }, { wch: 12 }]
    XLSX.utils.book_append_sheet(wb, ws3, 'Top Expenses')
  }

  const ws4 = XLSX.utils.json_to_sheet([
    { Metric: 'Average Monthly Income', Value: '₹' + avgIncome.value.toLocaleString() },
    { Metric: 'Average Monthly Expense', Value: '₹' + avgExpenses.value.toLocaleString() },
    { Metric: 'Average Savings Rate', Value: avgSavingsRate.value + '%' },
    { Metric: 'Total Saved', Value: '₹' + totalSaved.value.toLocaleString() },
    highestExpenseMonth.value ? { Metric: 'Highest Expense Month', Value: highestExpenseMonth.value.short } : null,
    bestSavingsMonth.value ? { Metric: 'Best Savings Month', Value: bestSavingsMonth.value.short } : null,
  ].filter(Boolean))
  ws4['!cols'] = [{ wch: 30 }, { wch: 22 }]
  XLSX.utils.book_append_sheet(wb, ws4, 'Key Metrics')

  // Add chart images to Excel if possible
  try {
    const barImg = getChartImage(barChartRef, 800, 400)
    if (barImg) {
      const ws5 = XLSX.utils.aoa_to_sheet([['Income vs Expenses Chart'], ['']])
      ws5['!images'] = [{ name: 'chart', data: barImg.split(',')[1], x: 0, y: 0, w: 600, h: 300 }]
      XLSX.utils.book_append_sheet(wb, ws5, 'Charts')
    }
  } catch { /* image embedding not supported in all xlsx builds */ }

  XLSX.writeFile(wb, 'Envelo_Financial_Report.xlsx')
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Loading -->
      <div v-if="loading" class="loading-page">
        <span class="spinner-lg"></span>
        <p>Loading reports...</p>
      </div>

      <template v-else>
        <div class="page-header">
          <div></div>
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

        <!-- Empty -->
        <div v-if="monthlyData.length === 0" class="empty-state card">
          <div class="empty-icon">📄</div>
          <h3>No data yet</h3>
          <p>Add transactions to generate reports!</p>
        </div>

        <template v-else>
          <!-- Charts Row -->
          <div class="charts-row">
            <div class="card chart-card-wide">
              <div class="card-header">
                <h2 class="card-title">Income vs Expenses</h2>
              </div>
              <div class="chart-tall">
                <Bar ref="barChartRef" :data="barData" :options="barOptions" />
              </div>
            </div>
            <div class="card chart-card-narrow">
              <div class="card-header">
                <h2 class="card-title">Savings Trend</h2>
              </div>
              <div class="chart-tall">
                <Line ref="lineChartRef" :data="lineData" :options="lineOptions" />
              </div>
            </div>
          </div>

          <!-- Budget + Top Expenses -->
          <div class="bottom-grid">
            <div class="card" v-if="budgetData.length > 0">
              <div class="card-header">
                <h2 class="card-title">Budget vs Actual</h2>
              </div>
              <div class="budget-grid">
                <div class="budget-chart-wrap">
                  <Doughnut ref="doughnutChartRef" :data="budgetActualData" :options="budgetActualOptions" />
                </div>
                <div class="budget-list">
                  <div v-for="b in budgetData" :key="b.id" class="budget-row">
                    <span class="budget-icon">{{ b.icon }}</span>
                    <div class="budget-info">
                      <div class="budget-top-row">
                        <span class="budget-name">{{ b.name }}</span>
                        <span class="budget-status" :class="b.spent <= b.budget * 0.6 ? 'green' : b.spent <= b.budget * 0.85 ? 'accent' : 'red'">
                          {{ b.spent <= b.budget * 0.6 ? 'Under budget' : b.spent <= b.budget * 0.85 ? 'On track' : 'Watch spending' }}
                        </span>
                      </div>
                      <div class="budget-bar-track">
                        <div class="budget-bar-fill" :style="{ width: Math.min((b.spent / b.budget) * 100, 100) + '%', background: b.spent <= b.budget * 0.6 ? '#2e7d32' : b.spent <= b.budget * 0.85 ? '#D7F34A' : '#fb923c' }"></div>
                      </div>
                      <span class="budget-amts">₹{{ b.spent.toLocaleString() }} / ₹{{ b.budget.toLocaleString() }}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="card">
              <div class="card-header">
                <h2 class="card-title">Top Expenses</h2>
              </div>
              <div v-if="topExpenses.length === 0" class="empty-state">
                <p>No expenses this month</p>
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
                          <div class="rate-bar-fill" :style="{ width: (m.income ? Math.round(m.saved / m.income * 100) : 0) + '%' }"></div>
                        </div>
                        <span class="rate-pct">{{ m.income ? Math.round(m.saved / m.income * 100) : 0 }}%</span>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
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

.empty-state { text-align: center; padding: 3rem 1rem; color: var(--color-text-muted); }
.empty-icon { font-size: 2.5rem; margin-bottom: 0.5rem; }
.empty-state h3 { font-size: 1rem; font-weight: 600; color: var(--color-text); margin-bottom: 0.25rem; }
.empty-state p { font-size: 0.8125rem; }

.page-header { display: flex; align-items: center; justify-content: space-between; }

.export-btns { display: flex; gap: 0.5rem; }

.export-btn {
  padding: 0.625rem 1.25rem; font-size: 0.875rem; font-weight: 600;
  font-family: var(--font-sans); border: none; border-radius: var(--radius);
  cursor: pointer; transition: background 0.2s, transform 0.15s;
}

.export-btn:hover { transform: translateY(-1px); }
.pdf-btn { color: #fff; background: #d32f2f; }
.pdf-btn:hover { background: #b71c1c; }
.excel-btn { color: #fff; background: #2e7d32; }
.excel-btn:hover { background: #1b5e20; }

.metrics-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }

.metric-card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.125rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  display: flex; align-items: center; gap: 0.875rem;
}

.metric-icon {
  width: 40px; height: 40px; border-radius: var(--radius);
  display: flex; align-items: center; justify-content: center;
  font-size: 1.125rem; flex-shrink: 0;
}

.green-bg { background: rgba(46, 125, 50, 0.1); }
.red-bg { background: rgba(211, 47, 47, 0.1); }
.accent-bg { background: rgba(215, 243, 74, 0.2); }

.metric-label { font-size: 0.75rem; color: var(--color-text-muted); }
.metric-value { font-size: 1.125rem; font-weight: 700; color: var(--color-text); }
.metric-value.green { color: #2e7d32; }
.metric-value.red { color: #d32f2f; }

.charts-row { display: grid; grid-template-columns: 1.5fr 1fr; gap: 1.5rem; }

.card {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
.card-title { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.chart-tall { height: 260px; }

.budget-grid { display: flex; align-items: center; gap: 1.5rem; }

.budget-chart-wrap {
  width: 170px; height: 170px; flex-shrink: 0; padding: 12px; margin: -12px;
}

.budget-list { flex: 1; display: flex; flex-direction: column; gap: 0.875rem; }
.budget-row { display: flex; align-items: flex-start; gap: 0.625rem; }
.budget-icon { font-size: 1.125rem; width: 24px; text-align: center; flex-shrink: 0; margin-top: 0.125rem; }
.budget-info { flex: 1; min-width: 0; }
.budget-top-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.25rem; }
.budget-name { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }

.budget-status { font-size: 0.6875rem; font-weight: 500; padding: 0.125rem 0.5rem; border-radius: 999px; }
.budget-status.green { color: #2e7d32; background: rgba(46, 125, 50, 0.1); }
.budget-status.accent { color: #7a8a1e; background: rgba(215, 243, 74, 0.2); }
.budget-status.red { color: #d32f2f; background: rgba(211, 47, 47, 0.1); }

.budget-bar-track { height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; margin-bottom: 0.25rem; }
.budget-bar-fill { height: 100%; border-radius: 2px; transition: width 0.3s ease; }
.budget-amts { font-size: 0.6875rem; color: var(--color-text-muted); }

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

.table-wrap { overflow-x: auto; }

.table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
.table th { text-align: left; padding: 0.75rem 1rem; font-weight: 500; color: var(--color-text-muted); border-bottom: 1px solid var(--color-bg); font-size: 0.8125rem; }
.table td { padding: 0.875rem 1rem; border-bottom: 1px solid var(--color-bg); }
.table tr:last-child td { border-bottom: none; }
.td-name { font-weight: 500; color: var(--color-text); }
.td-green { color: #2e7d32; font-weight: 500; }
.td-red { color: #d32f2f; font-weight: 500; }
.td-bold { font-weight: 600; color: var(--color-text); }

.rate-cell { display: flex; align-items: center; gap: 0.75rem; }
.rate-bar-track { flex: 1; height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; max-width: 80px; }
.rate-bar-fill { height: 100%; background: var(--color-accent); border-radius: 2px; }
.rate-pct { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); min-width: 32px; }

.bottom-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }
</style>
