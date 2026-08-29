<script setup>
defineProps({
  type: { type: String, required: true, validator: v => ['loading', 'error', 'empty'].includes(v) },
  icon: { type: String, default: '' },
  title: { type: String, default: '' },
  message: { type: String, default: '' },
  actionLabel: { type: String, default: '' },
})

const emit = defineEmits(['action'])

const defaults = {
  loading: { icon: '⏳', title: 'Loading...', message: 'Please wait while we fetch your data.' },
  error: { icon: '⚠️', title: 'Something went wrong', message: 'An unexpected error occurred. Please try again.' },
  empty: { icon: '📭', title: 'Nothing here yet', message: 'No data to display.' },
}
</script>

<template>
  <div class="state-display" :class="type">
    <span class="state-icon">{{ icon || defaults[type].icon }}</span>
    <h3 class="state-title">{{ title || defaults[type].title }}</h3>
    <p class="state-message">{{ message || defaults[type].message }}</p>
    <button v-if="actionLabel" class="state-action" @click="emit('action')">
      {{ actionLabel }}
    </button>
    <slot />
  </div>
</template>

<style scoped>
.state-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 3rem 2rem;
  gap: 0.75rem;
  min-height: 200px;
}

.state-icon {
  font-size: 2.5rem;
  line-height: 1;
  opacity: 0.8;
}

.state-display.loading .state-icon {
  animation: pulse 1.5s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 0.8; transform: scale(1); }
  50% { opacity: 0.5; transform: scale(1.1); }
}

.state-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
  margin: 0;
}

.state-message {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  max-width: 400px;
  line-height: 1.5;
  margin: 0;
}

.state-display.error .state-title {
  color: #d32f2f;
}

.state-action {
  margin-top: 0.5rem;
  padding: 0.625rem 1.5rem;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
}

.state-action:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
}

.state-display.error .state-action {
  background: #d32f2f;
  color: #fff;
}

.state-display.error .state-action:hover {
  background: #b71c1c;
}
</style>
