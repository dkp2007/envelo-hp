<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const splashGif = '/envelo-intro.gif'
const hasSeenSplash = sessionStorage.getItem('envelo-splash-seen')
const showSplash = ref(!hasSeenSplash)

onMounted(() => {
  if (showSplash.value) {
    setTimeout(() => {
      showSplash.value = false
      sessionStorage.setItem('envelo-splash-seen', '1')
    }, 4500)
  }
})

const features = [
  {
    icon: '✉️',
    title: 'Envelope Budgeting',
    desc: 'Allocate income into spending categories with set limits. Track every rupee and know exactly where your money goes each month.',
  },
  {
    icon: '📸',
    title: 'OCR Bill Scanner',
    desc: 'Upload a receipt photo — Tesseract.js extracts text, AI parses the amount, date, merchant, and category. One click to save.',
  },
  {
    icon: '🤖',
    title: 'AI Financial Plan',
    desc: 'Answer 6 quick questions about your income and goals. Groq AI generates a personalized savings and expenditure plan in seconds.',
  },
  {
    icon: '💪',
    title: 'Budget Stress Test',
    desc: 'Simulate medical emergencies, income cuts, and big purchases. Find out if your budget survives — and get a plan to make it stronger.',
  },
  {
    icon: '📈',
    title: 'Smart Analytics',
    desc: 'Doughnut charts, bar graphs, radar views, and trend lines reveal your spending patterns. Switch between graph types and time ranges instantly.',
  },
  {
    icon: '📄',
    title: 'PDF & Excel Reports',
    desc: 'Export monthly breakdowns, budget vs actual comparisons, and key metrics as formatted PDFs with embedded charts or multi-sheet Excel workbooks.',
  },
]

const steps = [
  { num: '1', icon: '🔗', title: 'Sign Up Free', desc: 'Create your account with Google or email in seconds. No credit card needed.' },
  { num: '2', icon: '📋', title: 'Set Your Budget', desc: 'Create envelopes for Rent, Food, Fun, and more. Set limits that match your lifestyle.' },
  { num: '3', icon: '💸', title: 'Track Expenses', desc: 'Log income and expenses as they happen. Upload receipts and let AI categorize them.' },
  { num: '4', icon: '📈', title: 'Grow & Optimize', desc: 'Let AI analyze your spending, stress-test your budget, and help you save more every month.' },
]

const stats = [
  { value: '6', label: 'AI Features Built' },
  { value: '5', label: 'Interactive Chart Types' },
  { value: '45+', label: 'Transactions Tracked' },
  { value: '100%', label: 'Free & Open Source' },
]

const mockBars = [
  { h: 55, label: 'Jan', color: 'var(--color-graphite)' },
  { h: 70, label: 'Feb', color: 'var(--color-accent)' },
  { h: 45, label: 'Mar', color: 'var(--color-graphite)' },
  { h: 80, label: 'Apr', color: 'var(--color-accent)' },
  { h: 60, label: 'May', color: 'var(--color-graphite)' },
  { h: 35, label: 'Jun', color: 'var(--color-accent)' },
  { h: 90, label: 'Jul', color: 'var(--color-graphite)' },
  { h: 50, label: 'Aug', color: 'var(--color-accent)' },
]

const testimonials = [
  {
    quote: 'I finally know where my money goes every month. The envelope system changed how I think about spending.',
    name: 'Budget Enthusiast',
    role: 'Beta Tester',
  },
  {
    quote: 'The OCR bill scanner is incredible — I just snap a photo and everything is logged automatically.',
    name: 'Tech Early Adopter',
    role: 'Beta Tester',
  },
  {
    quote: 'The stress test showed me I was one emergency away from trouble. Now I have a proper safety net.',
    name: 'Financial Planner',
    role: 'Beta Tester',
  },
]
</script>

