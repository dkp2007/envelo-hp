import { ref } from 'vue'

const siteKey = import.meta.env.VITE_HCAPTCHA_SITE_KEY

const isLocalhost =
  window.location.hostname === 'localhost' ||
  window.location.hostname === '127.0.0.1' ||
  window.location.hostname === ''

/**
 * Shared captcha state used by AuthView.
 * The actual <vue-hcaptcha> component is rendered in AuthView template.
 * This composable just holds the token and error state.
 */
export function useHcaptcha() {
  const token = ref('')
  const error = ref('')
  const isExpired = ref(false)

  function onVerify(t, eKey) {
    token.value = t
    error.value = ''
    isExpired.value = false
  }

  function onExpire() {
    token.value = ''
    isExpired.value = true
  }

  function onError(err) {
    token.value = ''
    error.value = typeof err === 'string' ? err : 'Captcha failed. Please try again.'
  }

  function resetToken() {
    token.value = ''
    isExpired.value = false
    error.value = ''
  }

  function getToken() {
    if (isLocalhost) return 'localhost-skip'
    return token.value || ''
  }

  function hasValidToken() {
    if (isLocalhost) return true
    return !!token.value
  }

  return {
    siteKey,
    token,
    error,
    isExpired,
    isLocalhost,
    onVerify,
    onExpire,
    onError,
    resetToken,
    getToken,
    hasValidToken,
  }
}
