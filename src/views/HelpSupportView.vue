<script setup>
import { ref } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth = useAuthStore()

const name = ref('')
const email = ref('')
const subject = ref('')
const message = ref('')
const submitting = ref(false)
const submitted = ref(false)
const submitError = ref('')

const openFaq = ref(null)

const faqs = [
  {
    q: 'What is envelope budgeting?',
    a: 'Envelope budgeting lets you allocate your income into spending categories like Rent, Food, Fun, and Savings. Each envelope has a set budget limit, and as you log expenses, Envelo tracks how much is left in each category in real-time.',
  },
  {
    q: 'How do I add an expense?',
    a: 'Click "Add Expense" in the sidebar. Fill in the name, amount, category, and date — you can also upload a bill or receipt. Switch between Expense and Income using the toggle at the top.',
  },
  {
    q: 'Can I upload bills or receipts?',
    a: 'Yes. On the Add Expense page there\'s a drag-and-drop upload zone on the right. You can upload JPG, PNG, or PDF files up to 10 MB. A preview of your file will appear once uploaded.',
  },
  {
    q: 'How do savings goals work?',
    a: 'Go to Savings Goals and create a goal with a target amount and deadline. Envelo shows a progress bar for each goal so you can see exactly how much you\'ve saved and how much is left.',
  },
  {
    q: 'What is the AI Financial Plan?',
    a: 'On the Overview page, click "Get My Plan" to open a form where you share your income, expenses, goals, and risk tolerance. Our AI then generates a personalized savings and expenditure plan with specific budget splits and tips.',
  },
  {
    q: 'Can I export my reports?',
    a: 'Go to Reports and use the "Export PDF" or "Export Excel" buttons. PDF gives you a formatted document with tables, while Excel provides a multi-sheet workbook with monthly breakdowns, budget vs actual, top expenses, and key metrics.',
  },
  {
    q: 'How does the budget vs actual comparison work?',
    a: 'In Reports, the Budget vs Actual card compares what you\'ve spent in each envelope against its budget. Color-coded badges tell you at a glance if you\'re under budget (green), on track (yellow), or overspending (orange).',
  },
  {
    q: 'What analytics are available?',
    a: 'The Analytics page includes a doughnut chart for spending by category, a bar chart comparing income vs expenses month by month, and a ranked list of your top spending categories with percentage bars.',
  },
  {
    q: 'Is my financial data secure?',
    a: 'Yes. We use Supabase with Row Level Security (RLS) so only you can access your data. Authentication is handled via Google OAuth or email/password. Bank-level encryption protects all data in transit and at rest.',
  },
  {
    q: 'How do I change my settings?',
    a: 'Click your profile in the top-right corner and select "Profile Settings". From there you can update your name, phone, country, currency, timezone, language, and toggle notification preferences like budget alerts and weekly reports.',
  },
  {
    q: 'What currencies are supported?',
    a: 'Envelo supports INR (₹), USD ($), EUR (€), GBP (£), JPY (¥), AUD, CAD, and SGD. You can change your preferred currency in Settings → Preferences.',
  },
  {
    q: 'Can I connect my bank account?',
    a: 'Bank account linking is on our roadmap. For now, you can manually log all income and expenses through the Add Expense form. Bill upload helps you keep digital copies of receipts for reference.',
  },
]

function toggleFaq(i) {
  openFaq.value = openFaq.value === i ? null : i
}

