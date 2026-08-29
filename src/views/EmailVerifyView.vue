<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()
const status = ref('Verifying your email...')

onMounted(async () => {
  const hash = window.location.hash
  if (hash) {
    const { error } = await supabase.auth.exchangeCodeForSession(window.location.search)
    if (error) {
      status.value = 'Verification failed. The link may have expired.'
    } else {
      status.value = 'Email verified! Redirecting...'
      setTimeout(() => router.replace('/'), 1500)
    }
  } else {
    status.value = 'No verification token found. Check your email for the correct link.'
  }
})
</script>

<template>
  <div class="verify-page">
    <div class="verify-card">
      <img src="/icon.png" alt="" class="verify-icon" />
      <p class="verify-status">{{ status }}</p>
    </div>
  </div>
</template>

<style scoped>
.verify-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg);
  padding: 2rem;
}

.verify-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
  padding: 3rem 2.5rem;
  text-align: center;
  max-width: 400px;
  width: 100%;
}

.verify-icon {
  height: 72px;
  width: 72px;
  object-fit: contain;
  margin-bottom: 1.5rem;
}

.verify-status {
  font-size: 1rem;
  color: var(--color-text);
  line-height: 1.5;
}
</style>
