import { ref } from 'vue'

const toasts = ref([])
let toastId = 0

export function useToast() {
  function show(message, type = 'info', duration = 4000) {
    const id = ++toastId
    toasts.value.push({ id, message, type, leaving: false })

    setTimeout(() => {
      const t = toasts.value.find(t => t.id === id)
      if (t) t.leaving = true
      setTimeout(() => {
        toasts.value = toasts.value.filter(t => t.id !== id)
      }, 300)
    }, duration)
  }

  function success(message, duration) { show(message, 'success', duration) }
  function error(message, duration) { show(message, 'error', duration || 6000) }
  function info(message, duration) { show(message, 'info', duration) }
  function warn(message, duration) { show(message, 'warning', duration) }

  function dismiss(id) {
    const t = toasts.value.find(t => t.id === id)
    if (t) t.leaving = true
    setTimeout(() => {
      toasts.value = toasts.value.filter(t => t.id !== id)
    }, 300)
  }

  return { toasts, show, success, error, info, warn, dismiss }
}
