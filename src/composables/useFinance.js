import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase.js'
import { useAuthStore } from '@/stores/auth.js'

const transactions = ref([])
const categories = ref([])
const budgets = ref([])
const savingsGoals = ref([])
const loading = ref(true)

// Color palette for categories
const CATEGORY_COLORS = {
  Rent: '#202124', Food: '#D7F34A', Fun: '#4285F4', Savings: '#2e7d32',
  Entertainment: '#a78bfa', Shopping: '#fb923c', Utilities: '#f472b6',
  Salary: '#2e7d32', Freelance: '#4285F4', 'Other Income': '#757575',
  default: '#9e9e9e',
}

export function useFinance() {
  const auth = useAuthStore()

  // ── Fetch all data ──
  async function fetchAll() {
    if (!auth.user) return
    loading.value = true

    try {
    const [txRes, catRes, budRes, goalRes] = await Promise.all([
      supabase
        .from('transactions')
        .select('id, name, amount, type, date, notes, bill_path, merchant, category_id, categories(name, icon, color, parent_id, type)')
        .eq('user_id', auth.user.id)
        .order('date', { ascending: false }),
      supabase
        .from('categories')
        .select('id, name, icon, color, parent_id, type')
        .eq('user_id', auth.user.id),
      supabase
        .from('budgets')
        .select('id, category_id, amount, spent, month')
        .eq('user_id', auth.user.id),
      supabase
        .from('savings_goals')
        .select('id, name, target, current, icon, deadline')
        .eq('user_id', auth.user.id),
    ])

    transactions.value = txRes.data || []
    categories.value = catRes.data || []
    budgets.value = budRes.data || []
    savingsGoals.value = goalRes.data || []
    } catch (err) {
      console.error('Failed to fetch finance data:', err)
    } finally {
      loading.value = false
    }
  }

  // ── Delete transaction ──
  async function deleteTransaction(id) {
    const { error } = await supabase.from('transactions').delete().eq('id', id)
    if (error) throw error
    transactions.value = transactions.value.filter(t => t.id !== id)
  }

  // ── Parent categories (no parent_id) ──
  const parentCategories = computed(() =>
    categories.value.filter(c => !c.parent_id && c.type === 'expense')
  )

  const parentIncomeCategories = computed(() =>
    categories.value.filter(c => !c.parent_id && c.type === 'income')
  )

  function subCategoriesOf(parentId) {
    return categories.value.filter(c => c.parent_id === parentId)
  }

  function getCategoryColor(name) {
    return CATEGORY_COLORS[name] || CATEGORY_COLORS.default
  }

  // ── Current month transactions ──
  const currentMonthTransactions = computed(() => {
    const now = new Date()
    const y = now.getFullYear()
    const m = now.getMonth()
    return transactions.value.filter(t => {
      const d = new Date(t.date)
      return d.getFullYear() === y && d.getMonth() === m
    })
  })

  // ── Total income / expense / net (all time) ──
  const totalIncome = computed(() =>
    transactions.value
      .filter(t => t.type === 'income')
      .reduce((s, t) => s + Math.abs(Number(t.amount)), 0)
  )

  const totalExpenses = computed(() =>
    transactions.value
      .filter(t => t.type === 'expense')
      .reduce((s, t) => s + Math.abs(Number(t.amount)), 0)
  )

  const netBalance = computed(() => totalIncome.value - totalExpenses.value)

  // ── Current month income / expense ──
  const monthIncome = computed(() =>
    currentMonthTransactions.value
      .filter(t => t.type === 'income')
      .reduce((s, t) => s + Math.abs(Number(t.amount)), 0)
  )

  const monthExpenses = computed(() =>
    currentMonthTransactions.value
      .filter(t => t.type === 'expense')
      .reduce((s, t) => s + Math.abs(Number(t.amount)), 0)
  )

  const monthSavings = computed(() => monthIncome.value - monthExpenses.value)

  const monthSavingsRate = computed(() =>
    monthIncome.value > 0 ? Math.round((monthSavings.value / monthIncome.value) * 100) : 0
  )

  // ── Spending by parent category (current month) ──
  const spendingByCategory = computed(() => {
    const map = {}
    currentMonthTransactions.value
      .filter(t => t.type === 'expense')
      .forEach(t => {
        const catName = t.categories?.name || 'Other'
        if (!map[catName]) {
          map[catName] = {
            name: catName,
            icon: t.categories?.icon || '📦',
            color: t.categories?.color || getCategoryColor(catName),
            spent: 0,
          }
        }
        map[catName].spent += Math.abs(Number(t.amount))
      })
    return Object.values(map).sort((a, b) => b.spent - a.spent)
  })

  // ── Monthly aggregations (for charts) ──
  const monthlyData = computed(() => {
    const map = {}
    transactions.value.forEach(t => {
      const d = new Date(t.date)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
      const short = d.toLocaleString('en-IN', { month: 'short' })
      if (!map[key]) {
        map[key] = { key, short, income: 0, expenses: 0, categories: {} }
      }
      const amt = Math.abs(Number(t.amount))
      if (t.type === 'income') {
        map[key].income += amt
      } else {
        map[key].expenses += amt
        const catName = t.categories?.name || 'Other'
        map[key].categories[catName] = (map[key].categories[catName] || 0) + amt
      }
    })
    // Add saved
    Object.values(map).forEach(m => { m.saved = m.income - m.expenses })
    // Sort by key ascending
    return Object.values(map).sort((a, b) => a.key.localeCompare(b.key))
  })

  // ── Category aggregation across filtered months ──
  function categoryAggForMonths(months) {
    const totals = {}
    months.forEach(m => {
      Object.entries(m.categories).forEach(([cat, amt]) => {
        totals[cat] = (totals[cat] || 0) + amt
      })
    })
    return totals
  }

  // ── Top expenses (current month) ──
  const topExpenses = computed(() => {
    const total = spendingByCategory.value.reduce((s, c) => s + c.spent, 0)
    return spendingByCategory.value.map(c => ({
      name: c.name,
      amount: c.spent,
      pct: total > 0 ? Math.round((c.spent / total) * 100) : 0,
      color: c.color,
    }))
  })

  // ── Budgets with spent amounts ──
  const currentMonthKey = computed(() => {
    const now = new Date()
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`
  })

  const budgetData = computed(() => {
    return budgets.value
      .filter(b => b.month === currentMonthKey.value || !b.month)
      .map(b => {
        const cat = categories.value.find(c => c.id === b.category_id)
        return {
          id: b.id,
          category_id: b.category_id,
          name: cat?.name || 'Unknown',
          icon: cat?.icon || '📦',
          color: cat?.color || '#9e9e9e',
          budget: Number(b.amount),
          spent: Number(b.spent) || 0,
        }
      })
  })

  return {
    // State
    transactions, categories, budgets, savingsGoals, loading,
    // Actions
    fetchAll, deleteTransaction,
    // Computed
    parentCategories, parentIncomeCategories, subCategoriesOf, getCategoryColor,
    currentMonthTransactions,
    totalIncome, totalExpenses, netBalance,
    monthIncome, monthExpenses, monthSavings, monthSavingsRate,
    spendingByCategory, topExpenses,
    monthlyData, categoryAggForMonths,
    budgetData, currentMonthKey,
  }
}
