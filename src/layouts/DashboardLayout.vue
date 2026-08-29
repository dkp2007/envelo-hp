<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useNotificationStore } from '@/stores/notifications'

const auth = useAuthStore()
const notifStore = useNotificationStore()
const route = useRoute()
const router = useRouter()
const showProfileMenu = ref(false)
const showNotifPanel = ref(false)
const expandedNotif = ref(null)
const collapsed = ref(true)
const sidebarRef = ref(null)
let isOverSidebar = false
let collapseTimer = null

function checkMousePosition(e) {
  if (!sidebarRef.value) return
  const rect = sidebarRef.value.getBoundingClientRect()
  const over = e.clientX <= rect.right && e.clientX >= rect.left && e.clientY >= rect.top && e.clientY <= rect.bottom

  if (over && !isOverSidebar) {
    isOverSidebar = true
    collapsed.value = false
    if (collapseTimer) {
      clearTimeout(collapseTimer)
      collapseTimer = null
    }
  } else if (!over && isOverSidebar) {
    isOverSidebar = false
    if (collapseTimer) clearTimeout(collapseTimer)
    collapseTimer = setTimeout(() => {
      if (!isOverSidebar) collapsed.value = true
    }, 300)
  }
}

const navItems = [
  { label: 'Overview', icon: '📊', to: '/dashboard' },
  { label: 'Envelopes', icon: '✉️', to: '/envelopes' },
  { label: 'Transactions', icon: '💳', to: '/transactions' },
  { label: 'Add Expense', icon: '➕', to: '/add-expense' },
  { label: 'Savings Goals', icon: '🎯', to: '/savings-goals' },
  { label: 'Analytics', icon: '📈', to: '/analytics' },
  { label: 'Reports', icon: '📋', to: '/reports' },
  { label: 'Stress Test', icon: '🛡️', to: '/stress-test' },
]

const profileMenuItems = [
  { label: 'Profile Settings', action: 'profile' },
  { label: 'Help & Support', action: 'help' },
]

function toggleProfileMenu() {
  showProfileMenu.value = !showProfileMenu.value
  if (showProfileMenu.value) showNotifPanel.value = false
}

function timeAgo(dateStr) {
  const now = new Date()
  const d = new Date(dateStr)
  const diff = Math.floor((now - d) / 1000)
  if (diff < 60) return 'just now'
  if (diff < 3600) return Math.floor(diff / 60) + 'm ago'
  if (diff < 86400) return Math.floor(diff / 3600) + 'h ago'
  if (diff < 604800) return Math.floor(diff / 86400) + 'd ago'
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
}

function toggleNotifPanel() {
  showNotifPanel.value = !showNotifPanel.value
  if (showNotifPanel.value) {
    showProfileMenu.value = false
    // Mark all as read when opening
    setTimeout(() => notifStore.markAllRead(), 2000)
  }
}

function expandNotif(id) {
  expandedNotif.value = expandedNotif.value === id ? null : id
  notifStore.markRead(id)
}

function handleNotifClick(notif) {
  if (notif.action_url) {
    showNotifPanel.value = false
    router.push(notif.action_url)
  } else {
    expandNotif(notif.id)
  }
}

async function handleMenuAction(action) {
  showProfileMenu.value = false
  if (action === 'logout') {
    await auth.logout()
    router.push('/')
  } else if (action === 'help') {
    router.push('/help')
  } else if (action === 'profile') {
    router.push('/settings')
  }
}

onMounted(() => {
  document.addEventListener('mousemove', checkMousePosition)
  // Load notifications and generate alerts from real data
  notifStore.fetchAll().then(() => notifStore.generateAlerts())
})

onUnmounted(() => {
  document.removeEventListener('mousemove', checkMousePosition)
  if (collapseTimer) clearTimeout(collapseTimer)
})
</script>

