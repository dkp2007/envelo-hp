import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const loading = ref(true)

  const isLoggedIn = computed(() => !!user.value)

  async function init() {
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user ?? null
    loading.value = false

    supabase.auth.onAuthStateChange((_event, session) => {
      user.value = session?.user ?? null
    })
  }

  async function loginWithGoogle(captchaToken) {
    const options = { redirectTo: window.location.origin }
    if (captchaToken) options.captchaToken = captchaToken
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options,
    })
    if (error) throw error
  }

  async function signInWithEmail(email, password, captchaToken) {
    const options = {}
    if (captchaToken) options.captchaToken = captchaToken
    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
      ...(Object.keys(options).length ? { options } : {}),
    })
    if (error) throw error
  }

  async function signUpWithEmail(email, password, captchaToken) {
    const options = {
      emailRedirectTo: window.location.origin + '/auth/verify',
    }
    if (captchaToken) options.captchaToken = captchaToken
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options,
    })
    if (error) throw error
  }

  async function logout() {
    await supabase.auth.signOut()
    user.value = null
  }

  return { user, loading, isLoggedIn, init, loginWithGoogle, signInWithEmail, signUpWithEmail, logout }
})