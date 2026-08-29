<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useHcaptcha } from '@/composables/useHcaptcha'
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha'

const auth = useAuthStore()
const router = useRouter()
const { siteKey, consumeToken, hasValidToken, onVerify, onExpire, onError, error: captchaError, isLocalhost } = useHcaptcha()

const activeTab = ref('signin')
const email = ref('')
const password = ref('')
const showPassword = ref(false)
const loading = ref(false)
const error = ref('')
const successMessage = ref('')

// Refs to hCaptcha component instances
const signInCaptcha = ref(null)
const signUpCaptcha = ref(null)

function resetCaptcha() {
  if (isLocalhost) return
  const ref = activeTab.value === 'signin' ? signInCaptcha.value : signUpCaptcha.value
  if (ref) {
    ref.reset()
  }
}

async function handleGoogleLogin() {
  error.value = ''
  try {
    const token = isLocalhost ? '' : consumeToken()
    await auth.loginWithGoogle(token)
  } catch (err) {
    error.value = err.message
    resetCaptcha()
  }
}

async function handleEmailSignIn() {
  error.value = ''
  loading.value = true
  try {
    const token = isLocalhost ? '' : consumeToken()
    await auth.signInWithEmail(email.value, password.value, token)
    router.push({ name: 'dashboard' })
  } catch (err) {
    error.value = err.message
    resetCaptcha()
  } finally {
    loading.value = false
  }
}

async function handleEmailSignUp() {
  error.value = ''
  successMessage.value = ''
  loading.value = true
  try {
    const token = isLocalhost ? '' : consumeToken()
    await auth.signUpWithEmail(email.value, password.value, token)
    successMessage.value = 'Check your email for a verification link.'
    email.value = ''
    password.value = ''
  } catch (err) {
    error.value = err.message
    resetCaptcha()
  } finally {
    loading.value = false
  }
}

function switchTab(tab) {
  activeTab.value = tab
  error.value = ''
  successMessage.value = ''
}

// Deterministic firefly positions using a seeded approach
const fireflyPositions = [
  { x: 8, y: 12 }, { x: 85, y: 8 }, { x: 12, y: 75 }, { x: 90, y: 70 },
  { x: 5, y: 45 }, { x: 92, y: 40 }, { x: 20, y: 5 }, { x: 78, y: 88 },
  { x: 15, y: 90 }, { x: 88, y: 15 }, { x: 3, y: 60 }, { x: 95, y: 55 },
  { x: 25, y: 82 }, { x: 75, y: 5 }, { x: 10, y: 30 }, { x: 82, y: 92 },
  { x: 30, y: 15 }, { x: 70, y: 78 },
]

function fireflyStyle(n) {
  const pos = fireflyPositions[(n - 1) % fireflyPositions.length]
  const size = 1.5 + (n % 3) * 0.8
  const delay = (n * 1.3) % 8
  const duration = 6 + (n % 5) * 2
  const angle = ((n * 137.508) % 360) * (Math.PI / 180)
  const distance = 20 + (n % 5) * 10
  const driftX = Math.round(Math.cos(angle) * distance)
  const driftY = Math.round(Math.sin(angle) * distance)
  return {
    left: pos.x + '%',
    top: pos.y + '%',
    width: size + 'px',
    height: size + 'px',
    animationDelay: delay + 's',
    animationDuration: duration + 's',
    '--drift-x': driftX + 'px',
    '--drift-y': driftY + 'px',
    '--glow-color': 'rgba(215, 243, 74, 0.9)',
    '--glow-spread': 'rgba(215, 243, 74, 0.35)',
  }
}
</script>

