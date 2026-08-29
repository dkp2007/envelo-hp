<script setup>
import { ref, computed, onMounted } from 'vue'
import { Doughnut } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { groq } from '@/lib/groq'
import { supabase } from '@/lib/supabase'
import { useFinance } from '@/composables/useFinance.js'
import StateDisplay from '@/components/StateDisplay.vue'

ChartJS.register(ArcElement, Tooltip, Legend)

import { useToast } from '@/composables/useToast.js'

const toast = useToast()
const {
  loading, fetchAll,
  monthIncome, monthExpenses, monthSavings, monthSavingsRate,
  spendingByCategory, topExpenses, budgetData, savingsGoals,
} = useFinance()

const loadError = ref('')

onMounted(async () => {
  try {
    await fetchAll()
    await loadLastPlan()
  } catch (err) {
    loadError.value = err.message || 'Failed to load dashboard data'
    toast.error('Failed to load dashboard data')
  }
})

// Stats derived from real data
const stats = computed(() => [
  { label: 'Total Income', value: `₹${monthIncome.value.toLocaleString()}`, sub: 'This Month', color: '#202124' },
  { label: 'Total Spent', value: `₹${monthExpenses.value.toLocaleString()}`, sub: monthIncome.value ? `${Math.round((monthExpenses.value / monthIncome.value) * 100)}% of income` : '0%', color: '#d32f2f' },
  { label: 'Total Remaining', value: `₹${monthSavings.value.toLocaleString()}`, sub: `${100 - (monthIncome.value ? Math.round((monthExpenses.value / monthIncome.value) * 100) : 0)}% of income`, color: '#2e7d32' },
  { label: 'Savings Rate', value: `${monthSavingsRate.value}%`, sub: 'This Month', color: '#D7F34A' },
])

// Category breakdown for doughnut chart
const spendingData = computed(() => ({
  labels: spendingByCategory.value.map(c => c.name),
  datasets: [{
    data: spendingByCategory.value.map(c => c.spent),
    backgroundColor: spendingByCategory.value.map(c => c.color),
    borderWidth: 0,
    hoverOffset: 4,
  }],
}))

const totalSpent = computed(() => spendingByCategory.value.reduce((s, c) => s + c.spent, 0))

const spendingLegend = computed(() =>
  spendingByCategory.value.map(c => ({
    label: `${c.name} (${totalSpent.value ? Math.round((c.spent / totalSpent.value) * 100) : 0}%)`,
    amount: `₹${c.spent.toLocaleString()}`,
    color: c.color,
  }))
)

const spendingOptions = {
  responsive: true,
  maintainAspectRatio: false,
  cutout: '65%',
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: '#202124',
      titleFont: { family: 'Inter', size: 12 },
      bodyFont: { family: 'Inter', size: 12 },
      padding: 10,
      cornerRadius: 8,
      displayColors: true,
      boxWidth: 10,
      boxHeight: 10,
      boxPadding: 4,
      usePointStyle: true,
      callbacks: { label: (ctx) => ` ₹${ctx.parsed.toLocaleString()}` },
    },
  },
}

// Budget categories for the expenditure card
const categories = computed(() => {
  return budgetData.value.length > 0 ? budgetData.value.map(b => ({
    name: b.name,
    icon: b.icon,
    color: b.color,
    spent: b.spent,
    total: b.budget,
  })) : spendingByCategory.value.map(c => ({
    name: c.name,
    icon: c.icon,
    color: c.color,
    spent: c.spent,
    total: c.spent,
    subs: [],
  }))
})

// First savings goal
const savingsGoal = computed(() => {
  const g = savingsGoals.value[0]
  if (!g) return null
  return {
    name: g.name,
    target: Number(g.target),
    current: Number(g.current),
    percent: Math.round((Number(g.current) / Number(g.target)) * 100),
  }
})

/* ─── AI Plan ─── */
const showModal = ref(false)
const generating = ref(false)
const aiResult = ref(null)
const aiError = ref('')
const savedPlan = ref(null)
const showFullPlan = ref(false)

const form = ref({
  monthlyIncome: '',
  fixedExpenses: '',
  variableExpenses: '',
  savingsGoalName: '',
  savingsGoalAmount: '',
  savingsGoalTimeline: '',
  riskTolerance: 'moderate',
  priorities: [],
})

