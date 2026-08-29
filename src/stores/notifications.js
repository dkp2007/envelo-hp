import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth'

export const useNotificationStore = defineStore('notifications', () => {
  const notifications = ref([])
  const loading = ref(false)
  const auth = useAuthStore()

  const unreadCount = computed(() => notifications.value.filter(n => !n.read).length)
  const unreadNotifications = computed(() => notifications.value.filter(n => !n.read))

  // Fetch all notifications
  async function fetchAll() {
    if (!auth.user) return
    loading.value = true
    const { data } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', auth.user.id)
      .order('created_at', { ascending: false })
      .limit(50)
    notifications.value = data || []
    loading.value = false
  }

  // Mark single notification as read
  async function markRead(id) {
    const notif = notifications.value.find(n => n.id === id)
    if (notif && !notif.read) {
      notif.read = true
      await supabase.from('notifications').update({ read: true }).eq('id', id)
    }
  }

  // Mark all as read
  async function markAllRead() {
    if (!auth.user) return
    notifications.value.forEach(n => { n.read = true })
    await supabase.from('notifications').update({ read: true }).eq('user_id', auth.user.id).eq('read', false)
  }

  // Delete a notification
  async function remove(id) {
    notifications.value = notifications.value.filter(n => n.id !== id)
    await supabase.from('notifications').delete().eq('id', id)
  }

  // Clear all
  async function clearAll() {
    if (!auth.user) return
    notifications.value = []
    await supabase.from('notifications').delete().eq('user_id', auth.user.id)
  }

  // Generate alerts from real financial data
  async function generateAlerts() {
    if (!auth.user) return

    // Fetch current data
    const [txRes, budRes, goalRes] = await Promise.all([
      supabase.from('transactions')
        .select('id, name, amount, type, date, categories(name, icon)')
        .eq('user_id', auth.user.id)
        .order('date', { ascending: false })
        .limit(50),
      supabase.from('budgets')
        .select('id, category_id, amount, spent, month, categories(name, icon)')
        .eq('user_id', auth.user.id),
      supabase.from('savings_goals')
        .select('id, name, target, current, icon')
        .eq('user_id', auth.user.id),
    ])

    const transactions = txRes.data || []
    const budgets = budRes.data || []
    const goals = goalRes.data || []
    const alerts = []

    // Current month transactions
    const now = new Date()
    const currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
    const monthTx = transactions.filter(t => t.date && t.date.startsWith(currentMonth))
    const monthIncome = monthTx.filter(t => t.type === 'income').reduce((s, t) => s + Math.abs(Number(t.amount)), 0)
    const monthExpenses = monthTx.filter(t => t.type === 'expense').reduce((s, t) => s + Math.abs(Number(t.amount)), 0)

    // Budget alerts
    for (const b of budgets) {
      if (!b.amount || b.amount <= 0) continue
      const pct = Math.round((b.spent / b.amount) * 100)
      const catName = b.categories?.name || 'Unknown'
      const catIcon = b.categories?.icon || '📦'

      if (pct >= 100) {
        alerts.push({
          type: 'budget_alert',
          title: `${catIcon} ${catName} budget exceeded!`,
          message: `You've spent ₹${b.spent.toLocaleString()} out of ₹${b.amount.toLocaleString()} budget (${pct}% used). Consider reducing spending in this category.`,
          icon: '🚨',
          action_url: '/analytics',
        })
      } else if (pct >= 80) {
        alerts.push({
          type: 'spending_warning',
          title: `${catIcon} ${catName} budget at ${pct}%`,
          message: `₹${b.spent.toLocaleString()} of ₹${b.amount.toLocaleString()} spent. You have ₹${(b.amount - b.spent).toLocaleString()} remaining.`,
          icon: '⚠️',
          action_url: '/analytics',
        })
      }
    }

    // Savings goal alerts
    for (const g of goals) {
      const pct = g.target > 0 ? Math.round((g.current / g.target) * 100) : 0
      if (pct >= 100) {
        alerts.push({
          type: 'savings_milestone',
          title: `${g.icon || '🎯'} Goal reached: ${g.name}!`,
          message: `Congratulations! You've saved ₹${g.current.toLocaleString()} towards your ${g.name} goal.`,
          icon: '🎉',
          action_url: '/savings-goals',
        })
      } else if (pct >= 75) {
        alerts.push({
          type: 'goal_progress',
          title: `${g.icon || '🎯'} ${g.name} — ${pct}% complete`,
          message: `₹${g.current.toLocaleString()} of ₹${g.target.toLocaleString()} saved. Just ₹${(g.target - g.current).toLocaleString()} to go!`,
          icon: '📈',
          action_url: '/savings-goals',
        })
      } else if (pct >= 50) {
        alerts.push({
          type: 'goal_progress',
          title: `${g.icon || '🎯'} ${g.name} — halfway there!`,
          message: `₹${g.current.toLocaleString()} of ₹${g.target.toLocaleString()} saved (${pct}%). Keep going!`,
          icon: '💪',
          action_url: '/savings-goals',
        })
      }
    }

    // Income/expense ratio alert
    if (monthIncome > 0) {
      const savingsRate = Math.round(((monthIncome - monthExpenses) / monthIncome) * 100)
      if (savingsRate < 10 && monthExpenses > 0) {
        alerts.push({
          type: 'spending_warning',
          title: '📉 Low savings rate this month',
          message: `Your savings rate is ${savingsRate}% (₹${(monthIncome - monthExpenses).toLocaleString()} saved from ₹${monthIncome.toLocaleString()} income). Try to save at least 20%.`,
          icon: '⚠️',
          action_url: '/stress-test',
        })
      } else if (savingsRate >= 30) {
        alerts.push({
          type: 'ai_tip',
          title: '🌟 Great savings rate!',
          message: `You're saving ${savingsRate}% of your income this month. That's well above the 20% target. Consider investing the surplus.`,
          icon: '💡',
          action_url: '/analytics',
        })
      }
    }

    // Large transaction alert
    const largeTx = monthTx.filter(t => t.type === 'expense' && Math.abs(Number(t.amount)) > monthIncome * 0.15)
    for (const tx of largeTx.slice(0, 2)) {
      alerts.push({
        type: 'spending_warning',
        title: `💸 Large expense: ${tx.name}`,
        message: `₹${Math.abs(Number(tx.amount)).toLocaleString()} spent on ${tx.categories?.name || 'Unknown'}. That's ${Math.round(Math.abs(Number(tx.amount)) / monthIncome * 100)}% of your monthly income.`,
        icon: '💸',
      })
    }

    // No alerts? Add a system message
    if (alerts.length === 0 && monthIncome > 0) {
      alerts.push({
        type: 'system',
        title: '✅ Everything looks good!',
        message: 'Your budgets are on track and your savings goals are progressing well.',
        icon: '✅',
      })
    }

    // Check for existing alerts to avoid duplicates (compare title + today's date)
    const today = now.toISOString().split('T')[0]
    const existingTitles = new Set(
      notifications.value
        .filter(n => n.created_at && n.created_at.startsWith(today))
        .map(n => n.title)
    )

    const newAlerts = alerts.filter(a => !existingTitles.has(a.title))

    if (newAlerts.length > 0) {
      const { data: inserted } = await supabase
        .from('notifications')
        .insert(newAlerts.map(a => ({
          user_id: auth.user.id,
          type: a.type,
          title: a.title,
          message: a.message,
          icon: a.icon,
          action_url: a.action_url || null,
        })))
        .select()

      if (inserted) {
        notifications.value = [...inserted, ...notifications.value]
      }
    }
  }

  return {
    notifications, loading, unreadCount, unreadNotifications,
    fetchAll, markRead, markAllRead, remove, clearAll, generateAlerts,
  }
})
