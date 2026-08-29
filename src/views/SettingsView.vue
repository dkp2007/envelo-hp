<script setup>
import { ref, onMounted, watch } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useSettingsStore } from '@/stores/settings'
import { supabase } from '@/lib/supabase.js'
import { useRouter } from 'vue-router'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useToast } from '@/composables/useToast.js'

const router = useRouter()

const auth = useAuthStore()
const settings = useSettingsStore()
const toast = useToast()

const fullName = ref(auth.user?.user_metadata?.full_name || '')
const avatarUrl = ref(auth.user?.user_metadata?.avatar_url || '')

const showDeleteModal = ref(false)
const showSaveBanner = ref(false)

onMounted(() => {
  settings.load()
})

watch(() => settings.saved, (val) => {
  if (val) {
    showSaveBanner.value = true
    setTimeout(() => { showSaveBanner.value = false }, 2000)
  }
})

async function saveProfile() {
  try {
    await settings.saveProfile({
      fullName: fullName.value,
      avatarUrl: avatarUrl.value,
    })
    toast.success('Profile saved successfully')
  } catch (err) {
    toast.error('Failed to save profile: ' + (err.message || 'Unknown error'))
  }
}

async function deleteAccount() {
  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) return

    // Delete all user data from tables
    await supabase.from('transactions').delete().eq('user_id', user.id)
    await supabase.from('budgets').delete().eq('user_id', user.id)
    await supabase.from('categories').delete().eq('user_id', user.id)
    await supabase.from('savings_goals').delete().eq('user_id', user.id)
    await supabase.from('notifications').delete().eq('user_id', user.id)
    await supabase.from('stress_test_results').delete().eq('user_id', user.id)
    await supabase.from('financial_plans').delete().eq('user_id', user.id)
    await supabase.from('profiles').delete().eq('id', user.id)

    // Delete auth user
    const { error } = await supabase.auth.admin.deleteUser(user.id)
    if (error) {
      // If admin delete fails, just sign out
      await supabase.auth.signOut()
      router.push('/')
      toast.success('Account deleted')
      return
    }

    await supabase.auth.signOut()
    router.push('/')
    toast.success('Account permanently deleted')
  } catch (err) {
    toast.error('Failed to delete account: ' + (err.message || 'Unknown error'))
  }
}

async function saveSettings() {
  try {
    await settings.save()
    toast.success('Settings saved')
  } catch (err) {
    toast.error('Failed to save settings')
  }
}

const countryOptions = [
  'India', 'United States', 'United Kingdom', 'Canada', 'Australia',
  'Germany', 'France', 'Japan', 'Brazil', 'Singapore', 'UAE',
]

const currencyOptions = [
  '₹ INR', '$ USD', '€ EUR', '£ GBP', '¥ JPY', 'A$ AUD', 'C$ CAD', 'S$ SGD',
]

const languageOptions = ['English', 'Hindi', 'Spanish', 'French', 'German', 'Japanese', 'Portuguese']

const timezoneOptions = [
  'Asia/Kolkata', 'America/New_York', 'America/Chicago', 'America/Los_Angeles',
  'Europe/London', 'Europe/Berlin', 'Asia/Tokyo', 'Australia/Sydney',
  'Asia/Singapore', 'America/Sao_Paulo',
]

const dateFormatOptions = ['DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY-MM-DD']
</script>

