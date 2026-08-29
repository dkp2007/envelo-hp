<script setup>
import { ref, computed, onMounted } from 'vue'
import { Doughnut } from 'vue-chartjs'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { groq } from '@/lib/groq'
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
    total: c.spent, // no budget set yet
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
const aiResult = ref('')
const aiError = ref('')

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

async function generatePlan() {
  generating.value = true
  aiResult.value = ''
  aiError.value = ''

  const prompt = `You are a personal finance advisor. Based on the user's financial details below, create a personalized monthly expenditure and savings plan. Be specific with numbers. Use INR (₹). Keep it concise but actionable.

User Details:
- Monthly Income: ₹${form.value.monthlyIncome || 'Not specified'}
- Fixed Monthly Expenses: ₹${form.value.fixedExpenses || 'Not specified'}
- Variable Monthly Expenses: ₹${form.value.variableExpenses || 'Not specified'}
- Current Savings Goal: ${form.value.savingsGoalName || 'None specified'} — Target: ₹${form.value.savingsGoalAmount || 'N/A'} — Timeline: ${form.value.savingsGoalTimeline || 'N/A'}
- Risk Tolerance: ${form.value.riskTolerance}
- Financial Priorities: ${form.value.priorities.length ? form.value.priorities.join(', ') : 'None selected'}

Format your response in clear sections with markdown headings. Include:
1. **Income & Expense Summary**
2. **Recommended Budget Split** (with percentages and amounts for each category)
3. **Savings Strategy** (how to reach their goal)
4. **Key Tips** (3–5 actionable tips)

Do NOT use code blocks. Use **bold** for section titles and bullet points for items.`

  try {
    const res = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.7,
      max_tokens: 1500,
    })
    aiResult.value = res.choices[0]?.message?.content || 'No response generated.'
  } catch (e) {
    const msg = e.message || 'Something went wrong. Please try again.'
    aiError.value = msg
    toast.error(msg)
  } finally {
    generating.value = false
  }
}

function closeModal() {
  showModal.value = false
  aiResult.value = ''
  aiError.value = ''
}

function formatResult(text) {
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n- /g, '\n<li>')
    .replace(/\n(\d+)\. /g, '\n<li>')
    .replace(/\n/g, '<br>')
    .replace(/<li>/g, '<li class="result-li">')
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

        <!-- AI Plan CTA -->
        <div class="ai-cta" @click="showModal = true">
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

          <div v-if="!aiResult && !aiError" class="modal-form">
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

          <div v-if="generating" class="loading-state">
            <div class="spinner"></div>
            <p class="loading-text">Analyzing your finances...</p>
          </div>

          <div v-if="aiResult && !generating" class="modal-result">
            <div class="result-content" v-html="formatResult(aiResult)"></div>
            <button class="regenerate-btn" @click="aiResult = ''; form.monthlyIncome = form.monthlyIncome">← Ask Again</button>
          </div>

          <div v-if="aiError && !generating" class="error-state">
            <p class="error-text">{{ aiError }}</p>
            <button class="regenerate-btn" @click="aiError = ''">Try Again</button>
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

.loading-page {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 4rem 0;
  color: var(--color-text-muted);
  font-size: 0.875rem;
}

.spinner-lg {
  width: 32px;
  height: 32px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-graphite);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
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

.loading-state { display: flex; flex-direction: column; align-items: center; gap: 1rem; padding: 2rem 0; }

.spinner {
  width: 32px; height: 32px; border: 3px solid var(--color-border);
  border-top-color: var(--color-graphite); border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.loading-text { font-size: 0.875rem; color: var(--color-text-muted); }

.modal-result { animation: fadeIn 0.3s ease; }
.result-content { font-size: 0.875rem; line-height: 1.7; color: var(--color-text); }
.result-content :deep(strong) { display: block; font-size: 0.9375rem; font-weight: 700; margin-top: 1rem; margin-bottom: 0.375rem; color: var(--color-text); }
.result-content :deep(.result-li) { display: block; padding-left: 0.75rem; margin-bottom: 0.25rem; }

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
