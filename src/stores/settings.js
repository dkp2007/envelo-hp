import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from './auth'

export const useSettingsStore = defineStore('settings', () => {
  const loading = ref(false)
  const saving = ref(false)
  const saved = ref(false)

  const phone = ref('')
  const country = ref('India')
  const currency = ref('₹ INR')
  const language = ref('English')
  const timezone = ref('Asia/Kolkata')
  const dateFormat = ref('DD/MM/YYYY')

  const emailNotifications = ref(true)
  const budgetAlerts = ref(true)
  const savingsReminders = ref(false)
  const weeklyReport = ref(true)

  async function load() {
    const auth = useAuthStore()
    if (!auth.user) return
    loading.value = true

    const { data } = await supabase
      .from('user_settings')
      .select('*')
      .eq('id', auth.user.id)
      .single()

    if (data) {
      phone.value = data.phone || ''
      country.value = data.country || 'India'
      currency.value = data.currency || '₹ INR'
      language.value = data.language || 'English'
      timezone.value = data.timezone || 'Asia/Kolkata'
      dateFormat.value = data.date_format || 'DD/MM/YYYY'
      emailNotifications.value = data.email_notifications ?? true
      budgetAlerts.value = data.budget_alerts ?? true
      savingsReminders.value = data.savings_reminders ?? false
      weeklyReport.value = data.weekly_report ?? true
    }

    loading.value = false
  }

  async function save() {
    const auth = useAuthStore()
    if (!auth.user) return

    saving.value = true
    saved.value = false

    const { error } = await supabase
      .from('user_settings')
      .upsert({
        id: auth.user.id,
        phone: phone.value,
        country: country.value,
        currency: currency.value,
        language: language.value,
        timezone: timezone.value,
        date_format: dateFormat.value,
        email_notifications: emailNotifications.value,
        budget_alerts: budgetAlerts.value,
        savings_reminders: savingsReminders.value,
        weekly_report: weeklyReport.value,
        updated_at: new Date().toISOString(),
      })

    saving.value = false

    if (!error) {
      saved.value = true
      setTimeout(() => { saved.value = false }, 2000)
    }
  }

  async function saveProfile(fields) {
    const auth = useAuthStore()
    if (!auth.user) return

    saving.value = true
    saved.value = false

    const { error } = await supabase
      .from('profiles')
      .upsert({
        id: auth.user.id,
        full_name: fields.fullName,
        avatar_url: fields.avatarUrl,
      })

    saving.value = false

    if (!error) {
      saved.value = true
      setTimeout(() => { saved.value = false }, 2000)
    }
  }

  return {
    loading,
    saving,
    saved,
    phone,
    country,
    currency,
    language,
    timezone,
    dateFormat,
    emailNotifications,
    budgetAlerts,
    savingsReminders,
    weeklyReport,
    load,
    save,
    saveProfile,
  }
})
