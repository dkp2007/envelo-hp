import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthView from '@/views/AuthView.vue'
import DashboardView from '@/views/DashboardView.vue'
import EmailVerifyView from '@/views/EmailVerifyView.vue'
import EnvelopesView from '@/views/EnvelopesView.vue'
import TransactionsView from '@/views/TransactionsView.vue'
import AddExpenseView from '@/views/AddExpenseView.vue'
import SavingsGoalsView from '@/views/SavingsGoalsView.vue'
import AnalyticsView from '@/views/AnalyticsView.vue'
import ReportsView from '@/views/ReportsView.vue'
import SettingsView from '@/views/SettingsView.vue'
import HelpSupportView from '@/views/HelpSupportView.vue'
import StressTestView from '@/views/StressTestView.vue'
import PrivacyPolicyView from '@/views/PrivacyPolicyView.vue'
import TermsOfServiceView from '@/views/TermsOfServiceView.vue'
import HomePageView from '@/views/HomePageView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomePageView,
      meta: { title: 'Envelo — Budget Smarter, Save More' },
    },
    {
      path: '/dashboard',
      name: 'dashboard',
      component: DashboardView,
      meta: { requiresAuth: true, title: 'Overview' },
    },
    {
      path: '/envelopes',
      name: 'envelopes',
      component: EnvelopesView,
      meta: { requiresAuth: true, title: 'Envelopes' },
    },
    {
      path: '/transactions',
      name: 'transactions',
      component: TransactionsView,
      meta: { requiresAuth: true, title: 'Transactions' },
    },
    {
      path: '/add-expense',
      name: 'add-expense',
      component: AddExpenseView,
      meta: { requiresAuth: true, title: 'Add Expense' },
    },
    {
      path: '/savings-goals',
      name: 'savings-goals',
      component: SavingsGoalsView,
      meta: { requiresAuth: true, title: 'Savings Goals' },
    },
    {
      path: '/analytics',
      name: 'analytics',
      component: AnalyticsView,
      meta: { requiresAuth: true, title: 'Analytics' },
    },
    {
      path: '/reports',
      name: 'reports',
      component: ReportsView,
      meta: { requiresAuth: true, title: 'Reports' },
    },
    {
      path: '/stress-test',
      name: 'stress-test',
      component: StressTestView,
      meta: { requiresAuth: true, title: 'Stress Test' },
    },
    {
      path: '/settings',
      name: 'settings',
      component: SettingsView,
      meta: { requiresAuth: true, title: 'Settings' },
    },
    {
      path: '/help',
      name: 'help',
      component: HelpSupportView,
      meta: { requiresAuth: true, title: 'Help & Support' },
    },
    {
      path: '/privacypolicy',
      name: 'privacy-policy',
      component: PrivacyPolicyView,
      meta: { title: 'Privacy Policy' },
    },
    {
      path: '/termsofservice',
      name: 'terms-of-service',
      component: TermsOfServiceView,
      meta: { title: 'Terms of Service' },
    },
    {
      path: '/auth',
      name: 'auth',
      component: AuthView,
      meta: { guest: true },
    },
    {
      path: '/auth/verify',
      name: 'email-verify',
      component: EmailVerifyView,
    },
  ],
})

router.beforeEach(async (to) => {
  const auth = useAuthStore()

  if (auth.loading) {
    await new Promise((resolve) => {
      const unwatch = auth.$subscribe(() => {
        if (!auth.loading) {
          unwatch()
          resolve()
        }
      })
    })
  }

  if (to.meta.requiresAuth && !auth.isLoggedIn) {
    return { name: 'auth' }
  }

  if (to.meta.guest && auth.isLoggedIn) {
    return { name: 'dashboard' }
  }

  if (to.name === 'home' && auth.isLoggedIn) {
    return { name: 'dashboard' }
  }
})

export default router