<template>
  <div class="home-page">
    <!-- Splash Screen -->
    <Transition name="splash-fade">
      <div v-if="showSplash" class="splash">
        <img :src="splashGif" alt="Envelo" class="splash-gif" />
      </div>
    </Transition>

    <!-- Nav -->
    <nav class="nav">
      <div class="nav-inner">
        <div class="nav-brand" @click="router.push('/')">
          <img src="/icon.png" alt="Envelo" class="nav-logo" />
          <span class="nav-name">Envelo</span>
        </div>
        <div class="nav-right">
          <template v-if="auth.isLoggedIn">
            <router-link to="/dashboard" class="nav-link">Dashboard</router-link>
            <div class="nav-user">
              <div class="nav-avatar">
                {{ auth.user?.user_metadata?.full_name?.charAt(0) || 'U' }}
              </div>
              <span class="nav-user-name">{{ auth.user?.user_metadata?.full_name || 'Account' }}</span>
            </div>
          </template>
          <template v-else>
            <router-link to="/auth" class="nav-link">Log In</router-link>
            <router-link to="/auth" class="nav-cta">Get Started Free</router-link>
          </template>
        </div>
      </div>
    </nav>

    <!-- Hero -->
    <section class="hero">
      <div class="hero-inner">
        <div class="hero-badge">✨ AI-powered budgeting for modern India</div>
        <h1 class="hero-title">
          Stop guessing.<br />
          <span class="hero-accent">Start planning.</span>
        </h1>
        <p class="hero-desc">
          Envelo is an open-source personal finance app that helps you track every rupee, build budgets that actually work,
          scan bills with AI, stress-test your finances, and get personalized savings plans — all for free.
        </p>
        <div class="hero-actions">
          <router-link to="/auth" class="hero-btn primary">Start Free →</router-link>
          <button class="hero-btn secondary" @click="document.querySelector('.features')?.scrollIntoView({ behavior: 'smooth' })">See Features</button>
        </div>
        <div class="hero-proof">
          <span class="proof-dot"></span>
          No credit card required · 100% free · Open source
        </div>
      </div>
      <div class="hero-visual">
        <!-- Dashboard Mock -->
        <div class="mock-dashboard">
          <div class="mock-topbar">
            <span class="mock-title">Overview</span>
            <span class="mock-avatar">D</span>
          </div>
          <div class="mock-stats">
            <div class="mock-stat">
              <span class="mock-stat-label">Total Income</span>
              <span class="mock-stat-value income">₹58,000</span>
            </div>
            <div class="mock-stat">
              <span class="mock-stat-label">Total Spent</span>
              <span class="mock-stat-value expense">₹32,450</span>
            </div>
            <div class="mock-stat">
              <span class="mock-stat-label">Savings Rate</span>
              <span class="mock-stat-value savings">44%</span>
            </div>
          </div>
          <div class="mock-chart-area">
            <div v-for="(bar, i) in mockBars" :key="i" class="mock-bar-col">
              <div class="mock-bar" :style="{ height: bar.h + '%', animationDelay: i * 0.08 + 's', background: bar.color }"></div>
              <span class="mock-bar-label">{{ bar.label }}</span>
            </div>
          </div>
          <div class="mock-label">Monthly Spending · Real-time</div>
        </div>
        <!-- Floating Cards -->
        <div class="float-card fc-1">
          <span class="fc-icon">📸</span>
          <div>
            <span class="fc-title">Bill Scanned</span>
            <span class="fc-sub">₹1,247 · Big Bazaar</span>
          </div>
        </div>
        <div class="float-card fc-2">
          <span class="fc-icon">🤖</span>
          <div>
            <span class="fc-title">AI Plan Ready</span>
            <span class="fc-sub">Save ₹8,000/mo</span>
          </div>
        </div>
      </div>
    </section>

    <!-- Stats -->
    <section class="stats-section">
      <div class="stats-row">
        <div v-for="s in stats" :key="s.label" class="stat-item">
          <span class="stat-value">{{ s.value }}</span>
          <span class="stat-label">{{ s.label }}</span>
        </div>
      </div>
    </section>

    <!-- Features -->
    <section class="features" id="features">
      <div class="section-inner">
        <div class="section-header">
          <h2 class="section-title">Everything you need to master your money</h2>
          <p class="section-desc">From daily expenses to long-term goals — Envelo has you covered.</p>
        </div>
        <div class="feature-grid">
          <div v-for="f in features" :key="f.title" class="feature-card">
            <span class="feature-icon">{{ f.icon }}</span>
            <h3 class="feature-title">{{ f.title }}</h3>
            <p class="feature-desc">{{ f.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- How It Works -->
    <section class="how-section">
      <div class="section-inner">
        <div class="section-header">
          <h2 class="section-title">Get started in minutes</h2>
          <p class="section-desc">Four simple steps to take control of your finances.</p>
        </div>
        <div class="steps-grid">
          <div v-for="s in steps" :key="s.num" class="step-card">
            <div class="step-num">{{ s.num }}</div>
            <span class="step-icon">{{ s.icon }}</span>
            <h3 class="step-title">{{ s.title }}</h3>
            <p class="step-desc">{{ s.desc }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Testimonials -->
    <section class="testimonials-section">
      <div class="section-inner">
        <div class="section-header">
          <h2 class="section-title">What people are saying</h2>
          <p class="section-desc">Real feedback from early users.</p>
        </div>
        <div class="testimonial-grid">
          <div v-for="(t, i) in testimonials" :key="i" class="testimonial-card">
            <p class="testimonial-quote">"{{ t.quote }}"</p>
            <div class="testimonial-author">
              <div class="testimonial-avatar">{{ t.name.charAt(0) }}</div>
              <div>
                <span class="testimonial-name">{{ t.name }}</span>
                <span class="testimonial-role">{{ t.role }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="cta-section">
      <div class="cta-inner">
        <h2 class="cta-title">Ready to take control of your finances?</h2>
        <p class="cta-desc">Join early users who budget smarter and save more with Envelo.</p>
        <router-link to="/auth" class="cta-btn">Get Started Free →</router-link>
      </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
      <div class="footer-inner">
        <div class="footer-brand">
          <div class="footer-logo-row">
            <img src="/icon.png" alt="Envelo" class="footer-logo" />
            <span class="footer-name">Envelo</span>
          </div>
          <p class="footer-tagline">Budget smarter. Save more. Free forever.</p>
        </div>
        <div class="footer-links">
          <div class="footer-col">
            <h4 class="footer-col-title">Product</h4>
            <a href="/#features" class="footer-link">Features</a>
            <router-link to="/help" class="footer-link">Help & Support</router-link>
            <a href="https://github.com/dkp2007/envelo" target="_blank" class="footer-link">GitHub</a>
          </div>
          <div class="footer-col">
            <h4 class="footer-col-title">Legal</h4>
            <router-link to="/privacypolicy" class="footer-link">Privacy Policy</router-link>
            <router-link to="/termsofservice" class="footer-link">Terms of Service</router-link>
          </div>
        </div>
      </div>
      <div class="footer-bottom">
        <p class="footer-copy">© {{ new Date().getFullYear() }} Envelo. Open source under MIT License.</p>
      </div>
    </footer>
  </div>
</template>

<style scoped>
.home-page {
  min-height: 100vh;
  background: var(--color-bg);
  overflow-x: hidden;
}

/* ─── Splash Screen ─── */
.splash {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: #fcfcff;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.splash-gif {
  width: 420px;
  max-height: 80vh;
  object-fit: contain;
  display: block;
  margin: 0 auto;
  animation: splashPulse 0.6s ease-out;
}

@keyframes splashPulse {
  0% { opacity: 0; transform: scale(0.85); }
  100% { opacity: 1; transform: scale(1); }
}

.splash-fade-leave-active {
  transition: opacity 0.6s ease, transform 0.6s ease;
}

.splash-fade-leave-to {
  opacity: 0;
  transform: scale(1.08);
}

/* ─── Nav ─── */
.nav {
  position: sticky;
  top: 0;
  z-index: 100;
  background: rgba(245, 245, 240, 0.85);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--color-border);
}

.nav-inner {
  max-width: 1120px;
  margin: 0 auto;
  padding: 0 2rem;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.nav-brand {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.nav-logo {
  width: 32px;
  height: 32px;
  object-fit: contain;
}

.nav-name {
  font-size: 1.125rem;
  font-weight: 700;
  color: var(--color-text);
}

.nav-right {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.nav-link {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text-muted);
  text-decoration: none;
  transition: color 0.2s;
}

.nav-link:hover {
  color: var(--color-text);
}

.nav-cta {
  padding: 0.5rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  text-decoration: none;
  cursor: pointer;
  transition: background 0.2s;
}

.nav-cta:hover {
  background: var(--color-accent-hover);
}

.nav-user {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.375rem 0.75rem;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  cursor: pointer;
  text-decoration: none;
  transition: background 0.15s;
}

.nav-user:hover {
  background: var(--color-bg);
}

.nav-avatar {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--color-graphite);
  color: var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
  flex-shrink: 0;
}

.nav-user-name {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
}

/* ─── Hero ─── */
.hero {
  max-width: 1120px;
  margin: 0 auto;
  padding: 5rem 2rem 3rem;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
  align-items: center;
}

.hero-badge {
  display: inline-block;
  padding: 0.375rem 1rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-graphite);
  background: rgba(215, 243, 74, 0.3);
  border-radius: 999px;
  margin-bottom: 1.5rem;
}

.hero-title {
  font-size: 3.25rem;
  font-weight: 800;
  line-height: 1.1;
  color: var(--color-text);
  margin-bottom: 1.25rem;
}

.hero-accent {
  color: var(--color-accent-hover);
}

.hero-desc {
  font-size: 1.0625rem;
  line-height: 1.7;
  color: var(--color-text-muted);
  margin-bottom: 2rem;
  max-width: 480px;
}

.hero-actions {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.hero-btn {
  padding: 0.875rem 2rem;
  font-size: 0.9375rem;
  font-weight: 600;
  font-family: var(--font-sans);
  border-radius: var(--radius);
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s;
}

.hero-btn.primary {
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
}

.hero-btn.primary:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
}

.hero-btn.secondary {
  color: var(--color-text-muted);
  background: none;
  border: 1.5px solid var(--color-border);
}

.hero-btn.secondary:hover {
  border-color: var(--color-graphite);
  color: var(--color-text);
}

.hero-proof {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.proof-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #2e7d32;
  flex-shrink: 0;
}

/* ─── Hero Visual — Dashboard Mock ─── */
.hero-visual {
  position: relative;
  display: flex;
  justify-content: center;
  padding: 2rem 0;
}

.mock-dashboard {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 0;
  width: 100%;
  max-width: 420px;
  box-shadow: 0 12px 48px rgba(0, 0, 0, 0.1), 0 2px 8px rgba(0, 0, 0, 0.04);
  overflow: hidden;
  border: 1px solid var(--color-border);
  position: relative;
  z-index: 2;
}

.mock-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1.25rem;
  background: var(--color-graphite);
}

.mock-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: #fff;
}

.mock-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: var(--color-accent);
  color: var(--color-graphite);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.625rem;
  font-weight: 700;
}