const riskOptions = ['conservative', 'moderate', 'aggressive']
const priorityOptions = [
  'Build emergency fund',
  'Pay off debt',
  'Invest more',
  'Save for a big purchase',
  'Increase monthly savings',
  'Better budget tracking',
]

function togglePriority(p) {
  const i = form.value.priorities.indexOf(p)
  if (i >= 0) form.value.priorities.splice(i, 1)
  else form.value.priorities.push(p)
}

async function loadLastPlan() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return
    const { data } = await supabase
      .from('financial_plans')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (data) {
      savedPlan.value = data
      aiResult.value = data.plan_data
    }
  } catch {
    // Table might not exist yet
  }
}

async function generatePlan() {
  generating.value = true
  aiResult.value = null
  aiError.value = ''

  const income = Number(form.value.monthlyIncome) || 0
  const fixed = Number(form.value.fixedExpenses) || 0
  const variable = Number(form.value.variableExpenses) || 0
  const total = fixed + variable

  const prompt = `You are a personal finance advisor for an Indian user. Based on the details below, create a personalized monthly expenditure and savings plan. Use INR (₹).

User Details:
- Monthly Income: ₹${income || 'Not specified'}
- Fixed Monthly Expenses: ₹${fixed || 'Not specified'} (rent, bills, EMI, etc.)
- Variable Monthly Expenses: ₹${variable || 'Not specified'} (food, fun, transport, etc.)
- Savings Goal: ${form.value.savingsGoalName || 'None'} — Target: ₹${form.value.savingsGoalAmount || 'N/A'} — Timeline: ${form.value.savingsGoalTimeline || 'N/A'}
- Risk Tolerance: ${form.value.riskTolerance}
- Priorities: ${form.value.priorities.length ? form.value.priorities.join(', ') : 'None'}

Return ONLY a valid JSON object (no markdown, no code fences) with this exact structure:
{
  "title": "Your Personalized Financial Plan",
  "summary": "One-line summary of the plan",
  "highlights": [
    { "icon": "💰", "label": "Monthly Savings", "value": "₹X,XXX" },
    { "icon": "📊", "label": "Savings Rate", "value": "XX%" },
    { "icon": "🎯", "label": "Goal Feasibility", "value": "Achievable / Tight / Needs Adjustment" }
  ],
  "sections": [
    {
      "heading": "Income & Expense Summary",
      "icon": "📋",
      "type": "table",
      "table": {
        "headers": ["Category", "Amount", "% of Income"],
        "rows": [
          ["Total Income", "₹XX,XXX", "100%"],
          ["Fixed Expenses", "₹XX,XXX", "XX%"],
          ["Variable Expenses", "₹XX,XXX", "XX%"],
          ["Total Expenses", "₹XX,XXX", "XX%"],
          ["Net Savings", "₹XX,XXX", "XX%"]
        ]
      }
    },
    {
      "heading": "Recommended Budget Split",
      "icon": "✉️",
      "type": "budget",
      "budget": [
        { "category": "Housing", "emoji": "🏠", "percent": 30, "amount": "₹X,XXX", "bar_color": "#202124" },
        { "category": "Food & Groceries", "emoji": "🍔", "percent": 20, "amount": "₹X,XXX", "bar_color": "#D7F34A" },
        { "category": "Transport", "emoji": "🚗", "percent": 10, "amount": "₹X,XXX", "bar_color": "#3D5A34" },
        { "category": "Fun & Lifestyle", "emoji": "🎬", "percent": 10, "amount": "₹X,XXX", "bar_color": "#2e7d32" },
        { "category": "Savings & Investments", "emoji": "💰", "percent": 20, "amount": "₹X,XXX", "bar_color": "#1565c0" },
        { "category": "Emergency Fund", "emoji": "🛡️", "percent": 10, "amount": "₹X,XXX", "bar_color": "#d32f2f" }
      ]
    },
    {
      "heading": "Savings Strategy",
      "icon": "🎯",
      "type": "tips",
      "items": [
        "Tip 1 with specific numbers",
        "Tip 2 with specific numbers",
        "Tip 3 with specific numbers"
      ]
    },
    {
      "heading": "Key Action Items",
      "icon": "⚡",
      "type": "tips",
      "items": [
        "Action 1 — specific and measurable",
        "Action 2 — specific and measurable",
        "Action 3 — specific and measurable",
        "Action 4 — specific and measurable"
      ]
    }
  ]
}

Be specific with amounts based on the income. All percentages and amounts must add up correctly. Make recommendations realistic for an Indian context.`

  try {
    const res = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 2000,
    })

    let content = res.choices[0]?.message?.content || ''

    // Strip markdown code fences if present
    content = content.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim()

    const parsed = JSON.parse(content)
    aiResult.value = parsed

    // Save to Supabase
    await savePlan(parsed)
    toast.success('Plan generated successfully!')
  } catch (e) {
    const msg = e.message || 'Something went wrong. Please try again.'
    aiError.value = msg
    toast.error(msg)
  } finally {
    generating.value = false
  }
}

