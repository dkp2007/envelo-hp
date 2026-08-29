<script setup>
import { ref, computed, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { groq } from '@/lib/groq'
import { supabase } from '@/lib/supabase.js'
import { useFinance } from '@/composables/useFinance.js'
import { useAuthStore } from '@/stores/auth.js'

const auth = useAuthStore()
const { loading: financeLoading, fetchAll, monthIncome, monthExpenses, monthSavings, budgetData, savingsGoals } = useFinance()

onMounted(async () => {
  await fetchAll()
  // Populate from real data
  if (monthIncome.value > 0) {
    snapshotIncome.value = monthIncome.value
    snapshotExpenses.value = monthExpenses.value
  }
  if (budgetData.value.length > 0) {
    budgets.value = budgetData.value.map(b => ({
      name: b.name, icon: b.icon, amount: b.spent || 0, essential: ['Rent', 'Food', 'Utilities'].includes(b.name),
    }))
  } else {
    // Fallback: use spending by category
    const { spendingByCategory } = useFinance()
    if (spendingByCategory.value.length > 0) {
      budgets.value = spendingByCategory.value.map(c => ({
        name: c.name, icon: c.icon, amount: c.spent || 0, essential: ['Rent', 'Food', 'Utilities'].includes(c.name),
      }))
    }
  }
  const totalSaved = savingsGoals.value.reduce((s, g) => s + Number(g.current), 0)
  snapshotSavings.value = totalSaved
  initScenarios()
  fetchHistory()
})

// ── Financial Snapshot (start at 0, populated from DB) ──
const snapshotIncome = ref(0)
const snapshotExpenses = ref(0)
const snapshotSavings = ref(0)

const surplus = computed(() => snapshotIncome.value - snapshotExpenses.value)
const savingsRate = computed(() => snapshotIncome.value ? Math.round((surplus.value / snapshotIncome.value) * 100) : 0)
const emergencyFund = computed(() => snapshotExpenses.value * 3)
const emergencyMonths = computed(() => snapshotExpenses.value ? Math.floor(snapshotSavings.value / snapshotExpenses.value) : 0)

// ── Budget Breakdown (populated from DB) ──
const budgets = ref([])

// ── Scenarios (populated from real income after data loads) ──
const scenarios = ref([])

function initScenarios() {
  const inc = snapshotIncome.value || 30000
  scenarios.value = [
    { id: 'medical', title: 'Unexpected Medical Expense', icon: '🏥', description: 'A sudden medical bill pops up this month.', impact: 5000, type: 'expense', color: '#d32f2f', min: 1000, max: Math.max(50000, inc), step: 1000, tip: 'Use your emergency fund. If short, negotiate a payment plan with the hospital.' },
    { id: 'income-cut', title: 'Income Reduction', icon: '📉', description: 'Your monthly income drops for the next 3 months.', impact: Math.round(inc * 0.1), type: 'income', color: '#fb923c', min: 1000, max: inc, step: 500, tip: 'Immediately cut non-essential spending (Fun, Subscriptions, Transport). Pause savings contributions temporarily.' },
    { id: 'emergency', title: 'Major Emergency Expense', icon: '🚨', description: 'A large emergency hits — car repair, home damage, etc.', impact: 15000, type: 'expense', color: '#e91e63', min: 5000, max: Math.max(100000, inc * 2), step: 1000, tip: 'Prioritize essentials only. Reduce Food budget by ordering less, pause Fun and Subscriptions entirely.' },
    { id: 'big-purchase', title: 'Major One-Time Purchase', icon: '🛒', description: 'You need a big purchase — laptop, furniture, appliance.', impact: 25000, type: 'expense', color: '#9c27b0', min: 5000, max: Math.max(200000, inc * 3), step: 1000, tip: 'Spread across 2-3 months by reducing non-essentials. Consider EMI if interest-free option is available.' },
    { id: 'job-loss', title: 'Job Loss (2 Months)', icon: '💼', description: 'You lose your job and are unemployed for 2 months.', impact: inc * 2, type: 'income', color: '#202124', min: Math.round(inc * 0.5), max: inc * 4, step: Math.round(inc * 0.05), tip: 'Cut all non-essential spending immediately. Cancel subscriptions. Start job hunting aggressively.' },
    { id: 'rent-hike', title: 'Rent Increase', icon: '🏠', description: 'Your landlord increases rent by a percentage.', impact: 3000, type: 'expense', color: '#ff9800', min: 500, max: Math.max(15000, Math.round(inc * 0.3)), step: 500, tip: 'Negotiate with your landlord. If not possible, offset by reducing other categories.' },
  ]
}

// ── Results ──
const results = computed(() => {
  const nonEssential = budgets.value.filter(b => !b.essential).reduce((s, b) => s + b.amount, 0)
  return scenarios.value.map(s => {
    let surviving, recoveryMonths, canAbsorb
    if (s.type === 'income') {
      const newSurplus = (snapshotIncome.value - s.impact) - snapshotExpenses.value
      surviving = newSurplus >= 0 || snapshotSavings.value >= s.impact * 3
      recoveryMonths = newSurplus >= 0 ? 0 : Math.ceil(s.impact * 3 / Math.max(nonEssential, 1))
      canAbsorb = snapshotSavings.value >= s.impact * 3
    } else {
      surviving = surplus.value >= s.impact || snapshotSavings.value >= s.impact
      recoveryMonths = surplus.value >= s.impact ? 0 : Math.ceil(s.impact / Math.max(surplus.value, 1))
      canAbsorb = snapshotSavings.value >= s.impact
    }
    const coveragePercent = s.type === 'income'
      ? (snapshotSavings.value >= s.impact * 3 ? 100 : Math.min(Math.round((snapshotSavings.value / (s.impact * 3)) * 100), 99))
      : (snapshotSavings.value >= s.impact ? 100 : Math.min(Math.round((snapshotSavings.value / s.impact) * 100), 99))
    const severity = s.impact > snapshotIncome.value * 0.5 ? 'critical' : s.impact > snapshotIncome.value * 0.2 ? 'high' : s.impact > snapshotIncome.value * 0.1 ? 'medium' : 'low'
    return { ...s, surviving, recoveryMonths, canAbsorb, coveragePercent, severity }
  })
})

const passedCount = computed(() => results.value.filter(r => r.surviving).length)
const totalCount = computed(() => results.value.length)
const scorePercent = computed(() => Math.round((passedCount.value / totalCount.value) * 100))
const scoreColor = computed(() => scorePercent.value >= 80 ? '#2e7d32' : scorePercent.value >= 50 ? '#fb923c' : '#d32f2f')

// ── UI State ──
const testRan = ref(false)
const running = ref(false)
const aiAnalysis = ref('')
const aiLoading = ref(false)
const aiError = ref('')
const activeScenario = ref(null)
const savingResult = ref(false)

// ── History ──
const history = ref([])
const historyLoading = ref(false)

async function fetchHistory() {
  if (!auth.user) return
  historyLoading.value = true
  const { data } = await supabase
    .from('stress_test_results')
    .select('*')
    .eq('user_id', auth.user.id)
    .order('created_at', { ascending: false })
    .limit(10)
  history.value = data || []
  historyLoading.value = false
}

async function runTest() {
  running.value = true
  aiAnalysis.value = ''
  aiError.value = ''
  activeScenario.value = null
  await new Promise(r => setTimeout(r, 1200))
  running.value = false
  testRan.value = true

  // Save result to DB
  saveResult()

  // AI analysis
  aiLoading.value = true
  const budgetBreakdown = budgets.value.map(b => `${b.name}: ₹${b.amount.toLocaleString()}${b.essential ? ' (essential)' : ' (non-essential)'}`).join(', ')
  const scenarioResults = results.value.map(r => `${r.title}: ${r.surviving ? 'SURVIVED' : 'FAILED'} — Impact: ₹${r.impact.toLocaleString()}${r.type === 'income' ? '/mo' : ''}, Covered: ${r.canAbsorb ? 'Yes' : 'No'}, Severity: ${r.severity}`).join('\n')

  try {
    const res = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [
        {
          role: 'system',
          content: `You are a personal finance advisor for Envelo. The user ran a budget stress test. Analyze their results and give personalized, actionable advice. Use INR. No markdown. Under 500 words.\n\nFormat:\n1. VERDICT — 2-sentence assessment\n2. SCENARIO BREAKDOWN — why each failed/passed with specific numbers\n3. RECOVERY PLAN — month-by-month for failed scenarios\n4. EMERGENCY FUND GAP — current vs recommended, monthly savings needed\n5. TOP 3 PRIORITIES — 3 things to do THIS WEEK\n6. MONTHLY BUDGET SUGGESTIONS — specific rupee amounts per category\n\nBe extremely specific with actual numbers.`,
        },
        {
          role: 'user',
          content: `Stress test results:\n\nSNAPSHOT:\n- Monthly Income: ₹${snapshotIncome.value.toLocaleString()}\n- Monthly Expenses: ₹${snapshotExpenses.value.toLocaleString()}\n- Monthly Surplus: ₹${surplus.value.toLocaleString()}\n- Current Savings: ₹${snapshotSavings.value.toLocaleString()}\n- Months covered: ${emergencyMonths.value}\n- Savings Rate: ${savingsRate.value}%\n\nBUDGET: ${budgetBreakdown}\n\nRESULTS:\n${scenarioResults}\n\nScore: ${passedCount.value}/${totalCount.value} | Emergency fund needed: ₹${emergencyFund.value.toLocaleString()}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1500,
    })
    aiAnalysis.value = res.choices[0]?.message?.content || ''
    // Update saved result with AI analysis
    if (history.value.length > 0) {
      await supabase.from('stress_test_results')
        .update({ ai_analysis: aiAnalysis.value })
        .eq('id', history.value[0].id)
    }
  } catch {
    aiError.value = 'Could not generate AI analysis. Showing basic tips instead.'
  } finally {
    aiLoading.value = false
  }
}

async function saveResult() {
  if (!auth.user) return
  savingResult.value = true
  const { data } = await supabase.from('stress_test_results').insert({
    user_id: auth.user.id,
    monthly_income: snapshotIncome.value,
    monthly_expenses: snapshotExpenses.value,
    current_savings: snapshotSavings.value,
    score: scorePercent.value,
    total_scenarios: totalCount.value,
    passed_scenarios: passedCount.value,
    scenario_results: JSON.parse(JSON.stringify(results.value)),
  }).select().single()
  if (data) history.value.unshift(data)
  savingResult.value = false
}

async function deleteHistoryItem(id) {
  await supabase.from('stress_test_results').delete().eq('id', id)
  history.value = history.value.filter(h => h.id !== id)
}

function loadFromHistory(item) {
  snapshotIncome.value = Number(item.monthly_income)
  snapshotExpenses.value = Number(item.monthly_expenses)
  snapshotSavings.value = Number(item.current_savings)
  if (item.scenario_results) {
    const saved = item.scenario_results
    scenarios.value.forEach(s => {
      const match = saved.find(r => r.id === s.id)
      if (match) s.impact = match.impact
    })
  }
  if (item.ai_analysis) aiAnalysis.value = item.ai_analysis
  testRan.value = true
}

function resetTest() {
  testRan.value = false
  aiAnalysis.value = ''
  aiError.value = ''
  activeScenario.value = null
}

function toggleScenario(id) {
  activeScenario.value = activeScenario.value === id ? null : id
}

function parseAiSections(text) {
  const lines = text.split('\n')
  const sections = []
  let current = null
  for (const line of lines) {
    const trimmed = line.trim()
    const headingMatch = trimmed.match(/^(?:\d+[.)\s]*\s*)?[A-Z][A-Z &']{2,}$/)
    if (headingMatch) {
      if (current) sections.push(current)
      current = { title: trimmed.replace(/^[\d.)\s]+/, '').trim(), body: '' }
    } else if (current) {
      current.body += (current.body ? '\n' : '') + trimmed
    } else if (trimmed) {
      current = { title: 'Overview', body: trimmed }
    }
  }
  if (current) sections.push(current)
  return sections.length ? sections : [{ title: 'Analysis', body: text }]
}

function formatAiText(text) {
  return text.replace(/\n/g, '<br>').replace(/(₹[\d,]+\.?\d*)/g, '<strong>$1</strong>')
}

function shareResults() {
  const text = `🛡️ My Envelo Budget Stress Test Results\n\nScore: ${passedCount.value}/${totalCount.value} scenarios survived\nSavings Rate: ${savingsRate.value}%\nEmergency Fund: ₹${emergencyFund.value.toLocaleString()} recommended\n\n${results.value.map(r => `${r.icon} ${r.title}: ${r.surviving ? '✓ Survived' : '✗ Failed'} (${r.coveragePercent}% covered)`).join('\n')}\n\nTest yours at envelo.netlify.app`
  navigator.clipboard.writeText(text).catch(() => {})
}

function formatDate(d) {
  return new Date(d).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })
}
</script>

<template>
  <DashboardLayout>
    <div class="page">

      <!-- Intro -->
      <div class="intro-banner">
        <div class="intro-left">
          <span class="intro-icon">🛡️</span>
          <div>
            <h2 class="intro-title">Budget Stress Test</h2>
            <p class="intro-desc">How resilient is your budget? Adjust numbers, simulate shocks, find out where you stand.</p>
          </div>
        </div>
        <div class="intro-actions">
          <button v-if="testRan" class="share-btn" @click="shareResults">📋 Share</button>
          <button v-if="testRan" class="reset-btn" @click="resetTest">↺ Reset</button>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="financeLoading" class="loading-page">
        <span class="spinner-lg"></span>
        <p>Loading your financial data...</p>
      </div>

      <template v-else>
        <!-- Snapshot -->
        <div class="snapshot-grid">
          <div class="card snap-card">
            <p class="snap-label">Monthly Income</p>
            <p class="snap-value green">₹{{ snapshotIncome.toLocaleString() }}</p>
            <input v-model.number="snapshotIncome" type="range" class="slider" min="10000" max="200000" step="1000" />
          </div>
          <div class="card snap-card">
            <p class="snap-label">Monthly Expenses</p>
            <p class="snap-value red">₹{{ snapshotExpenses.toLocaleString() }}</p>
            <input v-model.number="snapshotExpenses" type="range" class="slider" min="5000" max="200000" step="1000" />
          </div>
          <div class="card snap-card">
            <p class="snap-label">Current Savings</p>
            <p class="snap-value">₹{{ snapshotSavings.toLocaleString() }}</p>
            <input v-model.number="snapshotSavings" type="range" class="slider" min="0" max="500000" step="5000" />
          </div>
          <div class="card snap-card">
            <p class="snap-label">Monthly Surplus</p>
            <p class="snap-value" :class="surplus >= 0 ? 'green' : 'red'">₹{{ surplus.toLocaleString() }}</p>
            <p class="snap-hint">{{ savingsRate }}% savings rate</p>
          </div>
        </div>

        <!-- Budget Breakdown -->
        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Budget Breakdown</h2>
            <p class="card-subtotal">Total: ₹{{ budgets.reduce((s, b) => s + b.amount, 0).toLocaleString() }}</p>
          </div>
          <div class="budget-list">
            <div v-for="b in budgets" :key="b.name" class="budget-row">
              <div class="budget-left">
                <span class="budget-icon">{{ b.icon }}</span>
                <div class="budget-info">
                  <div class="budget-top">
                    <span class="budget-name">{{ b.name }}</span>
                    <span v-if="b.essential" class="essential-badge">Essential</span>
                    <span v-else class="optional-badge">Optional</span>
                  </div>
                  <div class="budget-bar-track">
                    <div class="budget-bar-fill" :style="{ width: Math.min((b.amount / snapshotIncome) * 100, 100) + '%' }"></div>
                  </div>
                </div>
              </div>
              <div class="budget-right">
                <span class="budget-amt">₹{{ b.amount.toLocaleString() }}</span>
                <input v-model.number="b.amount" type="range" class="slider-sm" min="0" max="30000" step="500" />
              </div>
            </div>
          </div>
        </div>

        <!-- Scenarios -->
        <div class="card">
          <div class="card-header">
            <h2 class="card-title">Stress Scenarios</h2>
            <p class="card-subtitle">Drag sliders to adjust impact</p>
          </div>
          <div class="scenario-grid">
            <div v-for="s in scenarios" :key="s.id" class="scenario-card">
              <div class="sa-top">
                <span class="sa-icon">{{ s.icon }}</span>
                <div class="sa-info">
                  <p class="sa-title">{{ s.title }}</p>
                  <p class="sa-desc">{{ s.description }}</p>
                </div>
                <div class="sa-badge" :style="{ background: s.color + '18', color: s.color }">
                  -₹{{ s.impact.toLocaleString() }}{{ s.type === 'income' ? '/mo' : '' }}
                </div>
              </div>
              <input v-model.number="s.impact" type="range" class="slider-scenario" :min="s.min" :max="s.max" :step="s.step" :style="{ '--accent': s.color }" />
              <div class="sa-range"><span>₹{{ s.min.toLocaleString() }}</span><span>₹{{ s.max.toLocaleString() }}</span></div>
            </div>
          </div>
        </div>

        <!-- Run -->
        <div class="run-section">
          <button class="run-btn" :disabled="running" @click="runTest">
            <span v-if="running" class="spinner-sm"></span>
            <span v-else>⚡</span>
            {{ running ? 'Running Stress Test...' : 'Run Stress Test' }}
          </button>
        </div>

        <!-- Results -->
        <div v-if="testRan" class="results-section">
          <!-- Score + Stats -->
          <div class="results-top-row">
            <div class="score-card card">
              <div class="score-ring-wrap">
                <svg class="score-ring" viewBox="0 0 120 120">
                  <circle cx="60" cy="60" r="52" fill="none" stroke="var(--color-bg)" stroke-width="10" />
                  <circle cx="60" cy="60" r="52" fill="none" :stroke="scoreColor" stroke-width="10" stroke-linecap="round" :stroke-dasharray="326.7" :stroke-dashoffset="326.7 - (326.7 * scorePercent / 100)" transform="rotate(-90 60 60)" class="score-arc" />
                </svg>
                <div class="score-center">
                  <span class="score-num" :style="{ color: scoreColor }">{{ passedCount }}/{{ totalCount }}</span>
                  <span class="score-label">Passed</span>
                </div>
              </div>
              <div class="score-info">
                <h3 class="score-title" :style="{ color: scoreColor }">
                  {{ scorePercent >= 80 ? 'Your budget is resilient! 💪' : scorePercent >= 50 ? 'Moderately resilient 🟡' : 'Your budget needs work 🔴' }}
                </h3>
                <p class="score-desc">Your budget survives <strong>{{ passedCount }} out of {{ totalCount }}</strong> stress scenarios. You have <strong>{{ emergencyMonths }} months</strong> of expenses covered.</p>
              </div>
            </div>
            <div class="quick-stats card">
              <div class="qs-item"><span class="qs-icon">🏦</span><div><p class="qs-label">Emergency Fund</p><p class="qs-value">₹{{ emergencyFund.toLocaleString() }}</p><p class="qs-sub" :class="snapshotSavings >= emergencyFund ? 'green' : 'red'">{{ snapshotSavings >= emergencyFund ? '✓ Funded' : '₹' + (emergencyFund - snapshotSavings).toLocaleString() + ' gap' }}</p></div></div>
              <div class="qs-item"><span class="qs-icon">📊</span><div><p class="qs-label">Savings Rate</p><p class="qs-value" :class="savingsRate >= 20 ? 'green' : savingsRate >= 10 ? 'accent' : 'red'">{{ savingsRate }}%</p><p class="qs-sub">{{ savingsRate >= 20 ? '✓ Healthy' : 'Could improve' }}</p></div></div>
              <div class="qs-item"><span class="qs-icon">🛡️</span><div><p class="qs-label">Months Covered</p><p class="qs-value">{{ emergencyMonths }}</p><p class="qs-sub">{{ emergencyMonths >= 3 ? '✓ 3+ months' : 'Below 3-month target' }}</p></div></div>
            </div>
          </div>

          <!-- Scenario Results -->
          <div class="scenario-results">
            <div v-for="r in results" :key="r.id" class="sr-card card" :class="{ passed: r.surviving, failed: !r.surviving }" @click="toggleScenario(r.id)">
              <div class="sr-top">
                <div class="sr-left"><span class="sr-icon">{{ r.icon }}</span><div><h3 class="sr-title">{{ r.title }}</h3><p class="sr-desc">{{ r.description }}</p></div></div>
                <span v-if="r.surviving" class="sr-badge pass">✓ Survived</span>
                <span v-else class="sr-badge fail">✗ Failed</span>
              </div>
              <div class="sr-bar"><div class="sr-bar-track"><div class="sr-bar-fill" :style="{ width: r.coveragePercent + '%', background: r.surviving ? '#2e7d32' : '#d32f2f' }"></div></div><span class="sr-bar-pct">{{ r.coveragePercent }}%</span></div>
              <div v-if="activeScenario === r.id" class="sr-details" @click.stop>
                <div class="sr-stats-row">
                  <div class="sr-stat"><span class="sr-stat-label">Impact</span><span class="sr-stat-value red">₹{{ r.impact.toLocaleString() }}{{ r.type === 'income' ? '/mo' : '' }}</span></div>
                  <div class="sr-stat"><span class="sr-stat-label">Severity</span><span class="sr-stat-value" :class="r.severity">{{ r.severity }}</span></div>
                  <div v-if="r.recoveryMonths > 0" class="sr-stat"><span class="sr-stat-label">Recovery</span><span class="sr-stat-value">{{ r.recoveryMonths }}mo</span></div>
                  <div class="sr-stat"><span class="sr-stat-label">Savings Cover</span><span class="sr-stat-value" :class="r.canAbsorb ? 'green' : 'red'">{{ r.canAbsorb ? 'Yes ✓' : 'No ✗' }}</span></div>
                </div>
                <div class="sr-tip"><span>💡</span><p>{{ r.tip }}</p></div>
              </div>
            </div>
          </div>

          <!-- AI Analysis -->
          <div class="card ai-card">
            <div class="ai-header"><h2 class="card-title">🤖 AI Resilience Analysis</h2><span v-if="aiLoading" class="ai-badge">Generating...</span></div>
            <div v-if="aiLoading" class="ai-loading"><div class="spinner"></div><p>Analyzing your results...</p></div>
            <div v-else-if="aiAnalysis" class="ai-content">
              <div v-for="(section, i) in parseAiSections(aiAnalysis)" :key="i" class="ai-section">
                <h3 class="ai-section-title">{{ section.title }}</h3>
                <p class="ai-section-text" v-html="formatAiText(section.body)"></p>
              </div>
            </div>
            <div v-else class="tips-list">
              <p v-if="aiError" class="ai-fallback">{{ aiError }}</p>
              <div v-if="snapshotSavings < emergencyFund" class="tip-row"><span>🏦</span><p>Build emergency fund to <strong>₹{{ emergencyFund.toLocaleString() }}</strong>. Gap: <strong>₹{{ (emergencyFund - snapshotSavings).toLocaleString() }}</strong></p></div>
              <div v-if="savingsRate < 20" class="tip-row"><span>📉</span><p>Savings rate is <strong>{{ savingsRate }}%</strong>. Aim for 20%+.</p></div>
              <div class="tip-row"><span>📊</span><p>You have <strong>{{ emergencyMonths }} months</strong> covered. Target 3-6 months.</p></div>
            </div>
          </div>
        </div>

        <!-- History -->
        <div v-if="history.length > 0" class="card history-card">
          <div class="card-header"><h2 class="card-title">📜 Past Stress Tests</h2></div>
          <div class="history-list">
            <div v-for="h in history" :key="h.id" class="history-row" @click="loadFromHistory(h)">
              <div class="history-left">
                <span class="history-score" :class="h.score >= 80 ? 'green' : h.score >= 50 ? 'accent' : 'red'">{{ h.score }}%</span>
                <div>
                  <p class="history-title">{{ h.passed_scenarios }}/{{ h.total_scenarios }} passed</p>
                  <p class="history-date">{{ formatDate(h.created_at) }}</p>
                </div>
              </div>
              <button class="history-delete" @click.stop="deleteHistoryItem(h.id)">🗑</button>
            </div>
          </div>
        </div>
      </template>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page { display: flex; flex-direction: column; gap: 1.5rem; }

.loading-page { display: flex; flex-direction: column; align-items: center; gap: 1rem; padding: 4rem 0; color: var(--color-text-muted); font-size: 0.875rem; }
.spinner-lg { width: 32px; height: 32px; border: 3px solid var(--color-border); border-top-color: var(--color-graphite); border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.intro-banner { display: flex; align-items: center; justify-content: space-between; background: var(--color-surface); border: 1.5px solid var(--color-accent); border-radius: var(--radius-lg); padding: 1.25rem 1.5rem; }
.intro-left { display: flex; align-items: center; gap: 1rem; }
.intro-icon { font-size: 1.75rem; }
.intro-title { font-size: 1rem; font-weight: 700; color: var(--color-text); }
.intro-desc { font-size: 0.8125rem; color: var(--color-text-muted); margin-top: 0.125rem; max-width: 500px; }
.intro-actions { display: flex; gap: 0.5rem; }
.share-btn, .reset-btn { padding: 0.5rem 1rem; font-size: 0.8125rem; font-weight: 500; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-surface); border: 1.5px solid var(--color-border); border-radius: var(--radius); cursor: pointer; transition: all 0.15s; }
.share-btn:hover, .reset-btn:hover { border-color: var(--color-graphite); }

.snapshot-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }
.snap-card { display: flex; flex-direction: column; gap: 0.375rem; padding: 1.125rem !important; }
.snap-label { font-size: 0.75rem; color: var(--color-text-muted); }
.snap-value { font-size: 1.25rem; font-weight: 700; color: var(--color-text); }
.snap-value.green { color: #2e7d32; } .snap-value.red { color: #d32f2f; }
.snap-hint { font-size: 0.6875rem; color: var(--color-text-muted); }

.slider { width: 100%; margin-top: 0.25rem; accent-color: var(--color-graphite); height: 4px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider::-webkit-slider-thumb { -webkit-appearance: none; width: 16px; height: 16px; border-radius: 50%; background: var(--color-graphite); cursor: pointer; border: 2px solid var(--color-surface); box-shadow: 0 1px 3px rgba(0,0,0,0.2); }
.slider-sm { width: 100%; margin-top: 0.25rem; height: 3px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider-sm::-webkit-slider-thumb { -webkit-appearance: none; width: 12px; height: 12px; border-radius: 50%; background: var(--color-graphite); cursor: pointer; border: 2px solid var(--color-surface); }
.slider-scenario { width: 100%; margin-top: 0.5rem; height: 4px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider-scenario::-webkit-slider-thumb { -webkit-appearance: none; width: 14px; height: 14px; border-radius: 50%; background: var(--accent, var(--color-graphite)); cursor: pointer; border: 2px solid var(--color-surface); }

.card { background: var(--color-surface); border-radius: var(--radius-lg); padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04); }
.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
.card-title { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.card-subtitle { font-size: 0.75rem; color: var(--color-text-muted); }
.card-subtotal { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }

.budget-list { display: flex; flex-direction: column; gap: 0.875rem; }
.budget-row { display: flex; align-items: center; justify-content: space-between; gap: 1.5rem; }
.budget-left { display: flex; align-items: center; gap: 0.75rem; flex: 1; min-width: 0; }
.budget-icon { font-size: 1.125rem; width: 28px; text-align: center; flex-shrink: 0; }
.budget-info { flex: 1; min-width: 0; }
.budget-top { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.375rem; }
.budget-name { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }
.essential-badge { font-size: 0.625rem; font-weight: 500; color: #d32f2f; background: rgba(211, 47, 47, 0.08); padding: 0.125rem 0.5rem; border-radius: 999px; }
.optional-badge { font-size: 0.625rem; font-weight: 500; color: var(--color-text-muted); background: var(--color-bg); padding: 0.125rem 0.5rem; border-radius: 999px; }
.budget-bar-track { height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; }
.budget-bar-fill { height: 100%; background: var(--color-graphite); border-radius: 2px; }
.budget-right { display: flex; flex-direction: column; align-items: flex-end; min-width: 140px; }
.budget-amt { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }

.scenario-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.scenario-card { padding: 1rem 1.25rem; background: var(--color-bg); border-radius: var(--radius); }
.scenario-card:hover { background: rgba(0,0,0,0.025); }
.sa-top { display: flex; align-items: flex-start; gap: 0.75rem; }
.sa-icon { font-size: 1.5rem; flex-shrink: 0; }
.sa-info { flex: 1; min-width: 0; }
.sa-title { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }
.sa-desc { font-size: 0.6875rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.sa-badge { font-size: 0.75rem; font-weight: 700; padding: 0.25rem 0.625rem; border-radius: 999px; white-space: nowrap; flex-shrink: 0; }
.sa-range { display: flex; justify-content: space-between; margin-top: 0.25rem; font-size: 0.625rem; color: var(--color-text-muted); }

.run-section { display: flex; align-items: center; gap: 0.75rem; }
.run-btn { display: flex; align-items: center; gap: 0.5rem; padding: 0.875rem 2rem; font-size: 0.9375rem; font-weight: 700; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-accent); border: none; border-radius: var(--radius); cursor: pointer; transition: all 0.2s; }
.run-btn:hover:not(:disabled) { background: var(--color-accent-hover); transform: translateY(-1px); }
.run-btn:disabled { opacity: 0.7; cursor: not-allowed; }
.spinner-sm { width: 16px; height: 16px; border: 2px solid rgba(32,33,36,0.2); border-top-color: var(--color-graphite); border-radius: 50%; animation: spin 0.7s linear infinite; }

.results-section { display: flex; flex-direction: column; gap: 1.5rem; animation: fadeUp 0.3s ease; }
@keyframes fadeUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }
.results-top-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }

.score-card { display: flex; align-items: center; gap: 2rem; }
.score-ring-wrap { position: relative; width: 130px; height: 130px; flex-shrink: 0; }
.score-ring { width: 100%; height: 100%; }
.score-arc { transition: stroke-dashoffset 1s ease; }
.score-center { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.score-num { font-size: 1.5rem; font-weight: 700; }
.score-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.score-info { flex: 1; }
.score-title { font-size: 1.0625rem; font-weight: 700; margin-bottom: 0.375rem; }
.score-desc { font-size: 0.8125rem; color: var(--color-text-muted); line-height: 1.6; }
.score-desc strong { color: var(--color-text); }

.quick-stats { padding: 1.25rem !important; display: flex; flex-direction: column; gap: 1rem; }
.qs-item { display: flex; align-items: flex-start; gap: 0.75rem; }
.qs-icon { font-size: 1.25rem; margin-top: 0.125rem; }
.qs-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.qs-value { font-size: 1.0625rem; font-weight: 700; color: var(--color-text); }
.qs-value.green { color: #2e7d32; } .qs-value.red { color: #d32f2f; } .qs-value.accent { color: #fb923c; }
.qs-sub { font-size: 0.6875rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.qs-sub.green { color: #2e7d32; } .qs-sub.red { color: #d32f2f; }

.scenario-results { display: flex; flex-direction: column; gap: 0.75rem; }
.sr-card { cursor: pointer; transition: transform 0.15s, box-shadow 0.15s; padding: 1.25rem 1.5rem !important; }
.sr-card:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,0.06); }
.sr-card.passed { border-left: 4px solid #2e7d32; }
.sr-card.failed { border-left: 4px solid #d32f2f; }
.sr-top { display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
.sr-left { display: flex; align-items: center; gap: 0.75rem; flex: 1; }
.sr-icon { font-size: 1.5rem; flex-shrink: 0; }
.sr-title { font-size: 0.875rem; font-weight: 600; color: var(--color-text); }
.sr-desc { font-size: 0.75rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.sr-badge { font-size: 0.75rem; font-weight: 600; padding: 0.25rem 0.75rem; border-radius: 999px; flex-shrink: 0; }
.sr-badge.pass { color: #2e7d32; background: rgba(46, 125, 50, 0.1); }
.sr-badge.fail { color: #d32f2f; background: rgba(211, 47, 47, 0.1); }
.sr-bar { display: flex; align-items: center; gap: 0.75rem; margin-top: 0.75rem; }
.sr-bar-track { flex: 1; height: 6px; background: var(--color-bg); border-radius: 3px; overflow: hidden; }
.sr-bar-fill { height: 100%; border-radius: 3px; transition: width 0.5s; }
.sr-bar-pct { font-size: 0.75rem; font-weight: 600; color: var(--color-text-muted); min-width: 80px; text-align: right; }
.sr-details { margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--color-bg); animation: fadeUp 0.2s ease; }
.sr-stats-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.75rem; margin-bottom: 1rem; }
.sr-stat { display: flex; flex-direction: column; gap: 0.25rem; }
.sr-stat-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.sr-stat-value { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }
.sr-stat-value.green { color: #2e7d32; } .sr-stat-value.red { color: #d32f2f; }
.sr-stat-value.critical { color: #d32f2f; } .sr-stat-value.high { color: #fb923c; }
.sr-stat-value.medium { color: #ff9800; } .sr-stat-value.low { color: #2e7d32; }
.sr-tip { display: flex; align-items: flex-start; gap: 0.5rem; padding: 0.75rem; background: var(--color-bg); border-radius: var(--radius); font-size: 0.8125rem; color: var(--color-text-muted); line-height: 1.6; }
.sr-tip p { margin: 0; }

.ai-card { border: 1.5px solid var(--color-accent); }
.ai-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.25rem; }
.ai-badge { font-size: 0.6875rem; font-weight: 500; color: var(--color-graphite); background: rgba(215, 243, 74, 0.3); padding: 0.25rem 0.625rem; border-radius: 999px; animation: pulse 1.5s ease-in-out infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.ai-loading { display: flex; flex-direction: column; align-items: center; gap: 0.75rem; padding: 2rem 0; }
.spinner { width: 28px; height: 28px; border: 3px solid var(--color-border); border-top-color: var(--color-graphite); border-radius: 50%; animation: spin 0.8s linear infinite; }
.ai-content { display: flex; flex-direction: column; gap: 1rem; animation: fadeUp 0.3s ease; }
.ai-section { padding: 0.875rem 1rem; background: var(--color-bg); border-radius: var(--radius); border-left: 3px solid var(--color-accent); }
.ai-section-title { font-size: 0.8125rem; font-weight: 700; color: var(--color-text); margin-bottom: 0.5rem; }
.ai-section-text { font-size: 0.8125rem; line-height: 1.7; color: var(--color-text-muted); }
.ai-section-text :deep(strong) { color: var(--color-text); font-weight: 600; }
.ai-fallback { font-size: 0.75rem; color: var(--color-text-muted); font-style: italic; margin-bottom: 0.75rem; }
.tips-list { display: flex; flex-direction: column; gap: 0.875rem; margin-top: 0.25rem; }
.tip-row { display: flex; align-items: flex-start; gap: 0.625rem; font-size: 0.8125rem; color: var(--color-text-muted); line-height: 1.6; }
.tip-row span { font-size: 1rem; flex-shrink: 0; margin-top: 0.125rem; }
.tip-row strong { color: var(--color-text); }

.history-card { margin-top: 0.5rem; }
.history-list { display: flex; flex-direction: column; gap: 0.5rem; }
.history-row { display: flex; align-items: center; justify-content: space-between; padding: 0.75rem; background: var(--color-bg); border-radius: var(--radius); cursor: pointer; transition: background 0.15s; }
.history-row:hover { background: rgba(0,0,0,0.04); }
.history-left { display: flex; align-items: center; gap: 0.75rem; }
.history-score { font-size: 1rem; font-weight: 700; min-width: 40px; }
.history-score.green { color: #2e7d32; } .history-score.accent { color: #fb923c; } .history-score.red { color: #d32f2f; }
.history-title { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }
.history-date { font-size: 0.6875rem; color: var(--color-text-muted); }
.history-delete { background: none; border: none; cursor: pointer; font-size: 0.875rem; opacity: 0.5; transition: opacity 0.15s; }
.history-delete:hover { opacity: 1; }
</style>