.mock-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0;
  border-bottom: 1px solid var(--color-border);
}

.mock-stat {
  padding: 0.875rem 0.75rem;
  text-align: center;
  border-right: 1px solid var(--color-border);
}

.mock-stat:last-child {
  border-right: none;
}

.mock-stat-label {
  display: block;
  font-size: 0.5625rem;
  color: var(--color-text-muted);
  margin-bottom: 0.25rem;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.mock-stat-value {
  display: block;
  font-size: 1.125rem;
  font-weight: 800;
}

.mock-stat-value.income { color: var(--color-accent-hover); }
.mock-stat-value.expense { color: #dc2626; }
.mock-stat-value.savings { color: #2e7d32; }

.mock-chart-area {
  display: flex;
  align-items: flex-end;
  gap: 6px;
  padding: 1rem 1.25rem 0.25rem;
  height: 140px;
}

.mock-bar-col {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  height: 100%;
  justify-content: flex-end;
}

.mock-bar {
  width: 100%;
  border-radius: 4px 4px 0 0;
  animation: barGrow 0.6s ease-out forwards;
  transform-origin: bottom;
  min-height: 6px;
}

.mock-bar-label {
  font-size: 0.5rem;
  color: var(--color-text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

@keyframes barGrow {
  0% { transform: scaleY(0); }
  100% { transform: scaleY(1); }
}

.mock-label {
  padding: 0.5rem 1.25rem 1rem;
  font-size: 0.625rem;
  color: var(--color-text-muted);
  text-align: center;
}

/* Floating cards */
.float-card {
  position: absolute;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: var(--color-surface);
  border-radius: var(--radius);
  padding: 0.625rem 0.875rem;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
  animation: float 4s ease-in-out infinite;
  border: 1px solid var(--color-border);
  z-index: 3;
}

.fc-1 {
  top: 4%;
  left: -6%;
  animation-delay: 0s;
}

.fc-2 {
  bottom: 8%;
  right: -4%;
  animation-delay: 2s;
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-6px); }
}

.fc-icon {
  font-size: 1.125rem;
}

.fc-title {
  display: block;
  font-size: 0.6875rem;
  font-weight: 600;
  color: var(--color-text);
}

.fc-sub {
  display: block;
  font-size: 0.5625rem;
  color: var(--color-text-muted);
}

/* ─── Stats ─── */
.stats-section {
  background: var(--color-graphite);
  padding: 2.5rem 2rem;
}

.stats-row {
  max-width: 1120px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 2rem;
  text-align: center;
}

.stat-value {
  display: block;
  font-size: 1.75rem;
  font-weight: 800;
  color: var(--color-accent);
}

.stat-label {
  font-size: 0.8125rem;
  color: rgba(255, 255, 255, 0.5);
  margin-top: 0.25rem;
  display: block;
}

/* ─── Sections ─── */
.section-inner {
  max-width: 1120px;
  margin: 0 auto;
  padding: 5rem 2rem;
}

.section-header {
  text-align: center;
  margin-bottom: 3rem;
}

.section-title {
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.5rem;
}

.section-desc {
  font-size: 1rem;
  color: var(--color-text-muted);
}

/* ─── Features ─── */
.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
}

.feature-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.75rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
  transition: transform 0.2s, box-shadow 0.2s;
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.feature-icon {
  font-size: 1.75rem;
  display: block;
  margin-bottom: 0.875rem;
}

.feature-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.5rem;
}

.feature-desc {
  font-size: 0.8125rem;
  line-height: 1.6;
  color: var(--color-text-muted);
}

/* ─── How It Works ─── */
.how-section {
  background: var(--color-surface);
}

.steps-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1.5rem;
}