<template>
  <div class="dashboard-layout" @click.self="showProfileMenu = false; showNotifPanel = false">
    <aside
      ref="sidebarRef"
      class="sidebar"
      :class="{ collapsed }"
    >
      <div class="sidebar-brand">
        <img src="/icon.png" alt="" class="sidebar-icon" />
        <div v-if="!collapsed" class="sidebar-brand-text">
          <img src="/wordmark.png" alt="Envelo" class="sidebar-wordmark" />
        </div>
      </div>

      <nav class="sidebar-nav">
        <router-link
          v-for="item in navItems"
          :key="item.label"
          :to="item.to"
          class="nav-item"
          :class="{ active: route.path === item.to }"
          :title="item.label"
          @click="onNavClick"
        >
          <span class="nav-icon">{{ item.icon }}</span>
          <span v-if="!collapsed" class="nav-label">{{ item.label }}</span>
        </router-link>
      </nav>


    </aside>

    <div class="main-area">
      <header class="topbar">
        <h2 class="topbar-title">{{ route.meta.title || 'Overview' }}</h2>
        <div class="topbar-right">
          <!-- Bell Icon -->
          <div class="notif-wrap">
            <button class="notif-btn" @click="toggleNotifPanel">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>
              <span v-if="notifStore.unreadCount > 0" class="notif-badge">{{ notifStore.unreadCount > 9 ? '9+' : notifStore.unreadCount }}</span>
            </button>

            <!-- Notification Panel -->
            <div v-if="showNotifPanel" class="notif-panel">
              <div class="notif-panel-header">
                <h3 class="notif-panel-title">Notifications</h3>
                <button v-if="notifStore.notifications.length > 0" class="notif-clear" @click="notifStore.clearAll()">Clear all</button>
              </div>

              <div v-if="notifStore.loading" class="notif-loading">
                <span class="notif-spinner"></span>
              </div>

              <div v-else-if="notifStore.notifications.length === 0" class="notif-empty">
                <span class="notif-empty-icon">🔔</span>
                <p>No notifications yet</p>
              </div>

              <div v-else class="notif-list">
                <div
                  v-for="n in notifStore.notifications"
                  :key="n.id"
                  class="notif-item"
                  :class="{ unread: !n.read, expanded: expandedNotif === n.id }"
                  @click="handleNotifClick(n)"
                >
                  <div class="notif-item-top">
                    <span class="notif-icon">{{ n.icon }}</span>
                    <div class="notif-content">
                      <p class="notif-title">{{ n.title }}</p>
                      <p class="notif-time">{{ timeAgo(n.created_at) }}</p>
                    </div>
                    <button v-if="expandedNotif !== n.id" class="notif-expand" @click.stop="expandNotif(n.id)">›</button>
                    <button class="notif-delete" @click.stop="notifStore.remove(n.id)">✕</button>
                  </div>
                  <div v-if="expandedNotif === n.id" class="notif-body">
                    <p class="notif-message">{{ n.message }}</p>
                    <button v-if="n.action_url" class="notif-action" @click.stop="handleNotifClick(n)">
                      View Details →
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="profile-wrap">              <button class="profile-btn" @click.stop="toggleProfileMenu">
              <img
                v-if="auth.user?.user_metadata?.avatar_url"
                :src="auth.user.user_metadata.avatar_url"
                alt=""
                class="profile-avatar"
              />
              <div v-else class="profile-avatar fallback">
                {{ auth.user?.user_metadata?.full_name?.charAt(0) || 'U' }}
              </div>
              <span class="profile-name">{{ auth.user?.user_metadata?.full_name || 'User' }}</span>
              <svg class="profile-chevron" :class="{ open: showProfileMenu }" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 12 15 18 9"/></svg>
            </button>
            <div v-if="showProfileMenu" class="profile-dropdown">
              <div class="dropdown-header">
                <img
                  v-if="auth.user?.user_metadata?.avatar_url"
                  :src="auth.user.user_metadata.avatar_url"
                  alt=""
                  class="dropdown-avatar"
                />
                <div v-else class="dropdown-avatar fallback">
                  {{ auth.user?.user_metadata?.full_name?.charAt(0) || 'U' }}
                </div>
                <div>
                  <p class="dropdown-name">{{ auth.user?.user_metadata?.full_name || 'User' }}</p>
                  <p class="dropdown-email">{{ auth.user?.email }}</p>
                </div>
              </div>
              <div class="dropdown-divider"></div>
              <button
                v-for="item in profileMenuItems"
                :key="item.action"
                class="dropdown-item"
                @click="handleMenuAction(item.action)"
              >
                {{ item.label }}
              </button>
              <div class="dropdown-divider"></div>
              <button class="dropdown-item logout" @click="handleMenuAction('logout')">
                Log out
              </button>
            </div>
          </div>
        </div>
      </header>

      <main class="main-content">
        <slot />

        <!-- Footer -->
        <footer class="app-footer">
          <div class="footer-inner">
            <div class="footer-left">
              <img src="/icon.png" alt="" class="footer-logo" />
              <span class="footer-brand">Envelo</span>
            </div>
            <div class="footer-links">
              <router-link to="/privacypolicy" class="footer-link">Privacy Policy</router-link>
              <span class="footer-dot">·</span>
              <router-link to="/termsofservice" class="footer-link">Terms of Service</router-link>
              <span class="footer-dot">·</span>
              <router-link to="/help" class="footer-link">Help</router-link>
            </div>
            <p class="footer-copy">© {{ new Date().getFullYear() }} Envelo</p>
          </div>
        </footer>
      </main>
    </div>
  </div>