async function savePlan(planData) {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    const highlights = planData.highlights || []
    const summaryTitle = planData.title || 'Financial Plan'

    const { error } = await supabase.from('financial_plans').insert({
      user_id: user.id,
      monthly_income: Number(form.value.monthlyIncome) || null,
      fixed_expenses: Number(form.value.fixedExpenses) || null,
      variable_expenses: Number(form.value.variableExpenses) || null,
      savings_goal_name: form.value.savingsGoalName || null,
      savings_goal_amount: Number(form.value.savingsGoalAmount) || null,
      savings_goal_timeline: form.value.savingsGoalTimeline || null,
      risk_tolerance: form.value.riskTolerance,
      priorities: form.value.priorities,
      plan_data: planData,
      summary_title: summaryTitle,
      summary_highlights: highlights,
    })

    if (error) throw error

    // Update local state
    savedPlan.value = {
      plan_data: planData,
      summary_title: summaryTitle,
      summary_highlights: highlights,
      created_at: new Date().toISOString(),
    }
  } catch {
    // Silently fail — plan still shows in UI
  }
}

function closeModal() {
  showModal.value = false
}

function openNewPlanModal() {
  aiResult.value = null
  aiError.value = ''
  showModal.value = true
}
</script>

<template>
  <DashboardLayout>
    <div class="dashboard">
      <!-- Error -->
      <StateDisplay v-if="loadError && !loading" type="error" :message="loadError" action-label="Retry" @action="loadError = ''; fetchAll()" />

      <!-- Loading -->
      <StateDisplay v-else-if="loading" type="loading" />

      <template v-else>
        <!-- Stats Row -->
        <div class="stats-row">
          <div v-for="stat in stats" :key="stat.label" class="stat-card">
            <p class="stat-label">{{ stat.label }}</p>
            <p class="stat-value" :style="{ color: stat.color }">{{ stat.value }}</p>
            <p class="stat-sub" :style="{ color: stat.color }">{{ stat.sub }}</p>
          </div>
        </div>

        <!-- Saved Plan Card (or Generate CTA) -->
        <div v-if="aiResult && !showModal" class="plan-preview-card">
          <div class="plan-preview-header">
            <div class="plan-preview-left">
              <span class="plan-preview-icon">🤖</span>
              <div>
                <h3 class="plan-preview-title">{{ aiResult.title || 'Your Financial Plan' }}</h3>
                <p class="plan-preview-sub">{{ aiResult.summary || 'Generated personalized plan' }}</p>
              </div>
            </div>
            <div class="plan-preview-actions">
              <button class="plan-action-btn secondary" @click="openNewPlanModal">New Plan</button>
              <button class="plan-action-btn primary" @click="showFullPlan = !showFullPlan">
                {{ showFullPlan ? 'Hide Plan' : 'View Plan' }}
              </button>
            </div>
          </div>

          <!-- Highlight chips -->
          <div v-if="aiResult.highlights" class="plan-highlights">
            <div v-for="(h, i) in aiResult.highlights" :key="i" class="highlight-chip">
              <span class="highlight-icon">{{ h.icon }}</span>
              <span class="highlight-label">{{ h.label }}</span>
              <span class="highlight-value">{{ h.value }}</span>
            </div>
          </div>

          <!-- Full Plan View -->
          <Transition name="plan-expand">
            <div v-if="showFullPlan" class="plan-full">
              <div v-for="(section, si) in aiResult.sections" :key="si" class="plan-section">
                <div class="section-heading">
                  <span class="section-icon">{{ section.icon }}</span>
                  <h4 class="section-title">{{ section.heading }}</h4>
                </div>

                <!-- Table type -->
                <div v-if="section.type === 'table' && section.table" class="plan-table-wrap">
                  <table class="plan-table">
                    <thead>
                      <tr>
                        <th v-for="(h, hi) in section.table.headers" :key="hi">{{ h }}</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="(row, ri) in section.table.rows" :key="ri" :class="{ 'total-row': ri === section.table.rows.length - 1 }">
                        <td v-for="(cell, ci) in row" :key="ci">{{ cell }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Budget type -->
                <div v-if="section.type === 'budget' && section.budget" class="plan-budget-list">
                  <div v-for="(b, bi) in section.budget" :key="bi" class="budget-row">
                    <div class="budget-left">
                      <span class="budget-emoji">{{ b.emoji }}</span>
                      <div class="budget-info">
                        <span class="budget-cat">{{ b.category }}</span>
                        <span class="budget-amt">{{ b.amount }}</span>
                      </div>
                    </div>
                    <div class="budget-right">
                      <span class="budget-pct">{{ b.percent }}%</span>
                      <div class="budget-bar-track">
                        <div class="budget-bar-fill" :style="{ width: b.percent + '%', background: b.bar_color || 'var(--color-accent)' }"></div>
                      </div>
                    </div>
                  </div>
                </div>

                <!-- Tips type -->
                <div v-if="section.type === 'tips' && section.items" class="plan-tips">
                  <div v-for="(tip, ti) in section.items" :key="ti" class="tip-item">
                    <span class="tip-bullet">→</span>
                    <span class="tip-text">{{ tip }}</span>
                  </div>
                </div>
              </div>
            </div>
          </Transition>
        </div>

        <!-- Generate CTA (no plan yet) -->
        <div v-else-if="!showModal" class="ai-cta" @click="openNewPlanModal">
          <div class="ai-cta-left">
            <span class="ai-cta-icon">🤖</span>
            <div>
              <p class="ai-cta-title">Get a Personalized Savings & Expenditure Plan</p>
              <p class="ai-cta-desc">Answer a few quick questions and our AI will craft a budget tailored to you.</p>
            </div>
          </div>
          <button class="ai-cta-btn">Get My Plan →</button>
        </div>

        <!-- Content Grid -->
        <div class="content-grid">
          <div class="card categories-card">
            <div class="card-header">
              <h2 class="card-title">Monthly Expenditure</h2>
            </div>
            <div v-if="categories.length === 0" class="empty-state">
              <p>No spending data yet. Add some transactions!</p>
            </div>
            <div v-else class="category-list">
              <div v-for="cat in categories" :key="cat.name" class="category-group">
                <div class="category-row">
                  <div class="cat-left">
                    <span class="cat-icon">{{ cat.icon }}</span>
                    <div class="cat-info">
                      <div class="cat-header-row">
                        <span class="cat-name">{{ cat.name }}</span>
                        <span class="cat-amt">₹{{ cat.spent.toLocaleString() }}{{ cat.total !== cat.spent ? ' / ₹' + cat.total.toLocaleString() : '' }}</span>
                      </div>
                      <div class="cat-bar-track">
                        <div
                          class="cat-bar-fill"
                          :style="{
                            width: Math.min((cat.spent / (cat.total || cat.spent || 1)) * 100, 100) + '%',
                            background: cat.color,
                          }"
                        ></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="right-col">
            <div class="card spending-card">
              <div class="card-header">
                <h2 class="card-title">Spending Breakdown</h2>
                <span class="card-link">This Month</span>
              </div>
              <div v-if="spendingByCategory.length === 0" class="empty-state">
                <p>No expenses this month</p>
              </div>
              <div v-else class="spending-body">
                <div class="chart-wrap">
                  <Doughnut :data="spendingData" :options="spendingOptions" />
                </div>
                <div class="spending-legend">
                  <div v-for="item in spendingLegend" :key="item.label" class="legend-item">
                    <span class="legend-dot" :style="{ background: item.color }"></span>
                    <span class="legend-label">{{ item.label }}</span>
                    <span class="legend-amount">{{ item.amount }}</span>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="savingsGoal" class="card goal-card">
              <div class="card-header">
                <h2 class="card-title">Savings Goal</h2>
              </div>
              <div class="goal-body">
                <div class="goal-info">
                  <div>
                    <p class="goal-name">{{ savingsGoal.name }}</p>
                    <p class="goal-target">Target: ₹{{ savingsGoal.target.toLocaleString() }}</p>
                  </div>
                  <div class="goal-amt">
                    <p class="goal-current">₹{{ savingsGoal.current.toLocaleString() }}</p>
                    <p class="goal-pct">{{ savingsGoal.percent }}% Completed</p>
                  </div>
                </div>
                <div class="goal-bar-track">
                  <div class="goal-bar-fill" :style="{ width: savingsGoal.percent + '%' }"></div>
                </div>
                <p class="goal-msg">Great job! You're one step closer to your goal. 🎯</p>
              </div>
            </div>

            <div v-else class="card goal-card">
              <div class="empty-state">
                <p>No savings goal set yet</p>
              </div>
            </div>
          </div>
        </div>
      </template>

      <!-- AI Plan Modal -->
      <div v-if="showModal" class="modal-overlay" @click.self="closeModal">
        <div class="modal">
          <button class="modal-close" @click="closeModal">✕</button>

          <div class="modal-header">
            <span class="modal-icon">🤖</span>
            <div>
              <h3 class="modal-title">AI Financial Plan</h3>
              <p class="modal-subtitle">Tell us about your finances and we'll build a plan for you.</p>
            </div>
          </div>

          <div v-if="generating" class="loading-state">
            <div class="spinner"></div>
            <p class="loading-text">Analyzing your finances...</p>
            <p class="loading-sub">AI is crafting your personalized plan</p>
          </div>

          <div v-else-if="aiError" class="error-state">
            <p class="error-text">{{ aiError }}</p>
            <button class="regenerate-btn" @click="aiError = ''">Try Again</button>
          </div>

          <div v-else class="modal-form">
            <div class="field">
              <label class="label">Monthly Income (₹)</label>
              <input v-model="form.monthlyIncome" type="number" placeholder="e.g. 50000" class="input" />
            </div>

            <div class="field-row">
              <div class="field">
                <label class="label">Fixed Expenses (₹)</label>
                <input v-model="form.fixedExpenses" type="number" placeholder="Rent, bills, etc." class="input" />
              </div>
              <div class="field">
                <label class="label">Variable Expenses (₹)</label>
                <input v-model="form.variableExpenses" type="number" placeholder="Food, fun, etc." class="input" />
              </div>
            </div>

            <div class="field">
              <label class="label">Savings Goal (optional)</label>
              <input v-model="form.savingsGoalName" type="text" placeholder="e.g. New Laptop" class="input" />
            </div>

            <div class="field-row">
              <div class="field">
                <label class="label">Goal Amount (₹)</label>
                <input v-model="form.savingsGoalAmount" type="number" placeholder="e.g. 80000" class="input" />
              </div>
              <div class="field">
                <label class="label">Timeline</label>
                <input v-model="form.savingsGoalTimeline" type="text" placeholder="e.g. 6 months" class="input" />
              </div>
            </div>

            <div class="field">
              <label class="label">Risk Tolerance</label>
              <div class="risk-options">
                <button
                  v-for="r in riskOptions"
                  :key="r"
                  type="button"
                  class="risk-btn"
                  :class="{ active: form.riskTolerance === r }"
                  @click="form.riskTolerance = r"
                >
                  {{ r.charAt(0).toUpperCase() + r.slice(1) }}
                </button>
              </div>
            </div>

            <div class="field">
              <label class="label">Financial Priorities</label>
              <div class="priority-grid">
                <button
                  v-for="p in priorityOptions"
                  :key="p"
                  type="button"
                  class="priority-btn"
                  :class="{ active: form.priorities.includes(p) }"
                  @click="togglePriority(p)"
                >
                  {{ p }}
                </button>
              </div>
            </div>

            <button
              class="generate-btn"
              :disabled="generating || !form.monthlyIncome"
              @click="generatePlan"
            >
              {{ generating ? 'Generating...' : '✨ Generate My Plan' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.dashboard {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

@keyframes spin { to { transform: rotate(360deg); } }

.empty-state {
  text-align: center;
  padding: 2rem;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

/* Stats */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}

.stat-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.stat-label { font-size: 0.8125rem; color: var(--color-text-muted); margin-bottom: 0.5rem; }
.stat-value { font-size: 1.375rem; font-weight: 700; }
.stat-sub { font-size: 0.75rem; margin-top: 0.25rem; opacity: 0.8; }

/* ─── Plan Preview Card ─── */
.plan-preview-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  border: 1.5px solid var(--color-accent);
  padding: 1.5rem;
  box-shadow: 0 2px 12px rgba(215, 243, 74, 0.15);
}

.plan-preview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.plan-preview-left {
  display: flex;
  align-items: center;
  gap: 0.875rem;
}

.plan-preview-icon { font-size: 2rem; }

.plan-preview-title {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
}

.plan-preview-sub {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.plan-preview-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.plan-action-btn {
  padding: 0.5rem 1rem;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: var(--font-sans);
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s;
  white-space: nowrap;
}

.plan-action-btn.primary {
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
}

.plan-action-btn.primary:hover {
  background: var(--color-accent-hover);
}

.plan-action-btn.secondary {
  color: var(--color-text-muted);
  background: none;
  border: 1.5px solid var(--color-border);
}

.plan-action-btn.secondary:hover {
  border-color: var(--color-graphite);
  color: var(--color-text);
}

/* Highlights */
.plan-highlights {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
  flex-wrap: wrap;
}

.highlight-chip {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.625rem 1rem;
  background: var(--color-bg);
  border-radius: var(--radius);
  border: 1px solid var(--color-border);
}

.highlight-icon { font-size: 1.125rem; }
.highlight-label { font-size: 0.75rem; color: var(--color-text-muted); }
.highlight-value { font-size: 0.875rem; font-weight: 700; color: var(--color-text); }

/* Full Plan */
.plan-full {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--color-border);
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.plan-section {}

.section-heading {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin-bottom: 1rem;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid var(--color-accent);
}

.section-icon { font-size: 1.25rem; }

.section-title {
  font-size: 0.9375rem;
  font-weight: 700;
  color: var(--color-text);
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

/* ─── Plan Table ─── */
.plan-table-wrap {
  overflow-x: auto;
  border-radius: var(--radius);
  border: 1px solid var(--color-border);
}

.plan-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8125rem;
}

.plan-table thead {
  background: var(--color-graphite);
}

.plan-table th {
  padding: 0.75rem 1rem;
  text-align: left;
  font-weight: 600;
  color: #fff;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.plan-table td {
  padding: 0.625rem 1rem;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text);
}

.plan-table tbody tr:last-child td {
  border-bottom: none;
}

.plan-table tbody tr:nth-child(even) {
  background: rgba(0, 0, 0, 0.02);
}

.plan-table .total-row {
  background: rgba(61, 90, 52, 0.08) !important;
  font-weight: 700;
}

.plan-table .total-row td {
  border-top: 2px solid var(--color-accent);
  padding-top: 0.75rem;
  padding-bottom: 0.75rem;
}

/* ─── Budget List ─── */
.plan-budget-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.budget-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.625rem 0.875rem;
  background: var(--color-bg);
  border-radius: var(--radius);
  border: 1px solid var(--color-border);
  transition: transform 0.15s;
}

.budget-row:hover {
  transform: translateX(4px);
}

.budget-left {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  flex: 1;
  min-width: 0;
}

.budget-emoji { font-size: 1.25rem; flex-shrink: 0; }

.budget-info {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.budget-cat {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
}

.budget-amt {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.budget-right {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  width: 160px;
  flex-shrink: 0;
}

.budget-pct {
  font-size: 0.8125rem;
  font-weight: 700;
  color: var(--color-text);
  width: 36px;
  text-align: right;
  flex-shrink: 0;
}

.budget-bar-track {
  flex: 1;
  height: 8px;
  background: var(--color-border);
  border-radius: 4px;
  overflow: hidden;
}

.budget-bar-fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.6s ease;
}

/* ─── Tips ─── */
.plan-tips {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.tip-item {
  display: flex;
  align-items: flex-start;
  gap: 0.625rem;
  padding: 0.625rem 0.875rem;
  background: var(--color-bg);
  border-radius: var(--radius);
  border-left: 3px solid var(--color-accent);
}

.tip-bullet {
  color: var(--color-accent-hover);
  font-weight: 700;
  flex-shrink: 0;
  margin-top: 0.0625rem;
}

.tip-text {
  font-size: 0.8125rem;
  line-height: 1.6;
  color: var(--color-text);
}

/* ─── Plan Expand Animation ─── */
.plan-expand-enter-active {
  transition: all 0.35s ease;
  overflow: hidden;
}
.plan-expand-leave-active {
  transition: all 0.25s ease;
  overflow: hidden;
}
.plan-expand-enter-from,
.plan-expand-leave-to {
  opacity: 0;
  max-height: 0;
}
.plan-expand-enter-to,
.plan-expand-leave-from {
  opacity: 1;
  max-height: 2000px;
}

/* AI CTA */
.ai-cta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: var(--color-surface);
  border: 1.5px solid var(--color-accent);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
  cursor: pointer;
  transition: box-shadow 0.2s, transform 0.15s;
}

.ai-cta:hover { box-shadow: 0 4px 20px rgba(215, 243, 74, 0.25); transform: translateY(-1px); }

.ai-cta-left { display: flex; align-items: center; gap: 1rem; }
.ai-cta-icon { font-size: 1.75rem; }
.ai-cta-title { font-size: 0.9375rem; font-weight: 600; color: var(--color-text); }
.ai-cta-desc { font-size: 0.8125rem; color: var(--color-text-muted); margin-top: 0.125rem; }

.ai-cta-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.2s;
}

.ai-cta-btn:hover { background: var(--color-accent-hover); }

/* Content Grid */
.content-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; }

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }
.card-title { font-size: 1rem; font-weight: 600; color: var(--color-text); }
.card-link { font-size: 0.8125rem; font-weight: 500; color: var(--color-accent); cursor: pointer; }