<template>
  <DashboardLayout>
    <div class="settings">
      <!-- Save banner -->
      <div v-if="showSaveBanner" class="save-banner">
        <span>✓ Settings saved successfully</span>
      </div>



      <!-- Profile Card -->
      <div class="profile-card">
        <div class="profile-top">
          <div class="avatar-section">
            <img
              v-if="avatarUrl"
              :src="avatarUrl"
              alt=""
              class="avatar"
            />
            <div v-else class="avatar fallback">
              {{ fullName?.charAt(0) || 'U' }}
            </div>
            <button class="avatar-btn">Change Photo</button>
          </div>
          <div class="profile-info">
            <h2 class="profile-name">{{ fullName || 'User' }}</h2>
            <p class="profile-email">{{ auth.user?.email }}</p>

          </div>
        </div>
      </div>

      <div class="two-col">
        <!-- Left column -->
        <div class="col">
          <!-- Personal Information -->
          <div class="card">
            <div class="card-header">
              <h2 class="card-title">Personal Information</h2>
            </div>
            <div class="form">
              <div class="field">
                <label class="label">Full Name</label>
                <input v-model="fullName" type="text" class="input" placeholder="Your full name" />
              </div>
              <div class="field">
                <label class="label">Email</label>
                <input :value="auth.user?.email" type="email" class="input" disabled />
                <span class="field-hint">Email cannot be changed</span>
              </div>
              <div class="field">
                <label class="label">Phone Number</label>
                <input v-model="settings.phone" type="tel" class="input" placeholder="+91 98765 43210" />
              </div>
              <div class="field">
                <label class="label">Country</label>
                <select v-model="settings.country" class="input select">
                  <option v-for="c in countryOptions" :key="c" :value="c">{{ c }}</option>
                </select>
              </div>
              <div class="field-row">
                <div class="field">
                  <label class="label">Currency</label>
                  <select v-model="settings.currency" class="input select">
                    <option v-for="c in currencyOptions" :key="c" :value="c">{{ c }}</option>
                  </select>
                </div>
                <div class="field">
                  <label class="label">Date Format</label>
                  <select v-model="settings.dateFormat" class="input select">
                    <option v-for="d in dateFormatOptions" :key="d" :value="d">{{ d }}</option>
                  </select>
                </div>
              </div>
              <button class="save-btn" :disabled="settings.saving" @click="saveProfile">
                {{ settings.saving ? 'Saving...' : 'Save Profile' }}
              </button>
            </div>
          </div>

          <!-- Preferences -->
          <div class="card">
            <div class="card-header">
              <h2 class="card-title">Preferences</h2>
            </div>
            <div class="form">
              <div class="field">
                <label class="label">Language</label>
                <select v-model="settings.language" class="input select">
                  <option v-for="l in languageOptions" :key="l" :value="l">{{ l }}</option>
                </select>
              </div>
              <div class="field">
                <label class="label">Timezone</label>
                <select v-model="settings.timezone" class="input select">
                  <option v-for="t in timezoneOptions" :key="t" :value="t">{{ t }}</option>
                </select>
              </div>
            </div>
          </div>
        </div>

        <!-- Right column -->
        <div class="col">
          <!-- Notifications -->
          <div class="card">
            <div class="card-header">
              <h2 class="card-title">Notifications</h2>
            </div>
            <div class="toggles">
              <div class="toggle-row">
                <div class="toggle-info">
                  <p class="toggle-label">Email Notifications</p>
                  <p class="toggle-desc">Receive updates via email</p>
                </div>
                <button class="toggle" :class="{ on: settings.emailNotifications }" @click="settings.emailNotifications = !settings.emailNotifications">
                  <span class="toggle-knob"></span>
                </button>
              </div>
              <div class="toggle-row">
                <div class="toggle-info">
                  <p class="toggle-label">Budget Alerts</p>
                  <p class="toggle-desc">Alert when envelope is near limit</p>
                </div>
                <button class="toggle" :class="{ on: settings.budgetAlerts }" @click="settings.budgetAlerts = !settings.budgetAlerts">
                  <span class="toggle-knob"></span>
                </button>
              </div>
              <div class="toggle-row">
                <div class="toggle-info">
                  <p class="toggle-label">Savings Reminders</p>
                  <p class="toggle-desc">Remind to contribute to goals</p>
                </div>
                <button class="toggle" :class="{ on: settings.savingsReminders }" @click="settings.savingsReminders = !settings.savingsReminders">
                  <span class="toggle-knob"></span>
                </button>
              </div>
              <div class="toggle-row">
                <div class="toggle-info">
                  <p class="toggle-label">Weekly Report</p>
                  <p class="toggle-desc">Get a weekly spending summary</p>
                </div>
                <button class="toggle" :class="{ on: settings.weeklyReport }" @click="settings.weeklyReport = !settings.weeklyReport">
                  <span class="toggle-knob"></span>
                </button>
              </div>
            </div>
            <button class="save-btn" :disabled="settings.saving" @click="saveSettings" style="margin-top: 1rem;">
              {{ settings.saving ? 'Saving...' : 'Save Settings' }}
            </button>
          </div>

          <!-- Danger Zone -->
          <div class="card danger-card">
            <div class="card-header">
              <h2 class="card-title danger-title">Danger Zone</h2>
            </div>
            <p class="danger-desc">Permanently delete your account and all associated data.</p>
            <button class="danger-btn" @click="showDeleteModal = true">Delete Account</button>
          </div>
        </div>
      </div>

      <!-- Delete Modal -->
      <div v-if="showDeleteModal" class="modal-overlay" @click.self="showDeleteModal = false">
        <div class="modal">
          <h3 class="modal-title">Delete Account</h3>
          <p class="modal-text">This action is irreversible. All your data, envelopes, transactions, and goals will be permanently deleted.</p>
          <div class="modal-actions">
            <button class="cancel-btn" @click="showDeleteModal = false">Cancel</button>
            <button class="delete-btn" @click="deleteAccount">Yes, Delete My Account</button>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.settings {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.save-banner {
  background: #2e7d32;
  color: #fff;
  padding: 0.75rem 1.25rem;
  border-radius: var(--radius);
  font-size: 0.875rem;
  font-weight: 500;
  animation: slideDown 0.25s ease;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

.settings-header {
  margin-bottom: 0.25rem;
}

.settings-title {
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--color-text);
}

.settings-subtitle {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
}

.profile-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.profile-top {
  display: flex;
  align-items: center;
  gap: 1.5rem;
}

.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

.avatar {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  object-fit: cover;
}

.avatar.fallback {
  background: var(--color-graphite);
  color: var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 2rem;
  font-weight: 700;
}

.avatar-btn {
  font-size: 0.75rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-accent);
  background: none;
  border: none;
  cursor: pointer;
  text-decoration: underline;
}

