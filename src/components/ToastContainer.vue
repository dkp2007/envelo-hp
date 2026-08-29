<script setup>
import { useToast } from '@/composables/useToast.js'
const { toasts, dismiss } = useToast()
</script>

<template>
  <div class="toast-container" aria-live="polite">
    <TransitionGroup name="toast">
      <div
        v-for="t in toasts"
        :key="t.id"
        class="toast"
        :class="[t.type, { leaving: t.leaving }]"
        @click="dismiss(t.id)"
      >
        <span class="toast-icon">
          {{ t.type === 'success' ? '✅' : t.type === 'error' ? '❌' : t.type === 'warning' ? '⚠️' : 'ℹ️' }}
        </span>
        <span class="toast-message">{{ t.message }}</span>
        <button class="toast-close" @click.stop="dismiss(t.id)">✕</button>
      </div>
    </TransitionGroup>
  </div>
</template>

<style scoped>
.toast-container {
  position: fixed;
  top: 1rem;
  right: 1rem;
  z-index: 9999;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  max-width: 400px;
  pointer-events: none;
}

.toast {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.875rem 1rem;
  border-radius: var(--radius);
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  pointer-events: auto;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(8px);
}

.toast.success {
  background: #e8f5e9;
  color: #1b5e20;
  border: 1px solid #a5d6a7;
}

.toast.error {
  background: #fce4ec;
  color: #b71c1c;
  border: 1px solid #ef9a9a;
}

.toast.warning {
  background: #fff3e0;
  color: #e65100;
  border: 1px solid #ffcc80;
}

.toast.info {
  background: #e3f2fd;
  color: #0d47a1;
  border: 1px solid #90caf9;
}

.toast-icon {
  font-size: 1rem;
  flex-shrink: 0;
}

.toast-message {
  flex: 1;
  line-height: 1.4;
}

.toast-close {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.06);
  color: inherit;
  font-size: 0.625rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  opacity: 0.6;
  transition: opacity 0.15s;
}

.toast-close:hover { opacity: 1; }

/* Transitions */
.toast-enter-active {
  transition: all 0.3s cubic-bezier(0.21, 1.02, 0.73, 1);
}

.toast-leave-active {
  transition: all 0.25s cubic-bezier(0.06, 0.71, 0.55, 1);
}

.toast-enter-from {
  opacity: 0;
  transform: translateX(100%) scale(0.95);
}

.toast-leave-to {
  opacity: 0;
  transform: translateX(100%) scale(0.95);
}

.toast-move {
  transition: transform 0.3s ease;
}
</style>