</template>

<style scoped>
.dashboard-layout {
  display: flex;
  height: 100vh;
  background: var(--color-bg);
  overflow: hidden;
}

.sidebar {
  background: var(--color-graphite);
  color: var(--color-surface);
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  width: 220px;
  transition: width 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.sidebar.collapsed {
  width: 60px;
  transition: width 0.25s cubic-bezier(0.4, 0, 1, 1);
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0 0.875rem;
  height: 56px;
  flex-shrink: 0;
  position: relative;
}

.collapsed .sidebar-brand {
  justify-content: center;
  padding: 0;
}

.sidebar-icon {
  width: 36px;
  height: 36px;
  object-fit: contain;
  flex-shrink: 0;
}

.sidebar-brand-text {
  display: flex;
  flex-direction: column;
  overflow: hidden;
  opacity: 1;
  transition: opacity 0.15s ease;
}

.sidebar.collapsed .sidebar-brand-text {
  opacity: 0;
  transition: opacity 0.1s ease;
}

.sidebar-wordmark {
  height: 22px;
  width: auto;
  object-fit: contain;
  filter: brightness(10);
}

.sidebar-nav {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  flex: 1;
  padding-top: 0.5rem;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 1.25rem;
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: rgba(255, 255, 255, 0.6);
  background: none;
  border: none;
  cursor: pointer;
  text-align: left;
  text-decoration: none;
  transition: background 0.2s ease, color 0.2s ease, padding 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
  white-space: nowrap;
}

.sidebar.collapsed .nav-item {
  justify-content: center;
  padding: 0.75rem 0.5rem;
  transition: background 0.2s ease, color 0.2s ease, padding 0.2s cubic-bezier(0.4, 0, 1, 1);
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.08);
  color: var(--color-surface);
}

.nav-item.active {
  background: var(--color-accent);
  color: var(--color-graphite);
  font-weight: 600;
}

.nav-item.active:not(.collapsed .nav-item) {
  border-radius: 0 var(--radius) var(--radius) 0;
  margin-right: 0.75rem;
}


.nav-icon {
  font-size: 1.125rem;
  width: 20px;
  text-align: center;
  flex-shrink: 0;
  transition: transform 0.25s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.sidebar:hover .nav-icon {
  transform: scale(1.1);
}

.sidebar.collapsed .nav-icon {
  transform: scale(1);
  transition: transform 0.2s cubic-bezier(0.4, 0, 1, 1);
}

.nav-label {
  overflow: hidden;
  opacity: 1;
  transition: opacity 0.15s ease;
}

.sidebar.collapsed .nav-label {
  opacity: 0;
  transition: opacity 0.1s ease;
}

.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
  overflow: hidden;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 2rem;
  height: 56px;
  min-height: 56px;
  background: var(--color-surface);
  border-bottom: 1px solid var(--color-border);
  flex-shrink: 0;
}

.topbar-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-text);
}

.topbar-right {
  display: flex;
  align-items: center;
}

.profile-wrap {
  position: relative;
}

.profile-btn {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  padding: 0.375rem 0.625rem;
  background: none;
  border: 1px solid transparent;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.15s, border-color 0.15s;
}

.profile-btn:hover {
  background: var(--color-bg);
  border-color: var(--color-border);
}

.profile-avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.profile-avatar.fallback {
  background: var(--color-graphite);
  color: var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8125rem;
  font-weight: 700;
}

.profile-name {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
}

.profile-chevron {
  color: var(--color-text-muted);
  transition: transform 0.2s;
}

.profile-chevron.open {
  transform: rotate(180deg);
}

/* ─── Notifications ─── */
.notif-wrap { position: relative; }

.notif-btn {
  position: relative;
  width: 36px;
  height: 36px;
  border-radius: var(--radius);
  border: none;
  background: none;
  color: var(--color-text-muted);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s, color 0.15s;
}

.notif-btn:hover { background: var(--color-bg); color: var(--color-text); }

.notif-badge {
  position: absolute;
  top: 2px;
  right: 2px;
  min-width: 16px;
  height: 16px;
  font-size: 0.5625rem;
  font-weight: 700;
  color: #fff;
  background: #d32f2f;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  line-height: 1;
}

.notif-panel {
  position: absolute;
  top: calc(100% + 6px);
  right: -60px;
  width: 380px;
  max-height: 480px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12);
  z-index: 300;
  display: flex;
  flex-direction: column;
  animation: dropIn 0.15s ease-out;
}