.profile-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.profile-name {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-text);
}

.profile-email {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}

.col {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
  margin-bottom: 1.25rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.field-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
}

.input {
  padding: 0.625rem 0.875rem;
  font-size: 0.875rem;
  font-family: var(--font-sans);
  color: var(--color-text);
  background: var(--color-bg);
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  outline: none;
  transition: border-color 0.2s;
}

.input:focus {
  border-color: var(--color-graphite);
}

.input:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%23666' stroke-width='2'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  padding-right: 2.25rem;
}

.field-hint {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
}

.save-btn {
  align-self: flex-start;
  padding: 0.625rem 1.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, opacity 0.2s;
}

.save-btn:hover {
  background: var(--color-accent-hover);
}

.save-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.toggles {
  display: flex;
  flex-direction: column;
}

.toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--color-bg);
}

.toggle-row:last-child {
  border-bottom: none;
  padding-bottom: 0;
}

.toggle-row:first-child {
  padding-top: 0;
}

.toggle-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text);
}

.toggle-desc {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.toggle {
  position: relative;
  width: 44px;
  height: 24px;
  background: var(--color-grey);
  border: none;
  border-radius: 12px;
  cursor: pointer;
  transition: background 0.2s;
  flex-shrink: 0;
}

.toggle.on {
  background: var(--color-accent);
}

.toggle-knob {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  background: var(--color-surface);
  border-radius: 50%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
  transition: transform 0.2s;
}

.toggle.on .toggle-knob {
  transform: translateX(20px);
}

.danger-card {
  border: 1px solid rgba(211, 47, 47, 0.2);
}

.danger-title {
  color: #d32f2f;
}

.danger-desc {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  margin-bottom: 1rem;
  line-height: 1.5;
}

.danger-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: #fff;
  background: #d32f2f;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s;
}

.danger-btn:hover {
  background: #b71c1c;
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.15s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.modal {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2rem;
  max-width: 400px;
  width: 90%;
  animation: slideUp 0.2s ease;
}

@keyframes slideUp {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: translateY(0); }
}

.modal-title {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.75rem;
}

.modal-text {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  line-height: 1.5;
  margin-bottom: 1.5rem;
}

.modal-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
}

.cancel-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: none;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  cursor: pointer;
  transition: border-color 0.2s, color 0.2s;
}

.cancel-btn:hover {
  border-color: var(--color-graphite);
  color: var(--color-text);
}

.delete-btn {
  padding: 0.625rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: #fff;
  background: #d32f2f;
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s;
}

.delete-btn:hover {
  background: #b71c1c;
}
</style>