.right-col { display: flex; flex-direction: column; gap: 1.5rem; }

.category-list { display: flex; flex-direction: column; gap: 1.25rem; }
.category-group { display: flex; flex-direction: column; gap: 0.5rem; }
.category-row { display: flex; align-items: center; }
.cat-left { display: flex; align-items: center; gap: 0.75rem; flex: 1; }
.cat-icon { font-size: 1.25rem; width: 28px; text-align: center; }
.cat-info { flex: 1; }
.cat-header-row { display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.375rem; }
.cat-name { font-size: 0.875rem; font-weight: 600; color: var(--color-text); }
.cat-amt { font-size: 0.75rem; color: var(--color-text-muted); }
.cat-bar-track { height: 6px; background: var(--color-bg); border-radius: 3px; overflow: hidden; }
.cat-bar-fill { height: 100%; border-radius: 3px; transition: width 0.3s ease; }

.spending-body { display: flex; align-items: center; gap: 1.5rem; }

.chart-wrap {
  width: 180px; height: 180px; flex-shrink: 0;
  padding: 24px; margin: -24px; overflow: visible;
}

.spending-legend { display: flex; flex-direction: column; gap: 0.625rem; flex: 1; }
.legend-item { display: flex; align-items: center; gap: 0.5rem; font-size: 0.8125rem; }
.legend-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.legend-label { color: var(--color-text-muted); flex: 1; }
.legend-amount { font-weight: 600; color: var(--color-text); }

