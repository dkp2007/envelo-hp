<script setup>
import { ref, computed } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { groq } from '@/lib/groq'

/* ─── User's current financial snapshot ─── */
const monthlyIncome = ref(58000)
const monthlyExpenses = ref(28450)
const currentSavings = ref(120000)

/* ─── Editable budget breakdown ─── */
const budgets = ref([
  { name: 'Rent', icon: '🏠', amount: 12000, essential: true },
  { name: 'Food', icon: '🍔', amount: 2750, essential: true },
  { name: 'Fun', icon: '🎮', amount: 4250, essential: false },
  { name: 'Utilities', icon: '💡', amount: 2500, essential: true },
  { name: 'Subscriptions', icon: '📱', amount: 649, essential: false },
  { name: 'Transport', icon: '🚗', amount: 1800, essential: false },
  { name: 'Savings', icon: '💰', amount: 4501, essential: false },
])

/* ─── Scenarios (impact adjustable) ─── */
const scenarios = ref([
  { id: 'medical', title: 'Unexpected Medical Expense', icon: '🏥', description: 'A sudden medical bill pops up this month.', impact: 5000, type: 'expense', color: '#d32f2f', min: 1000, max: 50000, step: 1000, tip: 'Use your emergency fund. If short, negotiate a payment plan with the hospital.' },
  { id: 'income-cut', title: 'Income Reduction', icon: '📉', description: 'Your monthly income drops for the next 3 months.', impact: 5800, type: 'income', color: '#fb923c', min: 1000, max: 30000, step: 500, tip: 'Immediately cut non-essential spending (Fun, Subscriptions, Transport). Pause savings contributions temporarily.' },
  { id: 'emergency', title: 'Major Emergency Expense', icon: '🚨', description: 'A large emergency hits — car repair, home damage, etc.', impact: 15000, type: 'expense', color: '#e91e63', min: 5000, max: 100000, step: 1000, tip: 'Prioritize essentials only. Reduce Food budget by ordering less, pause Fun and Subscriptions entirely.' },
  { id: 'big-purchase', title: 'Major One-Time Purchase', icon: '🛒', description: 'You need a big purchase — laptop, furniture, appliance.', impact: 25000, type: 'expense', color: '#9c27b0', min: 5000, max: 200000, step: 1000, tip: 'Spread across 2-3 months by reducing non-essentials. Consider EMI if interest-free option is available.' },
  { id: 'job-loss', title: 'Job Loss (2 Months)', icon: '💼', description: 'You lose your job and are unemployed for 2 months.', impact: 58000, type: 'income', color: '#202124', min: 10000, max: 200000, step: 2000, tip: 'Cut all non-essential spending immediately. Cancel subscriptions. File for unemployment benefits. Start job hunting aggressively.' },
  { id: 'rent-hike', title: 'Rent Increase', icon: '🏠', description: 'Your landlord increases rent by a percentage.', impact: 3000, type: 'expense', color: '#ff9800', min: 500, max: 15000, step: 500, tip: 'Negotiate with your landlord. If not possible, offset by reducing other categories. Consider if moving is cost-effective.' },
])

/* ─── Results ─── */
const results = computed(() => {
  const surplus = monthlyIncome.value - monthlyExpenses.value
  const nonEssentialTotal = budgets.value.filter(b => !b.essential).reduce((s, b) => s + b.amount, 0)
  const totalSavings = currentSavings.value

  return scenarios.value.map(s => {
    let surviving, recoveryMonths, canAbsorb

    if (s.type === 'income') {
      const newSurplus = (monthlyIncome.value - s.impact) - monthlyExpenses.value
      surviving = newSurplus >= 0 || totalSavings >= s.impact * 3
      recoveryMonths = newSurplus >= 0 ? 0 : Math.ceil(s.impact * 3 / Math.max(nonEssentialTotal, 1))
      canAbsorb = totalSavings >= s.impact * 3
    } else {
      surviving = surplus >= s.impact || totalSavings >= s.impact
      recoveryMonths = surplus >= s.impact ? 0 : Math.ceil(s.impact / Math.max(surplus, 1))
      canAbsorb = totalSavings >= s.impact
    }

    const coveragePercent = s.type === 'income'
      ? (totalSavings >= s.impact * 3 ? 100 : Math.min(Math.round((totalSavings / (s.impact * 3)) * 100), 99))
      : (totalSavings >= s.impact ? 100 : Math.min(Math.round((totalSavings / s.impact) * 100), 99))

    const severity = s.impact > monthlyIncome.value * 0.5 ? 'critical' : s.impact > monthlyIncome.value * 0.2 ? 'high' : s.impact > monthlyIncome.value * 0.1 ? 'medium' : 'low'

    return { ...s, surviving, recoveryMonths, canAbsorb, coveragePercent, severity }
  })
})