.step-card {
  text-align: center;
  padding: 1.5rem 1rem;
}

.step-num {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: var(--color-accent);
  color: var(--color-graphite);
  font-size: 0.875rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 0.75rem;
}

.step-icon {
  font-size: 1.75rem;
  display: block;
  margin-bottom: 0.75rem;
}

.step-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.375rem;
}

.step-desc {
  font-size: 0.8125rem;
  line-height: 1.6;
  color: var(--color-text-muted);
}

/* ─── Testimonials ─── */
.testimonials-section {
  background: var(--color-surface);
  border-top: 1px solid var(--color-border);
}

.testimonial-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1.5rem;
}

.testimonial-card {
  background: var(--color-bg);
  border-radius: var(--radius-lg);
  padding: 1.75rem;
  border: 1px solid var(--color-border);
}

.testimonial-quote {
  font-size: 0.9375rem;
  line-height: 1.6;
  color: var(--color-text);
  margin-bottom: 1.25rem;
  font-style: italic;
}

.testimonial-author {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.testimonial-avatar {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: var(--color-accent);
  color: var(--color-graphite);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.875rem;
  font-weight: 700;
  flex-shrink: 0;
}

.testimonial-name {
  display: block;
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
}

.testimonial-role {
  display: block;
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

/* ─── CTA ─── */
.cta-section {
  background: var(--color-graphite);
}

.cta-inner {
  max-width: 1120px;
  margin: 0 auto;
  padding: 5rem 2rem;
  text-align: center;
}

.cta-title {
  font-size: 2rem;
  font-weight: 700;
  color: #fff;
  margin-bottom: 0.75rem;
}

.cta-desc {
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.6);
  margin-bottom: 2rem;
}

.cta-btn {
  display: inline-block;
  padding: 0.875rem 2.5rem;
  font-size: 1rem;
  font-weight: 700;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border-radius: var(--radius);
  text-decoration: none;
  transition: background 0.2s, transform 0.15s;
}

.cta-btn:hover {
  background: var(--color-accent-hover);
  transform: translateY(-2px);
}

/* ─── Footer ─── */
.footer {
  border-top: 1px solid var(--color-border);
}

.footer-inner {
  max-width: 1120px;
  margin: 0 auto;
  padding: 3rem 2rem 2rem;
  display: flex;
  justify-content: space-between;
}

.footer-brand {
  max-width: 260px;
}

.footer-logo-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.footer-logo {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.footer-name {
  font-size: 1rem;
  font-weight: 700;
  color: var(--color-text);
}

.footer-tagline {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.footer-links {
  display: flex;
  gap: 4rem;
}

.footer-col {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.footer-col-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.25rem;
}

.footer-link {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  text-decoration: none;
  transition: color 0.2s;
}

.footer-link:hover {
  color: var(--color-text);
}

.footer-bottom {
  max-width: 1120px;
  margin: 0 auto;
  padding: 0 2rem 2rem;
}

.footer-copy {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}
</style>