.goal-body { display: flex; flex-direction: column; gap: 0.75rem; }
.goal-info { display: flex; justify-content: space-between; align-items: flex-start; }
.goal-name { font-size: 0.9375rem; font-weight: 600; color: var(--color-text); }
.goal-target { font-size: 0.75rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.goal-amt { text-align: right; }
.goal-current { font-size: 1.125rem; font-weight: 700; color: var(--color-text); }
.goal-pct { font-size: 0.75rem; color: var(--color-text-muted); margin-top: 0.125rem; }
.goal-bar-track { height: 8px; background: var(--color-bg); border-radius: 4px; overflow: hidden; }
.goal-bar-fill { height: 100%; background: var(--color-accent); border-radius: 4px; transition: width 0.3s ease; }
.goal-msg {
  font-size: 0.8125rem; color: var(--color-text-muted);
  background: rgba(215, 243, 74, 0.1); padding: 0.625rem 0.875rem; border-radius: var(--radius);
}

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0, 0, 0, 0.4);
  display: flex; align-items: center; justify-content: center;
  z-index: 1000; animation: fadeIn 0.15s ease;
}

@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.modal {
  background: var(--color-surface); border-radius: var(--radius-lg);
  padding: 2rem; max-width: 560px; width: 94%; max-height: 90vh;
  overflow-y: auto; position: relative; animation: slideUp 0.2s ease;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: translateY(0); }
}