.notif-panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--color-bg);
}

.notif-panel-title {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text);
}

.notif-clear {
  font-size: 0.75rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: none;
  border: none;
  cursor: pointer;
  transition: color 0.15s;
}

.notif-clear:hover { color: #d32f2f; }

.notif-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem;
}

.notif-spinner {
  width: 24px;
  height: 24px;
  border: 2.5px solid var(--color-border);
  border-top-color: var(--color-graphite);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

.notif-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  padding: 2.5rem 1rem;
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.notif-empty-icon { font-size: 1.5rem; opacity: 0.5; }

.notif-list {
  overflow-y: auto;
  flex: 1;
}

.notif-item {
  padding: 0.875rem 1.25rem;
  border-bottom: 1px solid var(--color-bg);
  cursor: pointer;
  transition: background 0.12s;
}

.notif-item:hover { background: rgba(0, 0, 0, 0.02); }

.notif-item.unread {
  background: rgba(215, 243, 74, 0.06);
}

.notif-item-top {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
}

.notif-icon {
  font-size: 1.125rem;
  flex-shrink: 0;
  margin-top: 0.125rem;
}

.notif-content { flex: 1; min-width: 0; }

.notif-title {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
  line-height: 1.4;
}

.notif-time {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.notif-expand {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: none;
  color: var(--color-text-muted);
  font-size: 0.875rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: transform 0.2s, color 0.15s;
}

.notif-expand:hover { color: var(--color-text); }

.notif-item.expanded .notif-expand { transform: rotate(90deg); }

.notif-delete {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: none;
  color: var(--color-grey);
  font-size: 0.625rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  opacity: 0;
  transition: opacity 0.15s, color 0.15s;
}

.notif-item:hover .notif-delete { opacity: 1; }
.notif-delete:hover { color: #d32f2f; }

.notif-body {
  margin-top: 0.75rem;
  padding-top: 0.75rem;
  border-top: 1px solid var(--color-bg);
  animation: fadeUp 0.2s ease;
}

@keyframes fadeUp { from { opacity: 0; transform: translateY(-4px); } to { opacity: 1; transform: translateY(0); } }

.notif-message {
  font-size: 0.8125rem;
  line-height: 1.6;
  color: var(--color-text-muted);
}

.notif-action {
  margin-top: 0.75rem;
  padding: 0.5rem 1rem;
  font-size: 0.75rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.15s;
}

.notif-action:hover { background: var(--color-accent-hover); }

/* ─── Profile Dropdown ─── */
.profile-dropdown {
  position: absolute;
  top: calc(100% + 6px);
  right: 0;
  width: 240px;
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
  z-index: 200;
  padding: 0.5rem;
  animation: dropIn 0.15s ease-out;
}

@keyframes dropIn {
  from { opacity: 0; transform: translateY(-4px); }
  to { opacity: 1; transform: translateY(0); }
}

.dropdown-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
}

.dropdown-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
}

.dropdown-avatar.fallback {
  background: var(--color-graphite);
  color: var(--color-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  font-weight: 700;
}

.dropdown-name {
  font-size: 0.875rem;
  font-weight: 600;
  color: var(--color-text);
}

.dropdown-email {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
  max-width: 160px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.dropdown-divider {
  height: 1px;
  background: var(--color-bg);
  margin: 0.25rem 0;
}

.dropdown-item {
  display: block;
  width: 100%;
  padding: 0.625rem 0.75rem;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text);
  background: none;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  transition: background 0.12s;
}

.dropdown-item:hover {
  background: var(--color-bg);
}

.dropdown-item.logout {
  color: #d32f2f;
}

.dropdown-item.logout:hover {
  background: rgba(211, 47, 47, 0.06);
}

.main-content {
  flex: 1;
  padding: 1.5rem 2rem;
  overflow-y: auto;
  overflow-x: hidden;
  display: flex;
  flex-direction: column;
}

.main-content > :first-child {
  flex: 1;
}

/* ─── Footer ─── */
.app-footer {
  margin-top: auto;
  padding-top: 1.25rem;
  border-top: 1px solid var(--color-bg);
  flex-shrink: 0;
}

.footer-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.footer-left {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.footer-logo {
  width: 18px;
  height: 18px;
  object-fit: contain;
}

.footer-brand {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
}

.footer-links {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.footer-link {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  text-decoration: none;
  transition: color 0.2s;
}

.footer-link:hover {
  color: var(--color-text);
}

.footer-dot {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.footer-copy {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
}
</style>