<template>
  <div class="auth-page">
    <div class="bg-shapes">
      <span class="shape shape-1"></span>
      <span class="shape shape-2"></span>
      <span class="shape shape-3"></span>
      <span class="shape shape-4"></span>
      <span class="shape shape-5"></span>
    </div>
    <!-- Fireflies -->
    <div class="fireflies" aria-hidden="true">
      <span v-for="n in 18" :key="n" class="firefly" :style="fireflyStyle(n)"></span>
    </div>
    <div class="auth-card">
      <div class="card-accent"></div>
      <div class="auth-brand">
        <img src="/icon.png" alt="" class="auth-icon" />
        <img src="/wordmark.png" alt="Envelo" class="auth-wordmark" />
      </div>

      <div class="auth-form-wrap">
        <button class="google-btn" @click="handleGoogleLogin">
          <svg class="google-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
            <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
            <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
            <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
            <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
          </svg>
          Sign in with Google
        </button>

        <div class="divider">
          <span>or</span>
        </div>

        <div class="tabs">
          <button
            class="tab"
            :class="{ active: activeTab === 'signin' }"
            @click="switchTab('signin')"
          >
            Sign In
          </button>
          <button
            class="tab"
            :class="{ active: activeTab === 'signup' }"
            @click="switchTab('signup')"
          >
            Sign Up
          </button>
        </div>

        <!-- Sign In Form -->
        <form v-if="activeTab === 'signin'" class="auth-form" @submit.prevent="handleEmailSignIn">
          <input
            v-model="email"
            type="email"
            placeholder="Email"
            required
            class="input"
          />
          <div class="password-wrap">
            <input
              v-model="password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="Password"
              required
              minlength="6"
              class="input"
            />
            <button type="button" class="toggle-pw" @click="showPassword = !showPassword">
              <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
            </button>
          </div>
          <div v-if="!isLocalhost" class="hcaptcha-wrap">
            <VueHcaptcha
              ref="signInCaptcha"
              :sitekey="siteKey"
              @verify="onVerify"
              @expired="onExpire"
              @error="onError"
            />
          </div>
          <p v-if="captchaError" class="error">{{ captchaError }}</p>
          <p v-if="error" class="error">{{ error }}</p>
          <button type="submit" class="submit-btn" :disabled="loading">
            {{ loading ? 'Signing in...' : 'Sign In' }}
          </button>
        </form>

        <!-- Sign Up Form -->
        <form v-else class="auth-form" @submit.prevent="handleEmailSignUp">
          <input
            v-model="email"
            type="email"
            placeholder="Email"
            required
            class="input"
          />
          <div class="password-wrap">
            <input
              v-model="password"
              :type="showPassword ? 'text' : 'password'"
              placeholder="Password (min 6 characters)"
              required
              minlength="6"
              class="input"
            />
            <button type="button" class="toggle-pw" @click="showPassword = !showPassword">
              <svg v-if="!showPassword" xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
              <svg v-else xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/><line x1="1" y1="1" x2="23" y2="23"/></svg>
            </button>
          </div>
          <div v-if="!isLocalhost" class="hcaptcha-wrap">
            <VueHcaptcha
              ref="signUpCaptcha"
              :sitekey="siteKey"
              @verify="onVerify"
              @expired="onExpire"
              @error="onError"
            />
          </div>
          <p v-if="captchaError" class="error">{{ captchaError }}</p>
          <p v-if="error" class="error">{{ error }}</p>
          <p v-if="successMessage" class="success">{{ successMessage }}</p>
          <button type="submit" class="submit-btn" :disabled="loading">
            {{ loading ? 'Creating account...' : 'Create Account' }}
          </button>
        </form>
      </div>
    </div>
  </div>
</template>

<style scoped>
.auth-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg);
  padding: 2rem;
  position: relative;
  overflow: hidden;
}

.bg-shapes .shape {
  position: absolute;
  border-radius: 50%;
  opacity: 0.35;
}

.shape-1 {
  width: 320px;
  height: 320px;
  background: radial-gradient(circle, rgba(215, 243, 74, 0.25) 0%, transparent 70%);
  top: -80px;
  right: -60px;
  animation: float 8s ease-in-out infinite;
}

.shape-2 {
  width: 200px;
  height: 200px;
  background: radial-gradient(circle, rgba(215, 243, 74, 0.2) 0%, transparent 70%);
  bottom: 10%;
  left: -40px;
  animation: float 10s ease-in-out infinite reverse;
}

.shape-3 {
  width: 120px;
  height: 120px;
  background: radial-gradient(circle, rgba(167, 167, 160, 0.15) 0%, transparent 70%);
  top: 30%;
  left: 15%;
  animation: float 12s ease-in-out infinite;
}

.shape-4 {
  width: 80px;
  height: 80px;
  background: radial-gradient(circle, rgba(215, 243, 74, 0.2) 0%, transparent 70%);
  bottom: 20%;
  right: 10%;
  animation: float 9s ease-in-out infinite reverse;
}

.shape-5 {
  width: 180px;
  height: 180px;
  background: radial-gradient(circle, rgba(32, 33, 36, 0.04) 0%, transparent 70%);
  top: 50%;
  right: 25%;
  animation: float 11s ease-in-out infinite;
}

@keyframes float {
  0%, 100% { transform: translateY(0) scale(1); }
  50% { transform: translateY(-20px) scale(1.05); }
}

/* ─── Fireflies ─── */
.fireflies {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 0;
  overflow: hidden;
}

.firefly {
  position: absolute;
  border-radius: 50%;
  background: var(--glow-color);
  box-shadow:
    0 0 4px 1px var(--glow-color),
    0 0 10px 2px var(--glow-spread);
  animation:
    fireflyDrift var(--duration, 8s) ease-in-out var(--delay, 0s) infinite alternate,
    fireflyGlow var(--duration, 8s) ease-in-out var(--delay, 0s) infinite alternate;
  opacity: 0;
}

