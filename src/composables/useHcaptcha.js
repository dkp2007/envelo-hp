import { ref, onUnmounted } from 'vue'

const siteKey = import.meta.env.VITE_HCAPTCHA_SITE_KEY
let widgetId = null

// Skip captcha on localhost / development
const isLocalhost = window.location.hostname === 'localhost'
  || window.location.hostname === '127.0.0.1'
  || window.location.hostname === ''

export function useHcaptcha() {
  const token = ref('')
  const error = ref('')

  function render(containerId) {
    // Skip captcha on localhost
    if (isLocalhost) return Promise.resolve(-1)

    return new Promise((resolve) => {
      const checkReady = setInterval(() => {
        if (window.hcaptcha) {
          clearInterval(checkReady)
          widgetId = window.hcaptcha.render(containerId, {
            sitekey: siteKey,
            callback: (t) => {
              token.value = t
              error.value = ''
            },
            'error-callback': () => {
              token.value = ''
              error.value = 'hCaptcha failed to load.'
            },
            'expired-callback': () => {
              token.value = ''
            },
          })
          resolve(widgetId)
        }
      }, 100)
    })
  }

  function reset() {
    if (isLocalhost) return
    if (widgetId !== null && window.hcaptcha) {
      window.hcaptcha.reset(widgetId)
      token.value = ''
    }
  }

  function getToken() {
    if (isLocalhost) return '' // empty token is fine on localhost
    if (token.value) return token.value
    if (widgetId !== null && window.hcaptcha) {
      return window.hcaptcha.getResponse(widgetId) || ''
    }
    return ''
  }

  onUnmounted(() => {
    reset()
  })

  return { token, error, render, reset, getToken, isLocalhost }
}