.modal::-webkit-scrollbar { width: 4px; }
.modal::-webkit-scrollbar-thumb { background: rgba(0, 0, 0, 0.12); border-radius: 2px; }

.modal-close {
  position: absolute; top: 1.25rem; right: 1.25rem;
  width: 28px; height: 28px; border-radius: 50%; border: none;
  background: var(--color-bg); color: var(--color-text-muted);
  font-size: 0.75rem; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: background 0.15s, color 0.15s;
}

.modal-close:hover { background: rgba(211, 47, 47, 0.1); color: #d32f2f; }
.modal-header { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.75rem; }
.modal-icon { font-size: 2rem; }
.modal-title { font-size: 1.125rem; font-weight: 700; color: var(--color-text); }
.modal-subtitle { font-size: 0.8125rem; color: var(--color-text-muted); margin-top: 0.125rem; }

.modal-form { display: flex; flex-direction: column; gap: 1rem; }
.field { display: flex; flex-direction: column; gap: 0.375rem; }
.field-row { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.label { font-size: 0.8125rem; font-weight: 500; color: var(--color-text); }

.input {
  padding: 0.625rem 0.875rem; font-size: 0.875rem; font-family: var(--font-sans);
  color: var(--color-text); background: var(--color-bg);
  border: 1.5px solid var(--color-border); border-radius: var(--radius);
  outline: none; transition: border-color 0.2s;
}

.input:focus { border-color: var(--color-graphite); }
.input::placeholder { color: var(--color-grey); }

.risk-options { display: flex; gap: 0.5rem; }

.risk-btn {
  flex: 1; padding: 0.5rem; font-size: 0.8125rem; font-weight: 500;
  font-family: var(--font-sans); color: var(--color-text-muted);
  background: var(--color-bg); border: 1.5px solid transparent;
  border-radius: var(--radius); cursor: pointer; transition: all 0.15s; text-align: center;
}

.risk-btn.active { background: var(--color-surface); border-color: var(--color-graphite); color: var(--color-text); }

.priority-grid { display: flex; flex-wrap: wrap; gap: 0.5rem; }

.priority-btn {
  padding: 0.4375rem 0.875rem; font-size: 0.75rem; font-weight: 500;
  font-family: var(--font-sans); color: var(--color-text-muted);
  background: var(--color-bg); border: 1.5px solid transparent;
  border-radius: 999px; cursor: pointer; transition: all 0.15s; white-space: nowrap;
}

.priority-btn.active { background: var(--color-surface); border-color: var(--color-graphite); color: var(--color-text); }

.generate-btn {
  padding: 0.75rem; font-size: 0.9375rem; font-weight: 600;
  font-family: var(--font-sans); color: var(--color-graphite);
  background: var(--color-accent); border: none; border-radius: var(--radius);
  cursor: pointer; margin-top: 0.5rem; transition: background 0.2s, opacity 0.2s;
}

.generate-btn:hover { background: var(--color-accent-hover); }
.generate-btn:disabled { opacity: 0.5; cursor: not-allowed; }

.loading-state { display: flex; flex-direction: column; align-items: center; gap: 0.75rem; padding: 2rem 0; }

.spinner {
  width: 36px; height: 36px; border: 3px solid var(--color-border);
  border-top-color: var(--color-graphite); border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.loading-text { font-size: 0.9375rem; font-weight: 600; color: var(--color-text); }
.loading-sub { font-size: 0.8125rem; color: var(--color-text-muted); }

.regenerate-btn {
  margin-top: 1.25rem; padding: 0.625rem 1.25rem; font-size: 0.8125rem;
  font-weight: 500; font-family: var(--font-sans); color: var(--color-text-muted);
  background: none; border: 1.5px solid var(--color-border); border-radius: var(--radius);
  cursor: pointer; transition: border-color 0.2s, color 0.2s;
}

.regenerate-btn:hover { border-color: var(--color-graphite); color: var(--color-text); }

.error-state { text-align: center; padding: 1.5rem 0; }
.error-text { font-size: 0.875rem; color: #d32f2f; margin-bottom: 1rem; }
</style>