@keyframes fireflyDrift {
  0% {
    transform: translate(0, 0) scale(1);
    opacity: 0;
  }
  10% {
    opacity: 0.8;
  }
  25% {
    transform: translate(calc(var(--drift-x) * 0.5), calc(var(--drift-y) * -0.7)) scale(1.15);
    opacity: 1;
  }
  50% {
    transform: translate(calc(var(--drift-x) * -0.3), calc(var(--drift-y) * 0.4)) scale(0.9);
    opacity: 0.9;
  }
  75% {
    transform: translate(calc(var(--drift-x) * 0.8), calc(var(--drift-y) * 0.6)) scale(1.1);
    opacity: 0.7;
  }
  90% {
    opacity: 0.4;
  }
  100% {
    transform: translate(calc(var(--drift-x) * -0.4), calc(var(--drift-y) * -0.5)) scale(0.85);
    opacity: 0;
  }
}

@keyframes fireflyGlow {
  0%, 100% {
    box-shadow:
      0 0 6px 2px var(--glow-color),
      0 0 16px 4px var(--glow-spread);
  }
  50% {
    box-shadow:
      0 0 6px 2px var(--glow-color),
      0 0 14px 4px var(--glow-spread);
  }
}

.auth-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.08), 0 2px 8px rgba(0, 0, 0, 0.04);
  text-align: center;
  max-width: 420px;
  width: 100%;
  overflow: hidden;
  position: relative;
  z-index: 1;
  animation: cardIn 0.5s ease-out;
}

@keyframes cardIn {
  from { opacity: 0; transform: translateY(20px) scale(0.98); }
  to { opacity: 1; transform: translateY(0) scale(1); }
}

.card-accent {
  height: 3px;
  background: linear-gradient(90deg, var(--color-accent) 0%, var(--color-accent-hover) 50%, var(--color-accent) 100%);
}

.auth-brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0;
  padding: 2rem 2.5rem 0;
  background: linear-gradient(180deg, rgba(215, 243, 74, 0.1) 0%, transparent 100%);
}

.auth-icon {
  width: 96px;
  height: 96px;
}

.auth-wordmark {
  height: 50px;
  width: auto;
  margin-bottom: 1.7rem;
}

.auth-tagline {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  letter-spacing: 0.15em;
  text-transform: uppercase;
}

.auth-form-wrap {
  padding: 0 2.5rem 2.5rem;
}

.tabs {
  display: flex;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  overflow: hidden;
  margin-bottom: 1.5rem;
}

.tab {
  flex: 1;
  padding: 0.625rem;
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: transparent;
  border: none;
  cursor: pointer;
  transition: background 0.2s, color 0.2s;
}

.tab.active {
  background: var(--color-graphite);
  color: var(--color-surface);
}

.auth-form {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.input {
  padding: 0.75rem 1rem;
  font-size: 0.9375rem;
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

.error {
  font-size: 0.8125rem;
  color: #d32f2f;
  text-align: left;
}

.success {
  font-size: 0.8125rem;
  color: #2e7d32;
  text-align: left;
}

.submit-btn {
  padding: 0.75rem;
  font-size: 0.9375rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, opacity 0.2s;
}

.submit-btn:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(215, 243, 74, 0.35);
}

.submit-btn:active {
  transform: translateY(0);
  box-shadow: none;
}

.submit-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.divider {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-top: 1.5rem;
  margin-bottom: 1.5rem;
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--color-border);
}

.google-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
  width: 100%;
  padding: 0.75rem;
  font-size: 0.9375rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text);
  background: var(--color-surface);
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  cursor: pointer;
  transition: border-color 0.2s, box-shadow 0.2s;
}

.google-btn:hover {
  border-color: var(--color-graphite);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
  transform: translateY(-1px);
}

.google-btn:active {
  transform: translateY(0);
  box-shadow: none;
}

.google-icon {
  width: 20px;
  height: 20px;
}

.password-wrap {
  position: relative;
  display: flex;
  align-items: center;
}

.password-wrap > .input {
  width: 100%;
  padding-right: 2.75rem;
}

.toggle-pw {
  position: absolute;
  right: 0.625rem;
  top: 0;
  bottom: 0;
  margin: auto 0;
  height: fit-content;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--color-grey);
  padding: 0.25rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: color 0.2s;
  z-index: 2;
}

.toggle-pw:hover {
  color: var(--color-graphite);
}

.hcaptcha-wrap {
  display: flex;
  justify-content: center;
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}
</style>