const passedCount = computed(() => results.value.filter(r => r.surviving).length)
const totalCount = computed(() => results.value.length)
const scorePercent = computed(() => Math.round((passedCount.value / totalCount.value) * 100))
const scoreColor = computed(() => {
  const p = scorePercent.value
  if (p >= 80) return '#2e7d32'
  if (p >= 50) return '#fb923c'
  return '#d32f2f'
})
const emergencyFund = computed(() => monthlyExpenses.value * 3)
const emergencyMonths = computed(() => Math.floor(currentSavings.value / monthlyExpenses.value))
const savingsRate = computed(() => monthlyIncome.value ? Math.round(((monthlyIncome.value - monthlyExpenses.value) / monthlyIncome.value) * 100) : 0)

/* ─── UI State ─── */
const testRan = ref(false)
const running = ref(false)
const aiAnalysis = ref('')
const aiLoading = ref(false)
const aiError = ref('')
const activeScenario = ref(null)

async function runTest() {
  running.value = true
  aiAnalysis.value = ''
  aiError.value = ''
  activeScenario.value = null

  await new Promise(r => setTimeout(r, 1200))
  running.value = false
  testRan.value = true

  // AI analysis
  aiLoading.value = true
  const surplus = monthlyIncome.value - monthlyExpenses.value
  const budgetBreakdown = budgets.value.map(b => `${b.name}: ₹${b.amount.toLocaleString()}${b.essential ? ' (essential)' : ' (non-essential)'}`).join(', ')
  const scenarioResults = results.value.map(r => `${r.title}: ${r.surviving ? 'SURVIVED' : 'FAILED'} — Impact: ₹${r.impact.toLocaleString()}${r.type === 'income' ? '/mo' : ''}, Covered: ${r.canAbsorb ? 'Yes' : 'No'}, Severity: ${r.severity}`).join('\n')

  try {
    const res = await groq.chat.completions.create({
      model: 'llama-3.1-70b-versatile',
      messages: [
        {
          role: 'system',
          content: `You are a personal finance advisor for Envelo. The user ran a budget stress test with 6 scenarios. Analyze their results and give personalized, actionable advice. Use INR. No markdown. Under 500 words.

Format in these sections:
1. VERDICT — 2-sentence overall assessment
2. SCENARIO BREAKDOWN — for each failed scenario, explain WHY it failed with specific numbers and WHAT to cut/change. For passed ones, note what works.
3. RECOVERY PLAN — for failed scenarios, give a month-by-month recovery plan
4. EMERGENCY FUND GAP — their current savings vs recommended, and exactly how much more to save monthly
5. TOP 3 PRIORITIES — the 3 most impactful things they can do THIS WEEK
6. MONTHLY BUDGET SUGGESTIONS — specific rupee amounts they should set for each category

Be extremely specific with actual numbers from their data.`,
        },
        {
          role: 'user',
          content: `My stress test results:

SNAPSHOT:
- Monthly Income: ₹${monthlyIncome.value.toLocaleString()}
- Monthly Expenses: ₹${monthlyExpenses.value.toLocaleString()}
- Monthly Surplus: ₹${surplus.toLocaleString()}
- Current Savings: ₹${currentSavings.value.toLocaleString()}
- Months of expenses covered: ${emergencyMonths.value}
- Savings Rate: ${savingsRate.value}%

BUDGET: ${budgetBreakdown}

RESULTS: ${scenarioResults}

Score: ${passedCount.value}/${totalCount.value} | Emergency fund needed: ₹${emergencyFund.value.toLocaleString()}`,
        },
      ],
      temperature: 0.7,
      max_tokens: 1500,
    })
    aiAnalysis.value = res.choices[0]?.message?.content || ''
  } catch {
    aiError.value = 'Could not generate AI analysis. Showing basic tips instead.'
  } finally {
    aiLoading.value = false
  }
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
  return text
    .replace(/\n/g, '<br>')
    .replace(/(₹[\d,]+\.?\d*)/g, '<strong>$1</strong>')
}