async function submitForm() {
  if (!name.value || !email.value || !subject.value || !message.value) return

  submitting.value = true
  submitError.value = ''

  const { error } = await supabase.from('contact_messages').insert({
    user_id: auth.user?.id || null,
    name: name.value,
    email: email.value,
    subject: subject.value,
    message: message.value,
  })

  submitting.value = false

  if (error) {
    submitError.value = 'Something went wrong. Please try again.'
    return
  }

  submitted.value = true
  name.value = ''
  email.value = ''
  subject.value = ''
  message.value = ''
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <div class="content-grid">
        <div class="left-col">
          <div class="card">
            <div class="card-header">
              <h2 class="card-title">Frequently Asked Questions</h2>
            </div>
            <div class="faq-list">
              <div v-for="(faq, i) in faqs" :key="i" class="faq-item">
                <button class="faq-question" @click="toggleFaq(i)">
                  <span>{{ faq.q }}</span>
                  <svg class="faq-chevron" :class="{ open: openFaq === i }" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
                </button>
                <div v-if="openFaq === i" class="faq-answer">
                  <p>{{ faq.a }}</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="right-col">
          <div class="card">
            <div class="card-header">
              <h2 class="card-title">Contact Us</h2>
            </div>

            <div v-if="submitted" class="success-state">
              <div class="success-icon">✅</div>
              <h3 class="success-title">Message Sent!</h3>
              <p class="success-text">We'll get back to you within 24 hours.</p>
              <button class="link-btn" @click="submitted = false">Send another message</button>
            </div>

            <form v-else class="form" @submit.prevent="submitForm">
              <p v-if="submitError" class="error-text">{{ submitError }}</p>

              <div class="field">
                <label class="label">Name</label>
                <input v-model="name" type="text" placeholder="Your name" class="input" required />
              </div>

              <div class="field">
                <label class="label">Email</label>
                <input v-model="email" type="email" placeholder="you@example.com" class="input" required />
              </div>

              <div class="field">
                <label class="label">Subject</label>
                <select v-model="subject" class="input" required>
                  <option value="" disabled>Select a topic</option>
                  <option value="account">Account Issues</option>
                  <option value="billing">Billing & Plans</option>
                  <option value="feature">Feature Request</option>
                  <option value="bug">Bug Report</option>
                  <option value="other">Other</option>
                </select>
              </div>

              <div class="field">
                <label class="label">Message</label>
                <textarea v-model="message" placeholder="Describe your issue or question..." class="input textarea" rows="5" required></textarea>
              </div>

              <button type="submit" class="submit-btn" :disabled="submitting">
                {{ submitting ? 'Sending...' : 'Send Message' }}
              </button>
            </form>
          </div>

          <div class="card quick-links">
            <div class="card-header">
              <h2 class="card-title">Quick Links</h2>
            </div>
            <div class="links-list">
              <a class="link-row">
                <span class="link-icon">📖</span>
                <span class="link-label">Documentation</span>
                <svg class="link-arrow" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
              </a>
              <a class="link-row">
                <span class="link-icon">🎬</span>
                <span class="link-label">Video Tutorials</span>
                <svg class="link-arrow" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
              </a>
              <a class="link-row">
                <span class="link-icon">🐦</span>
                <span class="link-label">Twitter / X</span>
                <svg class="link-arrow" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
              </a>
              <a class="link-row">
                <span class="link-icon">💬</span>
                <span class="link-label">Community Forum</span>
                <svg class="link-arrow" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.content-grid {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 1.5rem;
}

.card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.5rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1.25rem;
}

.card-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

/* ─── FAQ List ─── */
.faq-list {
  display: flex;
  flex-direction: column;
}

.faq-item {
  border-bottom: 1px solid var(--color-bg);
}

.faq-item:last-child {
  border-bottom: none;
}

.faq-question {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 1rem 0;
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text);
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  gap: 1rem;
}

.faq-chevron {
  flex-shrink: 0;
  color: var(--color-text-muted);
  transition: transform 0.2s ease;
}

.faq-chevron.open {
  transform: rotate(180deg);
}

.faq-answer {
  padding: 0 0 1rem;
  animation: slideDown 0.2s ease-out;
}

@keyframes slideDown {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.faq-answer p {
  font-size: 0.8125rem;
  line-height: 1.6;
  color: var(--color-text-muted);
}

/* ─── Form ─── */
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
  box-shadow: 0 0 0 3px rgba(32, 33, 36, 0.06);
}

.input::placeholder {
  color: var(--color-grey);
}

.textarea {
  resize: vertical;
}

select.input {
  cursor: pointer;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%23A7A7A0' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  padding-right: 2rem;
}

.submit-btn {
  padding: 0.75rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s, opacity 0.2s;
}

.submit-btn:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.error-text {
  font-size: 0.8125rem;
  color: #d32f2f;
  padding: 0.5rem 0.75rem;
  background: rgba(211, 47, 47, 0.06);
  border-radius: var(--radius);
}

/* ─── Success ─── */
.success-state {
  text-align: center;
  padding: 2rem 0;
}

.success-icon {
  font-size: 2.5rem;
  margin-bottom: 0.75rem;
}

.success-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.375rem;
}

.success-text {
  font-size: 0.875rem;
  color: var(--color-text-muted);
  margin-bottom: 1.25rem;
}

.link-btn {
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-accent);
  background: none;
  border: none;
  cursor: pointer;
  text-decoration: underline;
}

/* ─── Links ─── */
.links-list {
  display: flex;
  flex-direction: column;
}

.link-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--color-bg);
  cursor: pointer;
  text-decoration: none;
  transition: background 0.12s;
}

.link-row:last-child {
  border-bottom: none;
}

.link-row:hover {
  background: var(--color-bg);
  margin: 0 -1.5rem;
  padding-left: 1.5rem;
  padding-right: 1.5rem;
}

.link-icon {
  font-size: 1.125rem;
}

.link-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text);
  flex: 1;
}

.link-arrow {
  color: var(--color-text-muted);
}
</style>
