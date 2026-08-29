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
    desc: 'Allocate your income into spending categories with set limits. Track every rupee and know exactly where your money goes.',
  },
  {
    icon: '🎯',
    title: 'Savings Goals',
    desc: 'Set financial targets with deadlines and watch your progress grow. Visual bars keep you motivated to reach each milestone.',
  },
  {
    icon: '📈',
    title: 'Smart Analytics',
    desc: 'Doughnut charts, bar graphs, and trend lines reveal your spending patterns. Switch between graph types and time ranges instantly.',
  },
  {
    icon: '📊',
    title: 'PDF & Excel Reports',
    desc: 'Export monthly breakdowns, budget vs actual comparisons, and key metrics as formatted PDFs or multi-sheet Excel workbooks.',
  },
  {
    icon: '🤖',
    title: 'AI Financial Plan',
    desc: 'Answer a few questions and our AI crafts a personalized savings and expenditure plan with budget splits and actionable tips.',
  },
  {
    icon: '🛡️',
    title: 'Budget Stress Test',
    desc: 'Simulate medical bills, income cuts, and emergencies. Find out if your budget survives — and get a plan to make it stronger.',
  },
]

const steps = [
  { num: '1', icon: '🔗', title: 'Sign Up Free', desc: 'Create your account with Google or email in seconds. No credit card needed.' },
  { num: '2', icon: '📋', title: 'Set Your Budget', desc: 'Create envelopes for Rent, Food, Fun, and more. Set limits that match your lifestyle.' },
  { num: '3', icon: '💸', title: 'Track Expenses', desc: 'Log income and expenses as they happen. Upload receipts and categorize automatically.' },
  { num: '4', icon: '📈', title: 'Grow & Optimize', desc: 'Let AI analyze your spending, generate reports, and help you save more every month.' },
]

const stats = [
  { value: '₹2L+', label: 'Budgets Tracked' },
  { value: '50K+', label: 'Expenses Logged' },
  { value: '33%', label: 'Avg Savings Rate' },
  { value: '99.9%', label: 'Uptime' },
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
          <img src="/wordmark.png" alt="Envelo" class="nav-wordmark" />
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
        <div class="hero-badge">✨ Now with AI-powered financial planning</div>
        <h1 class="hero-title">
          Take control of<br />
          <span class="hero-accent">your money.</span>
        </h1>
        <p class="hero-desc">
          Envelo is a personal finance app that helps you track every rupee, build budgets that actually work,
          reach your savings goals, and get AI-powered insights — so you never have to guess where your money went.
        </p>
        <div class="hero-actions">
          <router-link to="/auth" class="hero-btn primary">Start Free →</router-link>
          <button class="hero-btn secondary" @click="$el.closest('.home-page').querySelector('.features').scrollIntoView({ behavior: 'smooth' })">See Features</button>
        </div>
        <div class="hero-proof">
          <span class="proof-dot"></span>
          No credit card required · Free forever plan
        </div>
      </div>
      <div class="hero-visual">
        <div class="mock-card mc-1">
          <div class="mc-header">
            <span class="mc-icon">🏠</span>
            <span class="mc-title">Rent</span>
          </div>
          <div class="mc-bar"><div class="mc-fill" style="width: 60%; background: #202124;"></div></div>
          <span class="mc-amt">₹12,000 / ₹20,000</span>
        </div>
        <div class="mock-card mc-2">
          <div class="mc-header">
            <span class="mc-icon">🍔</span>
            <span class="mc-title">Food</span>
          </div>
          <div class="mc-bar"><div class="mc-fill" style="width: 55%; background: #D7F34A;"></div></div>
          <span class="mc-amt">₹2,750 / ₹5,000</span>
        </div>
        <div class="mock-card mc-3">
          <div class="mc-header">
            <span class="mc-icon">💰</span>
            <span class="mc-title">Savings</span>
          </div>
          <div class="mc-bar"><div class="mc-fill" style="width: 67%; background: #2e7d32;"></div></div>
          <span class="mc-amt">₹8,000 / ₹12,000</span>
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

    <!-- CTA -->
    <section class="cta-section">
      <div class="cta-inner">
        <h2 class="cta-title">Ready to take control of your finances?</h2>
        <p class="cta-desc">Join thousands of people who budget smarter and save more with Envelo.</p>
        <router-link to="/auth" class="cta-btn">Get Started Free →</router-link>
      </div>
    </section>

    <!-- Footer -->
    <footer class="footer">
      <div class="footer-inner">
        <div class="footer-brand">
          <div class="footer-logo-row">
            <img src="/wordmark.png" alt="Envelo" class="footer-wordmark" />
          </div>
          <p class="footer-tagline">Budget smarter. Save more.</p>
        </div>
        <div class="footer-links">
          <div class="footer-col">
            <h4 class="footer-col-title">Product</h4>
            <router-link to="/" class="footer-link">Overview</router-link>
            <router-link to="/auth" class="footer-link">Pricing</router-link>
            <router-link to="/help" class="footer-link">Help & Support</router-link>
          </div>
          <div class="footer-col">
            <h4 class="footer-col-title">Legal</h4>
            <router-link to="/privacypolicy" class="footer-link">Privacy Policy</router-link>
            <router-link to="/termsofservice" class="footer-link">Terms of Service</router-link>
          </div>
        </div>
      </div>
      <div class="footer-bottom">
        <p class="footer-copy">© {{ new Date().getFullYear() }} Envelo. All rights reserved.</p>
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

.nav-wordmark {
  height: 26px;
  width: auto;
  object-fit: contain;
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

/* Hero Visual */
.hero-visual {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  align-items: center;
}

.mock-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 1.25rem 1.5rem;
  width: 320px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.06);
  transition: transform 0.3s ease;
}

.mock-card:hover {
  transform: translateY(-4px);
}

.mc-2 { margin-left: 2rem; }
.mc-3 { margin-left: -1rem; }

.mc-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.mc-icon {
  font-size: 1.125rem;
}

.mc-title {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.mc-bar {
  height: 6px;
  background: var(--color-bg);
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 0.375rem;
}

.mc-fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.5s ease;
}

.mc-amt {
  font-size: 0.75rem;
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

.footer-wordmark {
  height: 22px;
  width: auto;
  object-fit: contain;
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