function shareResults() {
  const text = `🛡️ My Envelo Budget Stress Test Results\n\nScore: ${passedCount.value}/${totalCount.value} scenarios survived\nSavings Rate: ${savingsRate.value}%\nEmergency Fund: ₹${emergencyFund.value.toLocaleString()} recommended\n\n${results.value.map(r => `${r.icon} ${r.title}: ${r.surviving ? '✓ Survived' : '✗ Failed'} (${r.coveragePercent}% covered)`).join('\n')}\n\nTest yours at envelo.app`
  navigator.clipboard.writeText(text).catch(() => {})
}
</script>

<template>
  <DashboardLayout>
    <div class="page">

      <!-- Intro Banner -->
      <div class="intro-banner">
        <div class="intro-left">
          <span class="intro-icon">🛡️</span>
          <div>
            <h2 class="intro-title">Budget Stress Test</h2>
            <p class="intro-desc">How resilient is your budget? Adjust your numbers, simulate real-world shocks, and find out where you stand.</p>
          </div>
        </div>
        <button v-if="testRan" class="share-btn" @click="shareResults">📋 Share Results</button>
      </div>

      <!-- Snapshot -->
      <div class="snapshot-grid">
        <div class="card snap-card">
          <p class="snap-label">Monthly Income</p>
          <p class="snap-value green">₹{{ monthlyIncome.toLocaleString() }}</p>
          <input v-model.number="monthlyIncome" type="range" class="slider" min="10000" max="200000" step="1000" />
          <span class="snap-range">₹10K – ₹2L</span>
        </div>
        <div class="card snap-card">
          <p class="snap-label">Monthly Expenses</p>
          <p class="snap-value red">₹{{ monthlyExpenses.toLocaleString() }}</p>
          <input v-model.number="monthlyExpenses" type="range" class="slider" min="5000" max="200000" step="1000" />
          <span class="snap-range">₹5K – ₹2L</span>
        </div>
        <div class="card snap-card">
          <p class="snap-label">Current Savings</p>
          <p class="snap-value">₹{{ currentSavings.toLocaleString() }}</p>
          <input v-model.number="currentSavings" type="range" class="slider" min="0" max="500000" step="5000" />
          <span class="snap-range">₹0 – ₹5L</span>
        </div>
        <div class="card snap-card">
          <p class="snap-label">Monthly Surplus</p>
          <p class="snap-value" :class="monthlyIncome - monthlyExpenses >= 0 ? 'green' : 'red'">
            ₹{{ (monthlyIncome - monthlyExpenses).toLocaleString() }}
          </p>
          <div class="snap-surplus-bar">
            <div class="surplus-fill" :style="{ width: Math.min(Math.abs(monthlyIncome - monthlyExpenses) / monthlyIncome * 100, 100) + '%', background: monthlyIncome - monthlyExpenses >= 0 ? '#2e7d32' : '#d32f2f' }"></div>
          </div>
          <p class="snap-hint">{{ savingsRate }}% savings rate</p>
        </div>
      </div>

      <!-- Budget Breakdown -->
      <div class="card">
        <div class="card-header">
          <h2 class="card-title">Budget Breakdown</h2>
          <p class="card-subtotal">Total: ₹{{ budgets.reduce((s, b) => s + b.amount, 0).toLocaleString() }} / ₹{{ monthlyIncome.toLocaleString() }}</p>
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
                  <div class="budget-bar-fill" :style="{ width: Math.min((b.amount / monthlyIncome) * 100, 100) + '%' }"></div>
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

      <!-- Scenarios (Adjustable) -->
      <div class="card">
        <div class="card-header">
          <h2 class="card-title">Stress Scenarios</h2>
          <p class="card-subtitle">Drag each slider to adjust the impact severity</p>
        </div>
        <div class="scenario-adjust-grid">
          <div v-for="s in scenarios" :key="s.id" class="scenario-adjust-card" :class="s.type">
            <div class="sa-top">
              <span class="sa-icon">{{ s.icon }}</span>
              <div class="sa-info">
                <p class="sa-title">{{ s.title }}</p>
                <p class="sa-desc">{{ s.description }}</p>
              </div>
              <div class="sa-impact-badge" :style="{ background: s.color + '18', color: s.color }">
                {{ s.type === 'income' ? '-' : '-' }}₹{{ s.impact.toLocaleString() }}{{ s.type === 'income' ? '/mo' : '' }}
              </div>
            </div>
            <input v-model.number="s.impact" type="range" class="slider-scenario" :min="s.min" :max="s.max" :step="s.step" :style="{ '--accent': s.color }" />
            <div class="sa-range-row">
              <span class="sa-range-min">₹{{ s.min.toLocaleString() }}</span>
              <span class="sa-range-max">₹{{ s.max.toLocaleString() }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Run Button -->
      <div class="run-section">
        <button class="run-btn" :disabled="running" @click="runTest">
          <span v-if="running" class="spinner-sm"></span>
          <span v-else>⚡</span>
          {{ running ? 'Running Stress Test...' : 'Run Stress Test' }}
        </button>
        <button v-if="testRan" class="reset-btn" @click="resetTest">↺ Reset</button>
      </div>

      <!-- Results -->
      <div v-if="testRan" class="results-section">

        <!-- Score + Summary Row -->
        <div class="results-top-row">
          <!-- Score Card -->
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
              <p class="score-desc">
                Your budget survives <strong>{{ passedCount }} out of {{ totalCount }}</strong> stress scenarios.
                You have <strong>{{ emergencyMonths }} months</strong> of expenses covered.
              </p>
            </div>
          </div>

          <!-- Quick Stats -->
          <div class="quick-stats card">
            <div class="qs-row">
              <div class="qs-item">
                <span class="qs-icon">🏦</span>
                <div>
                  <p class="qs-label">Emergency Fund</p>
                  <p class="qs-value">₹{{ emergencyFund.toLocaleString() }}</p>
                  <p class="qs-sub">{{ currentSavings >= emergencyFund ? '✓ Funded' : '₹' + (emergencyFund - currentSavings).toLocaleString() + ' gap' }}" :class="currentSavings >= emergencyFund ? 'green' : 'red'"</p>
                </div>
              </div>
              <div class="qs-item">
                <span class="qs-icon">📊</span>
                <div>
                  <p class="qs-label">Savings Rate</p>
                  <p class="qs-value" :class="savingsRate >= 20 ? 'green' : savingsRate >= 10 ? 'accent' : 'red'">{{ savingsRate }}%</p>
                  <p class="qs-sub">{{ savingsRate >= 20 ? '✓ Healthy' : savingsRate >= 10 ? 'Could improve' : 'Too low' }}</p>
                </div>
              </div>
              <div class="qs-item">
                <span class="qs-icon">🛡️</span>
                <div>
                  <p class="qs-label">Months Covered</p>
                  <p class="qs-value">{{ emergencyMonths }}</p>
                  <p class="qs-sub">{{ emergencyMonths >= 3 ? '✓ 3+ months' : 'Below 3-month target' }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Scenario Results -->
        <div class="scenario-results-grid">
          <div v-for="r in results" :key="r.id" class="scenario-result-card card" :class="{ passed: r.surviving, failed: !r.surviving }" @click="toggleScenario(r.id)">
            <div class="sr-top">
              <div class="sr-left">
                <span class="sr-icon">{{ r.icon }}</span>
                <div>
                  <h3 class="sr-title">{{ r.title }}</h3>
                  <p class="sr-desc">{{ r.description }}</p>
                </div>
              </div>
              <span v-if="r.surviving" class="sr-badge pass">✓ Survived</span>
              <span v-else class="sr-badge fail">✗ Failed</span>
            </div>

            <!-- Severity bar -->
            <div class="sr-severity">
              <div class="severity-track">
                <div class="severity-fill" :style="{ width: r.coveragePercent + '%', background: r.surviving ? '#2e7d32' : '#d32f2f' }"></div>
              </div>
              <span class="severity-pct">{{ r.coveragePercent }}% covered</span>
            </div>

            <!-- Expanded details -->
            <div v-if="activeScenario === r.id" class="sr-details" @click.stop>
              <div class="sr-stats">
                <div class="sr-stat">
                  <span class="sr-stat-label">Impact</span>
                  <span class="sr-stat-value red">₹{{ r.impact.toLocaleString() }}{{ r.type === 'income' ? '/mo' : '' }}</span>
                </div>
                <div class="sr-stat">
                  <span class="sr-stat-label">Severity</span>
                  <span class="sr-stat-value" :class="r.severity">{{ r.severity.charAt(0).toUpperCase() + r.severity.slice(1) }}</span>
                </div>
                <div v-if="r.recoveryMonths > 0" class="sr-stat">
                  <span class="sr-stat-label">Recovery</span>
                  <span class="sr-stat-value">{{ r.recoveryMonths }} month{{ r.recoveryMonths > 1 ? 's' : '' }}</span>
                </div>
                <div class="sr-stat">
                  <span class="sr-stat-label">Covered by Savings</span>
                  <span class="sr-stat-value" :class="r.canAbsorb ? 'green' : 'red'">{{ r.canAbsorb ? 'Yes ✓' : 'No ✗' }}</span>
                </div>
              </div>
              <div class="sr-tip">
                <span class="sr-tip-icon">💡</span>
                <p class="sr-tip-text">{{ r.tip }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- AI Analysis -->
        <div class="card ai-card">
          <div class="ai-header">
            <h2 class="card-title">🤖 AI Resilience Analysis</h2>
            <span v-if="aiLoading" class="ai-badge">Generating...</span>
          </div>

          <div v-if="aiLoading" class="ai-loading">
            <div class="spinner"></div>
            <p class="loading-text">Analyzing your stress test results...</p>
          </div>

          <div v-else-if="aiAnalysis" class="ai-content">
            <div v-for="(section, i) in parseAiSections(aiAnalysis)" :key="i" class="ai-section">
              <h3 class="ai-section-title">{{ section.title }}</h3>
              <p class="ai-section-text" v-html="formatAiText(section.body)"></p>
            </div>
          </div>

          <div v-else class="tips-list">
            <p v-if="aiError" class="ai-fallback-note">{{ aiError }}</p>
            <div v-if="currentSavings < emergencyFund" class="tip-row">
              <span class="tip-icon">🏦</span>
              <p class="tip-text">Build your emergency fund to <strong>₹{{ emergencyFund.toLocaleString() }}</strong>. You're at <strong>₹{{ currentSavings.toLocaleString() }}</strong> — that's a <strong>₹{{ (emergencyFund - currentSavings).toLocaleString() }}</strong> gap.</p>
            </div>
            <div v-if="savingsRate < 20" class="tip-row">
              <span class="tip-icon">📉</span>
              <p class="tip-text">Your savings rate is <strong>{{ savingsRate }}%</strong>. Aim for 20%+ by reducing non-essential spending.</p>
            </div>
            <div class="tip-row">
              <span class="tip-icon">📊</span>
              <p class="tip-text">You have <strong>{{ emergencyMonths }} months</strong> of expenses covered. Target 3-6 months for true resilience.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page { display: flex; flex-direction: column; gap: 1.5rem; }

/* ─── Intro ─── */
.intro-banner { display: flex; align-items: center; justify-content: space-between; background: var(--color-surface); border: 1.5px solid var(--color-accent); border-radius: var(--radius-lg); padding: 1.25rem 1.5rem; }
.intro-left { display: flex; align-items: center; gap: 1rem; }
.intro-icon { font-size: 1.75rem; }
.intro-title { font-size: 1rem; font-weight: 700; color: var(--color-text); }
.intro-desc { font-size: 0.8125rem; color: var(--color-text-muted); margin-top: 0.125rem; max-width: 500px; }

.share-btn { padding: 0.5rem 1rem; font-size: 0.8125rem; font-weight: 500; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-surface); border: 1.5px solid var(--color-border); border-radius: var(--radius); cursor: pointer; transition: all 0.15s; }
.share-btn:hover { border-color: var(--color-graphite); }

/* ─── Snapshot ─── */
.snapshot-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 1rem; }
.snap-card { display: flex; flex-direction: column; gap: 0.375rem; padding: 1.125rem !important; }
.snap-label { font-size: 0.75rem; color: var(--color-text-muted); }
.snap-value { font-size: 1.25rem; font-weight: 700; color: var(--color-text); }
.snap-value.green { color: #2e7d32; } .snap-value.red { color: #d32f2f; }
.snap-range { font-size: 0.625rem; color: var(--color-text-muted); text-align: right; }
.snap-surplus-bar { height: 4px; background: var(--color-bg); border-radius: 2px; overflow: hidden; margin-top: 0.25rem; }
.surplus-fill { height: 100%; border-radius: 2px; transition: width 0.3s; }
.snap-hint { font-size: 0.6875rem; color: var(--color-text-muted); }

/* ─── Sliders ─── */
.slider { width: 100%; margin-top: 0.25rem; accent-color: var(--color-graphite); height: 4px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider::-webkit-slider-thumb { -webkit-appearance: none; width: 16px; height: 16px; border-radius: 50%; background: var(--color-graphite); cursor: pointer; border: 2px solid var(--color-surface); box-shadow: 0 1px 3px rgba(0,0,0,0.2); }
.slider-sm { width: 100%; margin-top: 0.25rem; accent-color: var(--color-graphite); height: 3px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider-sm::-webkit-slider-thumb { -webkit-appearance: none; width: 12px; height: 12px; border-radius: 50%; background: var(--color-graphite); cursor: pointer; border: 2px solid var(--color-surface); }
.slider-scenario { width: 100%; margin-top: 0.5rem; accent-color: var(--accent, var(--color-graphite)); height: 4px; -webkit-appearance: none; appearance: none; background: var(--color-bg); border-radius: 2px; outline: none; }
.slider-scenario::-webkit-slider-thumb { -webkit-appearance: none; width: 14px; height: 14px; border-radius: 50%; background: var(--accent, var(--color-graphite)); cursor: pointer; border: 2px solid var(--color-surface); box-shadow: 0 1px 2px rgba(0,0,0,0.15); }

/* ─── Cards ─── */
.card { background: var(--color-surface); border-radius: var(--radius-lg); padding: 1.5rem; box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04); }
.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
.card-title { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.card-subtitle { font-size: 0.75rem; color: var(--color-text-muted); }
.card-subtotal { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }

/* ─── Budget ─── */
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
.budget-bar-fill { height: 100%; background: var(--color-graphite); border-radius: 2px; transition: width 0.3s; }
.budget-right { display: flex; flex-direction: column; align-items: flex-end; min-width: 140px; }
.budget-amt { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }

/* ─── Scenario Adjust ─── */
.scenario-adjust-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.scenario-adjust-card { padding: 1rem 1.25rem; background: var(--color-bg); border-radius: var(--radius); transition: background 0.2s; }
.scenario-adjust-card:hover { background: rgba(0,0,0,0.025); }
.sa-top { display: flex; align-items: flex-start; gap: 0.75rem; }
.sa-icon { font-size: 1.5rem; flex-shrink: 0; margin-top: 0.125rem; }
.sa-info { flex: 1; min-width: 0; }
.sa-title { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }
.sa-desc { font-size: 0.6875rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.sa-impact-badge { font-size: 0.75rem; font-weight: 700; padding: 0.25rem 0.625rem; border-radius: 999px; white-space: nowrap; flex-shrink: 0; }
.sa-range-row { display: flex; justify-content: space-between; margin-top: 0.25rem; }
.sa-range-min, .sa-range-max { font-size: 0.625rem; color: var(--color-text-muted); }

/* ─── Run ─── */
.run-section { display: flex; align-items: center; gap: 0.75rem; }
.run-btn { display: flex; align-items: center; gap: 0.5rem; padding: 0.875rem 2rem; font-size: 0.9375rem; font-weight: 700; font-family: var(--font-sans); color: var(--color-graphite); background: var(--color-accent); border: none; border-radius: var(--radius); cursor: pointer; transition: all 0.2s; }
.run-btn:hover:not(:disabled) { background: var(--color-accent-hover); transform: translateY(-1px); }
.run-btn:disabled { opacity: 0.7; cursor: not-allowed; }
.spinner-sm { width: 16px; height: 16px; border: 2px solid rgba(32,33,36,0.2); border-top-color: var(--color-graphite); border-radius: 50%; animation: spin 0.7s linear infinite; flex-shrink: 0; }
@keyframes spin { to { transform: rotate(360deg); } }
.reset-btn { padding: 0.75rem 1.25rem; font-size: 0.8125rem; font-weight: 500; font-family: var(--font-sans); color: var(--color-text-muted); background: none; border: 1.5px solid var(--color-border); border-radius: var(--radius); cursor: pointer; transition: all 0.15s; }
.reset-btn:hover { border-color: var(--color-graphite); color: var(--color-text); }

/* ─── Results ─── */
.results-section { display: flex; flex-direction: column; gap: 1.5rem; animation: fadeUp 0.3s ease; }
@keyframes fadeUp { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: translateY(0); } }

.results-top-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }

/* Score */
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

/* Quick Stats */
.quick-stats { padding: 1.25rem !important; }
.qs-row { display: flex; flex-direction: column; gap: 1rem; }
.qs-item { display: flex; align-items: flex-start; gap: 0.75rem; }
.qs-icon { font-size: 1.25rem; margin-top: 0.125rem; }
.qs-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.qs-value { font-size: 1.0625rem; font-weight: 700; color: var(--color-text); }
.qs-value.green { color: #2e7d32; } .qs-value.red { color: #d32f2f; } .qs-value.accent { color: #fb923c; }
.qs-sub { font-size: 0.6875rem; color: var(--color-text-muted); margin-top: 0.125rem; }

/* Scenario Results */
.scenario-results-grid { display: flex; flex-direction: column; gap: 0.75rem; }
.scenario-result-card { cursor: pointer; transition: transform 0.15s, box-shadow 0.15s; padding: 1.25rem 1.5rem !important; }
.scenario-result-card:hover { transform: translateY(-1px); box-shadow: 0 4px 12px rgba(0,0,0,0.06); }
.scenario-result-card.passed { border-left: 4px solid #2e7d32; }
.scenario-result-card.failed { border-left: 4px solid #d32f2f; }
.sr-top { display: flex; align-items: center; justify-content: space-between; gap: 1rem; }
.sr-left { display: flex; align-items: center; gap: 0.75rem; flex: 1; }
.sr-icon { font-size: 1.5rem; flex-shrink: 0; }
.sr-title { font-size: 0.875rem; font-weight: 600; color: var(--color-text); }
.sr-desc { font-size: 0.75rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.sr-badge { font-size: 0.75rem; font-weight: 600; padding: 0.25rem 0.75rem; border-radius: 999px; flex-shrink: 0; }
.sr-badge.pass { color: #2e7d32; background: rgba(46, 125, 50, 0.1); }
.sr-badge.fail { color: #d32f2f; background: rgba(211, 47, 47, 0.1); }
.sr-severity { display: flex; align-items: center; gap: 0.75rem; margin-top: 0.75rem; }
.severity-track { flex: 1; height: 6px; background: var(--color-bg); border-radius: 3px; overflow: hidden; }
.severity-fill { height: 100%; border-radius: 3px; transition: width 0.5s; }
.severity-pct { font-size: 0.75rem; font-weight: 600; color: var(--color-text-muted); min-width: 80px; text-align: right; }

.sr-details { margin-top: 1rem; padding-top: 1rem; border-top: 1px solid var(--color-bg); animation: fadeUp 0.2s ease; }
.sr-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0.75rem; margin-bottom: 1rem; }
.sr-stat { display: flex; flex-direction: column; gap: 0.25rem; }
.sr-stat-label { font-size: 0.6875rem; color: var(--color-text-muted); }
.sr-stat-value { font-size: 0.8125rem; font-weight: 600; color: var(--color-text); }
.sr-stat-value.green { color: #2e7d32; } .sr-stat-value.red { color: #d32f2f; } .sr-stat-value.critical { color: #d32f2f; } .sr-stat-value.high { color: #fb923c; } .sr-stat-value.medium { color: #ff9800; } .sr-stat-value.low { color: #2e7d32; }
.sr-tip { display: flex; align-items: flex-start; gap: 0.5rem; padding: 0.75rem; background: var(--color-bg); border-radius: var(--radius); }
.sr-tip-icon { font-size: 0.875rem; flex-shrink: 0; margin-top: 0.125rem; }
.sr-tip-text { font-size: 0.8125rem; line-height: 1.6; color: var(--color-text-muted); }

/* ─── AI ─── */
.ai-card { border: 1.5px solid var(--color-accent); }
.ai-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.25rem; }
.ai-badge { font-size: 0.6875rem; font-weight: 500; color: var(--color-graphite); background: rgba(215, 243, 74, 0.3); padding: 0.25rem 0.625rem; border-radius: 999px; animation: pulse 1.5s ease-in-out infinite; }
@keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }
.ai-loading { display: flex; flex-direction: column; align-items: center; gap: 0.75rem; padding: 2rem 0; }
.spinner { width: 28px; height: 28px; border: 3px solid var(--color-border); border-top-color: var(--color-graphite); border-radius: 50%; animation: spin 0.8s linear infinite; }
.loading-text { font-size: 0.8125rem; color: var(--color-text-muted); }
.ai-content { display: flex; flex-direction: column; gap: 1rem; animation: fadeUp 0.3s ease; }
.ai-section { padding: 0.875rem 1rem; background: var(--color-bg); border-radius: var(--radius); border-left: 3px solid var(--color-accent); }
.ai-section-title { font-size: 0.8125rem; font-weight: 700; color: var(--color-text); margin-bottom: 0.5rem; letter-spacing: 0.02em; }
.ai-section-text { font-size: 0.8125rem; line-height: 1.7; color: var(--color-text-muted); }
.ai-section-text :deep(strong) { color: var(--color-text); font-weight: 600; }
.ai-fallback-note { font-size: 0.75rem; color: var(--color-text-muted); font-style: italic; margin-bottom: 0.75rem; }
.tips-list { display: flex; flex-direction: column; gap: 0.875rem; margin-top: 0.25rem; }
.tip-row { display: flex; align-items: flex-start; gap: 0.625rem; }
.tip-icon { font-size: 1rem; margin-top: 0.125rem; flex-shrink: 0; }
.tip-text { font-size: 0.8125rem; line-height: 1.6; color: var(--color-text-muted); }
.tip-text strong { color: var(--color-text); }
</style>
