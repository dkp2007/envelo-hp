<script setup>
import { ref, onMounted } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { supabase } from '@/lib/supabase.js'
import { useAuthStore } from '@/stores/auth.js'
import { processBill } from '@/lib/ocr.js'

const auth = useAuthStore()

const type = ref('expense')
const name = ref('')
const amount = ref('')
const category = ref('')
const date = ref(new Date().toISOString().split('T')[0])
const notes = ref('')

const billFile = ref(null)
const billPreview = ref(null)
const dragOver = ref(false)

// OCR state
const ocrProcessing = ref(false)
const ocrProgress = ref(0)
const ocrResult = ref(null) // { name, amount, date, category, merchant, rawText }
const ocrError = ref('')

const allCategories = ref([])
const parentCategories = ref([])
const subCategories = ref([])
const selectedParent = ref(null)
const subCategory = ref('')
const loading = ref(false)
const success = ref(false)
const errorMsg = ref('')

// Uploaded bills
const uploadedBills = ref([])
const billsLoading = ref(false)

async function getSignedUrl(path) {
  if (!path) return null
  const { data } = await supabase.storage
    .from('bills')
    .createSignedUrl(path, 3600) // 1 hour expiry
  return data?.signedUrl || null
}

async function fetchBills() {
  if (!auth.user) return
  billsLoading.value = true
  const { data } = await supabase
    .from('transactions')
    .select('id, name, amount, type, date, bill_path, categories(name, icon)')
    .eq('user_id', auth.user.id)
    .not('bill_path', 'is', null)
    .order('date', { ascending: false })
    .limit(20)

  if (data) {
    // Generate signed URLs for each bill
    const billsWithUrls = await Promise.all(
      data.map(async (bill) => {
        const signedUrl = await getSignedUrl(bill.bill_path)
        return { ...bill, signedUrl }
      })
    )
    uploadedBills.value = billsWithUrls
  } else {
    uploadedBills.value = []
  }
  billsLoading.value = false
}

async function downloadBill(bill) {
  if (!bill.signedUrl) return
  const resp = await fetch(bill.signedUrl)
  const blob = await resp.blob()
  const ext = bill.bill_path.split('.').pop()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${bill.name.replace(/\s+/g, '_')}.${ext}`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

// Hardcoded fallback categories (used when DB has none)
const FALLBACK_CATEGORIES = [
  { id: 'fb-rent', name: 'Rent', icon: '🏠', color: '#202124', parent_id: null, type: 'expense' },
  { id: 'fb-housing', name: 'Housing', icon: '🏠', color: '#202124', parent_id: 'fb-rent', type: 'expense' },
  { id: 'fb-utilities', name: 'Utilities', icon: '💡', color: '#f472b6', parent_id: 'fb-rent', type: 'expense' },
  { id: 'fb-internet', name: 'Internet', icon: '🌐', color: '#4285F4', parent_id: 'fb-rent', type: 'expense' },
  { id: 'fb-maintenance', name: 'Maintenance', icon: '🔧', color: '#795548', parent_id: 'fb-rent', type: 'expense' },
  { id: 'fb-food', name: 'Food', icon: '🍔', color: '#D7F34A', parent_id: null, type: 'expense' },
  { id: 'fb-groceries', name: 'Groceries', icon: '🛒', color: '#D7F34A', parent_id: 'fb-food', type: 'expense' },
  { id: 'fb-dining', name: 'Dining Out', icon: '🍽️', color: '#fb923c', parent_id: 'fb-food', type: 'expense' },
  { id: 'fb-delivery', name: 'Delivery', icon: '🛵', color: '#f472b6', parent_id: 'fb-food', type: 'expense' },
  { id: 'fb-coffee', name: 'Coffee', icon: '☕', color: '#795548', parent_id: 'fb-food', type: 'expense' },
  { id: 'fb-fun', name: 'Fun', icon: '🎮', color: '#4285F4', parent_id: null, type: 'expense' },
  { id: 'fb-entertainment', name: 'Entertainment', icon: '🎬', color: '#a78bfa', parent_id: 'fb-fun', type: 'expense' },
  { id: 'fb-shopping', name: 'Shopping', icon: '🛍️', color: '#fb923c', parent_id: 'fb-fun', type: 'expense' },
  { id: 'fb-travel', name: 'Travel', icon: '✈️', color: '#4285F4', parent_id: 'fb-fun', type: 'expense' },
  { id: 'fb-subs', name: 'Subscriptions', icon: '📱', color: '#f472b6', parent_id: 'fb-fun', type: 'expense' },
  { id: 'fb-savings', name: 'Savings', icon: '💰', color: '#2e7d32', parent_id: null, type: 'expense' },
  { id: 'fb-emergency', name: 'Emergency Fund', icon: '🏦', color: '#2e7d32', parent_id: 'fb-savings', type: 'expense' },
  { id: 'fb-investments', name: 'Investments', icon: '📈', color: '#4285F4', parent_id: 'fb-savings', type: 'expense' },
  { id: 'fb-goals', name: 'Goals', icon: '🎯', color: '#D7F34A', parent_id: 'fb-savings', type: 'expense' },
  { id: 'fb-salary', name: 'Salary', icon: '💼', color: '#2e7d32', parent_id: null, type: 'income' },
  { id: 'fb-base', name: 'Base Salary', icon: '💰', color: '#2e7d32', parent_id: 'fb-salary', type: 'income' },
  { id: 'fb-bonus', name: 'Bonus', icon: '🎁', color: '#388e3c', parent_id: 'fb-salary', type: 'income' },
  { id: 'fb-freelance', name: 'Freelance', icon: '💻', color: '#4285F4', parent_id: null, type: 'income' },
  { id: 'fb-projects', name: 'Projects', icon: '📋', color: '#4285F4', parent_id: 'fb-freelance', type: 'income' },
]

// Fetch user's categories from DB, split into parents and subs
async function fetchCategories() {
  if (!auth.user) return
  const { data } = await supabase
    .from('categories')
    .select('id, name, icon, parent_id, type')
    .eq('user_id', auth.user.id)
    .order('name')

  if (data && data.length > 0) {
    allCategories.value = data
  } else {
    // Use hardcoded fallback when no DB categories exist
    allCategories.value = FALLBACK_CATEGORIES
  }
  filterByType(type.value)
}

function filterByType(t) {
  parentCategories.value = allCategories.value.filter(c => !c.parent_id && c.type === t)
  subCategories.value = []
  selectedParent.value = null
  subCategory.value = ''
  category.value = ''
}

onMounted(() => {
  fetchCategories()
  fetchBills()
})

function selectParent(cat) {
  selectedParent.value = cat
  subCategory.value = ''
  category.value = cat.id
  // Find subcategories for this parent
  subCategories.value = allCategories.value.filter(c => c.parent_id === cat.id)
}

function selectSub(sub) {
  subCategory.value = sub.id
  category.value = sub.id
}

function switchType(t) {
  type.value = t
  filterByType(t)
}

// Upload bill to Supabase Storage — returns the storage path
async function uploadBill(userId) {
  if (!billFile.value) return null

  const ext = billFile.value.name.split('.').pop()
  const path = `${userId}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`

  const { error } = await supabase.storage
    .from('bills')
    .upload(path, billFile.value, {
      contentType: billFile.value.type,
      upsert: false,
    })

  if (error) throw error
  return path // store the path, not the URL
}

// Submit form
async function handleSubmit() {
  if (!auth.user) return
  if (!name.value.trim()) { errorMsg.value = 'Please enter a name'; return }
  if (!amount.value || Number(amount.value) <= 0) { errorMsg.value = 'Please enter a valid amount'; return }
  if (!category.value) { errorMsg.value = 'Please select a category'; return }

  loading.value = true
  errorMsg.value = ''
  success.value = false

  try {
    // Upload bill if present
    let billPath = null
    if (billFile.value) {
      billPath = await uploadBill(auth.user.id)
    }

    // Resolve category_id: if using fallback (fb-*), insert category into DB first
    let resolvedCategoryId = category.value
    if (resolvedCategoryId && resolvedCategoryId.startsWith('fb-')) {
      const fallbackCat = FALLBACK_CATEGORIES.find(c => c.id === resolvedCategoryId)
      if (fallbackCat) {
        const { data: newCat, error: catErr } = await supabase
          .from('categories')
          .insert({
            user_id: auth.user.id,
            name: fallbackCat.name,
            icon: fallbackCat.icon,
            color: fallbackCat.color,
            parent_id: null,
            type: fallbackCat.type,
          })
          .select('id')
          .single()
        if (catErr) {
          console.warn('Could not create category:', catErr)
          resolvedCategoryId = null // insert without category
        } else {
          resolvedCategoryId = newCat.id
        }
      }
    }

    // Insert transaction
    const txData = {
      user_id: auth.user.id,
      name: name.value.trim(),
      amount: type.value === 'expense' ? -Math.abs(Number(amount.value)) : Math.abs(Number(amount.value)),
      type: type.value,
      date: date.value,
      notes: notes.value.trim() || null,
      bill_path: billPath,
      merchant: ocrResult.value?.merchant || null,
      ocr_raw_text: ocrResult.value?.rawText || null,
    }
    // Only set category_id if it's a real DB ID
    if (resolvedCategoryId && !resolvedCategoryId.startsWith('fb-')) {
      txData.category_id = resolvedCategoryId
    }
    const { error } = await supabase.from('transactions').insert(txData)

    if (error) throw error

    success.value = true
    // Reset form
    name.value = ''
    amount.value = ''
    category.value = ''
    selectedParent.value = null
    subCategory.value = ''
    subCategories.value = []
    date.value = new Date().toISOString().split('T')[0]
    notes.value = ''
    removeFile()
    ocrResult.value = null
    ocrError.value = ''
    fetchBills() // refresh bills list

    setTimeout(() => { success.value = false }, 3000)
  } catch (err) {
    errorMsg.value = err.message || 'Failed to save transaction'
  } finally {
    loading.value = false
  }
}

function handleFile(file) {
  billFile.value = file
  billPreview.value = null
  ocrResult.value = null
  ocrError.value = ''

  if (file.type.startsWith('image/')) {
    billPreview.value = URL.createObjectURL(file)
    // Auto-run OCR on image files
    runOcr(file)
  }
}

async function runOcr(file) {
  ocrProcessing.value = true
  ocrProgress.value = 0
  ocrError.value = ''
  ocrResult.value = null

  try {
    const result = await processBill(file, (p) => { ocrProgress.value = p })
    ocrResult.value = result
    // Auto-fill form fields from OCR data (only if they have values)
    if (result.name && !name.value) name.value = result.name
    if (result.amount && !amount.value) amount.value = result.amount
    if (result.date && !date.value) date.value = result.date
    // Try to match category
    if (result.category) {
      const match = allCategories.value.find(
        c => c.name.toLowerCase() === result.category.toLowerCase() && !c.parent_id
      )
      if (match) {
        selectedParent.value = match
        category.value = match.id
        subCategories.value = allCategories.value.filter(c => c.parent_id === match.id)
      }
    }
  } catch (err) {
    console.error('OCR pipeline error:', err)
    ocrError.value = err.message || 'Failed to read bill. Try uploading a clearer image.'
  } finally {
    ocrProcessing.value = false
  }
}

function applyOcrField(field, value) {
  if (field === 'name') name.value = value
  else if (field === 'amount') amount.value = value
  else if (field === 'date') date.value = value
}

function dismissOcrResult() {
  ocrResult.value = null
  ocrError.value = ''
}

function onDragOver(e) {
  e.preventDefault()
  dragOver.value = true
}

function onDragLeave() {
  dragOver.value = false
}

function onDrop(e) {
  e.preventDefault()
  dragOver.value = false
  const file = e.dataTransfer.files[0]
  if (file) handleFile(file)
}

function onFileSelect(e) {
  const file = e.target.files[0]
  if (file) handleFile(file)
}

function removeFile() {
  billFile.value = null
  billPreview.value = null
}

function isImage(path) {
  if (!path) return false
  return /\.(jpg|jpeg|png|webp|gif)$/i.test(path)
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
      <!-- Success toast -->
      <Transition name="toast">
        <div v-if="success" class="toast success">
          ✅ Transaction added successfully!
        </div>
      </Transition>

      <!-- Error toast -->
      <Transition name="toast">
        <div v-if="errorMsg" class="toast error" @click="errorMsg = ''">
          ❌ {{ errorMsg }}
        </div>
      </Transition>

      <div class="two-col">
        <!-- Left: Form -->
        <div class="form-card">
          <div class="type-toggle">
            <button
              class="type-btn"
              :class="{ active: type === 'expense', expense: type === 'expense' }"
              @click="switchType('expense')"
            >
              Expense
            </button>
            <button
              class="type-btn"
              :class="{ active: type === 'income', income: type === 'income' }"
              @click="switchType('income')"
            >
              Income
            </button>
          </div>

          <form class="form" @submit.prevent="handleSubmit">
            <div class="field">
              <label class="label">Name</label>
              <input v-model="name" type="text" placeholder="e.g. Grocery shopping" class="input" />
            </div>

            <div class="field">
              <label class="label">Amount (₹)</label>
              <input v-model="amount" type="number" placeholder="0.00" class="input" min="0" step="0.01" />
            </div>

            <div class="field">
              <label class="label">Category</label>
              <div class="category-grid">
                <button
                  v-for="cat in parentCategories"
                  :key="cat.id"
                  type="button"
                  class="cat-btn"
                  :class="{ active: selectedParent?.id === cat.id }"
                  @click="selectParent(cat)"
                >
                  {{ cat.icon }} {{ cat.name }}
                </button>
              </div>
              <p v-if="parentCategories.length === 0" class="field-hint">
                No categories found. Run the seed data from your Supabase dashboard first.
              </p>
            </div>

            <!-- Subcategories appear after selecting a parent -->
            <Transition name="subcat-slide">
              <div v-if="subCategories.length > 0" class="field">
                <label class="label">
                  Subcategory
                  <span class="subcat-hint">under {{ selectedParent?.icon }} {{ selectedParent?.name }}</span>
                </label>
                <div class="category-grid subcategory-grid">
                  <button
                    v-for="sub in subCategories"
                    :key="sub.id"
                    type="button"
                    class="cat-btn subcat-btn"
                    :class="{ active: subCategory === sub.id }"
                    @click="selectSub(sub)"
                  >
                    {{ sub.icon }} {{ sub.name }}
                  </button>
                  <button
                    type="button"
                    class="cat-btn subcat-btn skip-btn"
                    :class="{ active: subCategory === '' && selectedParent }"
                    @click="subCategory = ''; category = selectedParent.id"
                  >
                    General (skip)
                  </button>
                </div>
              </div>
            </Transition>

            <div class="field">
              <label class="label">Date</label>
              <input v-model="date" type="date" class="input" />
            </div>

            <div class="field">
              <label class="label">Notes (optional)</label>
              <textarea v-model="notes" placeholder="Any additional details..." class="input textarea" rows="3"></textarea>
            </div>

            <div class="form-actions">
              <button type="button" class="cancel-btn" @click="$router.back()">Cancel</button>
              <button type="submit" class="submit-btn" :disabled="loading">
                <span v-if="loading" class="spinner"></span>
                {{ loading ? 'Saving...' : (type === 'expense' ? 'Add Expense' : 'Add Income') }}
              </button>
            </div>
          </form>
        </div>

        <!-- Right: Bill Upload -->
        <div class="upload-card">
          <div class="upload-header">
            <h2 class="upload-title">Upload Bill</h2>
            <p class="upload-subtitle">Attach a receipt or invoice (optional)</p>
          </div>

          <div
            v-if="!billFile"
            class="drop-zone"
            :class="{ dragging: dragOver }"
            @dragover="onDragOver"
            @dragleave="onDragLeave"
            @drop="onDrop"
          >
            <div class="drop-icon">📎</div>
            <p class="drop-text">Drag & drop your bill here</p>
            <p class="drop-hint">or</p>
            <label class="browse-btn">
              Browse Files
              <input type="file" accept="image/*,.pdf" class="file-input" @change="onFileSelect" />
            </label>
            <p class="drop-formats">JPG, PNG, or PDF — max 10 MB</p>
          </div>

          <div v-else class="file-preview">
            <div v-if="billPreview" class="preview-image-wrap">
              <img :src="billPreview" class="preview-image" alt="Bill preview" />
            </div>
            <div v-else class="preview-file">
              <span class="preview-file-icon">📄</span>
            </div>
            <div class="preview-info">
              <p class="preview-name">{{ billFile.name }}</p>
              <p class="preview-size">{{ (billFile.size / 1024).toFixed(1) }} KB</p>
            </div>
            <button class="remove-btn" @click="removeFile">✕</button>
          </div>

          <!-- OCR Processing -->
          <Transition name="ocr-slide">
            <div v-if="ocrProcessing" class="ocr-status">
              <div class="ocr-status-inner">
                <div class="ocr-spinner"></div>
                <div class="ocr-status-text">
                  <span class="ocr-status-title">🔍 Analyzing your bill...</span>
                  <span class="ocr-status-sub">Running OCR + AI extraction</span>
                </div>
              </div>
              <div class="ocr-progress-bar">
                <div class="ocr-progress-fill" :style="{ width: ocrProgress + '%' }"></div>
              </div>
            </div>
          </Transition>

          <!-- OCR Result -->
          <Transition name="ocr-slide">
            <div v-if="ocrResult && !ocrProcessing" class="ocr-result">
              <div class="ocr-result-header">
                <span class="ocr-result-icon">✨</span>
                <span class="ocr-result-title">Bill data extracted</span>
                <button class="ocr-dismiss" @click="dismissOcrResult">✕</button>
              </div>
              <div class="ocr-fields">
                <div v-if="ocrResult.name" class="ocr-field">
                  <span class="ocr-field-label">Name</span>
                  <span class="ocr-field-value">{{ ocrResult.name }}</span>
                  <button class="ocr-field-btn" @click="applyOcrField('name', ocrResult.name)">Use</button>
                </div>
                <div v-if="ocrResult.amount" class="ocr-field">
                  <span class="ocr-field-label">Amount</span>
                  <span class="ocr-field-value">₹{{ ocrResult.amount.toLocaleString() }}</span>
                  <button class="ocr-field-btn" @click="applyOcrField('amount', ocrResult.amount)">Use</button>
                </div>
                <div v-if="ocrResult.date" class="ocr-field">
                  <span class="ocr-field-label">Date</span>
                  <span class="ocr-field-value">{{ formatDate(ocrResult.date) }}</span>
                  <button class="ocr-field-btn" @click="applyOcrField('date', ocrResult.date)">Use</button>
                </div>
                <div v-if="ocrResult.merchant" class="ocr-field">
                  <span class="ocr-field-label">Merchant</span>
                  <span class="ocr-field-value">{{ ocrResult.merchant }}</span>
                </div>
                <div v-if="ocrResult.category" class="ocr-field">
                  <span class="ocr-field-label">Category</span>
                  <span class="ocr-field-value">{{ ocrResult.category }}</span>
                </div>
              </div>
              <!-- Raw OCR text toggle -->
              <details class="ocr-raw-toggle">
                <summary class="ocr-raw-summary">View raw OCR text</summary>
                <pre class="ocr-raw-text">{{ ocrResult.rawText || 'No text detected' }}</pre>
              </details>
            </div>
          </Transition>

          <!-- OCR Error -->
          <Transition name="ocr-slide">
            <div v-if="ocrError && !ocrProcessing" class="ocr-error">
              <span class="ocr-error-icon">⚠️</span>
              <span class="ocr-error-text">{{ ocrError }}</span>
              <button class="ocr-dismiss" @click="ocrError = ''">✕</button>
            </div>
          </Transition>

          <!-- Upload tips -->
          <div class="upload-tips">
            <h3 class="tips-title">💡 Tips</h3>
            <ul class="tips-list">
              <li>Upload bills for record-keeping</li>
              <li>Bills are stored securely in your private storage</li>
              <li>You can delete bills from the Transactions tab</li>
            </ul>
          </div>

          <!-- Uploaded Bills (inside right column) -->
          <div class="bills-section">
          <div class="bills-header">
            <h2 class="bills-title">📄 Uploaded Bills</h2>
            <span class="bills-count" v-if="uploadedBills.length">{{ uploadedBills.length }}</span>
          </div>

          <div v-if="billsLoading" class="bills-loading">
            <span class="spinner"></span>
            <span>Loading bills...</span>
          </div>

          <div v-else-if="uploadedBills.length === 0" class="bills-empty">
            <div class="bills-empty-icon">📋</div>
            <p>No bills uploaded yet</p>
            <p class="bills-empty-hint">Upload a receipt above and it will appear here</p>
          </div>

          <div v-else class="bills-list">
            <div v-for="bill in uploadedBills" :key="bill.id" class="bill-row">
              <div class="bill-thumb" @click="bill.signedUrl && window.open(bill.signedUrl, '_blank')">
                <img
                  v-if="bill.signedUrl && isImage(bill.bill_path)"
                  :src="bill.signedUrl"
                  class="bill-thumb-img"
                  alt="Bill"
                />
                <span v-else class="bill-thumb-icon">📄</span>
              </div>
              <div class="bill-info">
                <span class="bill-name">{{ bill.name }}</span>
                <span class="bill-meta">
                  {{ bill.categories?.icon }} {{ bill.categories?.name }} · {{ formatDate(bill.date) }}
                </span>
              </div>
              <div class="bill-right">
                <span class="bill-amount" :class="{ income: bill.type === 'income' }">
                  {{ bill.type === 'income' ? '+' : '-' }}₹{{ Math.abs(bill.amount).toLocaleString() }}
                </span>
                <div class="bill-actions">
                  <a v-if="bill.signedUrl" :href="bill.signedUrl" target="_blank" class="bill-action-btn view">View</a>
                  <button v-if="bill.signedUrl" class="bill-action-btn download" @click="downloadBill(bill)">⬇</button>
                </div>
              </div>
            </div>
          </div>
        </div>
        </div>
      </div>
    </div>
  </DashboardLayout>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

/* Toast notifications */
.toast {
  position: fixed;
  top: 1.5rem;
  right: 1.5rem;
  z-index: 1000;
  padding: 1rem 1.5rem;
  border-radius: var(--radius);
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  cursor: pointer;
}

.toast.success {
  background: #e8f5e9;
  color: #2e7d32;
  border: 1px solid #a5d6a7;
}

.toast.error {
  background: #fce4ec;
  color: #c62828;
  border: 1px solid #ef9a9a;
}

.toast-enter-active { transition: all 0.3s ease; }
.toast-leave-active { transition: all 0.3s ease; }
.toast-enter-from { opacity: 0; transform: translateY(-1rem); }
.toast-leave-to { opacity: 0; transform: translateY(-1rem); }

.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
  align-items: start;
}

.form-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.type-toggle {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 2rem;
}

.type-btn {
  flex: 1;
  padding: 0.75rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  background: var(--color-bg);
  color: var(--color-text-muted);
  border: 1.5px solid transparent;
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s;
}

.type-btn.active.expense {
  background: rgba(211, 47, 47, 0.06);
  border-color: #d32f2f;
  color: #d32f2f;
}

.type-btn.active.income {
  background: rgba(46, 125, 50, 0.06);
  border-color: #2e7d32;
  color: #2e7d32;
}

.form {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.label {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
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

.textarea {
  resize: vertical;
}

.field-hint {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  font-style: italic;
}

.category-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 0.5rem;
}

.cat-btn {
  padding: 0.625rem;
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: var(--color-bg);
  border: 1.5px solid transparent;
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s;
  text-align: center;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.cat-btn:hover {
  color: var(--color-text);
  background: var(--color-surface);
}

.cat-btn.active {
  border-color: var(--color-graphite);
  color: var(--color-text);
  background: var(--color-surface);
}

/* Subcategory styles */
.subcategory-grid {
  margin-top: 0.25rem;
}

.subcat-btn {
  font-size: 0.75rem !important;
  padding: 0.5rem 0.75rem !important;
}

.skip-btn {
  color: var(--color-text-muted);
  font-style: italic;
  border-style: dashed;
}

.skip-btn.active {
  border-style: solid;
  color: var(--color-text);
}

.subcat-hint {
  font-weight: 400;
  color: var(--color-text-muted);
  font-size: 0.75rem;
}

.subcat-slide-enter-active {
  transition: all 0.25s ease;
}
.subcat-slide-leave-active {
  transition: all 0.2s ease;
}
.subcat-slide-enter-from {
  opacity: 0;
  transform: translateY(-0.5rem);
  max-height: 0;
}
.subcat-slide-enter-to {
  opacity: 1;
  transform: translateY(0);
  max-height: 200px;
}
.subcat-slide-leave-to {
  opacity: 0;
  transform: translateY(-0.5rem);
  max-height: 0;
}

.form-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: flex-end;
  margin-top: 0.5rem;
}

.cancel-btn {
  padding: 0.75rem 1.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: none;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius);
  cursor: pointer;
  transition: border-color 0.2s, color 0.2s;
}

.cancel-btn:hover {
  border-color: var(--color-graphite);
  color: var(--color-text);
}

.submit-btn {
  padding: 0.75rem 1.5rem;
  font-size: 0.875rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border: none;
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s, transform 0.15s;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.submit-btn:hover:not(:disabled) {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
}

.submit-btn:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.spinner {
  width: 14px;
  height: 14px;
  border: 2px solid var(--color-graphite);
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.6s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Upload Card */
.upload-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 2rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.upload-header {
  margin-bottom: 1.5rem;
}

.upload-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.upload-subtitle {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  margin-top: 0.25rem;
}

.drop-zone {
  border: 2px dashed var(--color-border);
  border-radius: var(--radius-lg);
  padding: 3rem 1.5rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
  transition: border-color 0.2s, background 0.2s;
  cursor: pointer;
}

.drop-zone:hover {
  border-color: var(--color-graphite);
  background: rgba(0, 0, 0, 0.015);
}

.drop-zone.dragging {
  border-color: var(--color-accent);
  background: rgba(215, 243, 74, 0.06);
}

.drop-icon {
  font-size: 2rem;
  margin-bottom: 0.25rem;
}

.drop-text {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--color-text);
}

.drop-hint {
  font-size: 0.75rem;
  color: var(--color-text-muted);
}

.browse-btn {
  display: inline-block;
  padding: 0.5rem 1.25rem;
  font-size: 0.8125rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: var(--color-graphite);
  background: var(--color-accent);
  border-radius: var(--radius);
  cursor: pointer;
  transition: background 0.2s;
  margin-top: 0.25rem;
}

.browse-btn:hover {
  background: var(--color-accent-hover);
}

.file-input {
  display: none;
}

.drop-formats {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  margin-top: 0.5rem;
}

/* File Preview */
.file-preview {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--color-bg);
  border-radius: var(--radius);
  border: 1.5px solid var(--color-border);
}

.preview-image-wrap {
  width: 64px;
  height: 64px;
  border-radius: var(--radius);
  overflow: hidden;
  flex-shrink: 0;
  background: var(--color-surface);
}

.preview-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.preview-file {
  width: 64px;
  height: 64px;
  border-radius: var(--radius);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.preview-file-icon {
  font-size: 1.5rem;
}

.preview-info {
  flex: 1;
  min-width: 0;
}

.preview-name {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.preview-size {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.remove-btn {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: none;
  background: var(--color-surface);
  color: var(--color-text-muted);
  font-size: 0.75rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: background 0.15s, color 0.15s;
}

.remove-btn:hover {
  background: rgba(211, 47, 47, 0.1);
  color: #d32f2f;
}

/* Upload Tips */
.upload-tips {
  margin-top: 1.5rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--color-bg);
}

.tips-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
  margin-bottom: 0.75rem;
}

.tips-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.tips-list li {
  font-size: 0.75rem;
  color: var(--color-text-muted);
  padding-left: 1rem;
  position: relative;
}

.tips-list li::before {
  content: '•';
  position: absolute;
  left: 0;
  color: var(--color-accent);
  font-weight: 700;
}

/* Uploaded Bills (inside upload card) */
.bills-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--color-bg);
}

.bills-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.bills-title {
  font-size: 1rem;
  font-weight: 600;
  color: var(--color-text);
}

.bills-count {
  font-size: 0.6875rem;
  font-weight: 600;
  color: var(--color-graphite);
  background: var(--color-bg);
  padding: 0.125rem 0.5rem;
  border-radius: 999px;
}

.bills-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 2rem;
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.bills-empty {
  text-align: center;
  padding: 2.5rem 1rem;
}

.bills-empty-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.bills-empty p {
  font-size: 0.875rem;
  color: var(--color-text-muted);
}

.bills-empty-hint {
  font-size: 0.75rem !important;
  margin-top: 0.25rem;
  color: var(--color-grey) !important;
}

.bills-list {
  display: flex;
  flex-direction: column;
}

.bill-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--color-bg);
}

.bill-row:last-child {
  border-bottom: none;
}

.bill-thumb {
  width: 44px;
  height: 44px;
  border-radius: var(--radius);
  overflow: hidden;
  flex-shrink: 0;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
}

.bill-thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.bill-thumb-icon {
  font-size: 1.25rem;
}

.bill-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.bill-name {
  font-size: 0.8125rem;
  font-weight: 500;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.bill-meta {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.bill-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.25rem;
  flex-shrink: 0;
}

.bill-amount {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
}

.bill-amount.income {
  color: #2e7d32;
}

.bill-actions {
  display: flex;
  align-items: center;
  gap: 0.375rem;
}

.bill-action-btn {
  font-size: 0.6875rem;
  font-weight: 500;
  font-family: var(--font-sans);
  cursor: pointer;
  border: none;
  background: none;
  padding: 0;
  transition: color 0.15s;
}

.bill-action-btn.view {
  color: var(--color-graphite);
  text-decoration: underline;
}

.bill-action-btn.view:hover {
  color: var(--color-accent);
}

.bill-action-btn.download {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
  padding: 0.125rem 0.25rem;
  border-radius: var(--radius);
}

.bill-action-btn.download:hover {
  color: var(--color-accent);
  background: var(--color-bg);
}

/* OCR Status */
.ocr-status {
  margin-top: 1rem;
  padding: 1rem;
  background: var(--color-bg);
  border-radius: var(--radius);
  border: 1.5px solid var(--color-border);
}

.ocr-status-inner {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.ocr-spinner {
  width: 20px;
  height: 20px;
  border: 2.5px solid var(--color-border);
  border-top-color: var(--color-accent);
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
  flex-shrink: 0;
}

.ocr-status-text {
  display: flex;
  flex-direction: column;
}

.ocr-status-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: var(--color-text);
}

.ocr-status-sub {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  margin-top: 0.125rem;
}

.ocr-progress-bar {
  height: 3px;
  background: var(--color-border);
  border-radius: 999px;
  overflow: hidden;
}

.ocr-progress-fill {
  height: 100%;
  background: var(--color-accent);
  border-radius: 999px;
  transition: width 0.3s ease;
}

/* OCR Result */
.ocr-result {
  margin-top: 1rem;
  padding: 1rem;
  background: rgba(46, 125, 50, 0.04);
  border-radius: var(--radius);
  border: 1.5px solid rgba(46, 125, 50, 0.2);
}

.ocr-result-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.75rem;
}

.ocr-result-icon {
  font-size: 1rem;
}

.ocr-result-title {
  font-size: 0.8125rem;
  font-weight: 600;
  color: #2e7d32;
  flex: 1;
}

.ocr-dismiss {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: transparent;
  color: var(--color-text-muted);
  font-size: 0.625rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.15s;
}

.ocr-dismiss:hover {
  background: rgba(0, 0, 0, 0.06);
}

.ocr-fields {
  display: flex;
  flex-direction: column;
  gap: 0.375rem;
}

.ocr-field {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.375rem 0.5rem;
  background: var(--color-surface);
  border-radius: var(--radius);
}

.ocr-field-label {
  font-size: 0.6875rem;
  font-weight: 500;
  color: var(--color-text-muted);
  min-width: 60px;
}

.ocr-field-value {
  font-size: 0.8125rem;
  color: var(--color-text);
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ocr-field-btn {
  font-size: 0.625rem;
  font-weight: 600;
  font-family: var(--font-sans);
  color: #2e7d32;
  background: rgba(46, 125, 50, 0.08);
  border: none;
  border-radius: var(--radius);
  padding: 0.25rem 0.5rem;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s;
}

.ocr-field-btn:hover {
  background: rgba(46, 125, 50, 0.15);
}

/* OCR Raw Text */
.ocr-raw-toggle {
  margin-top: 0.75rem;
}

.ocr-raw-summary {
  font-size: 0.6875rem;
  color: var(--color-text-muted);
  cursor: pointer;
  user-select: none;
}

.ocr-raw-summary:hover {
  color: var(--color-text);
}

.ocr-raw-text {
  margin-top: 0.5rem;
  padding: 0.75rem;
  background: var(--color-surface);
  border-radius: var(--radius);
  font-size: 0.6875rem;
  font-family: monospace;
  color: var(--color-text-muted);
  max-height: 150px;
  overflow-y: auto;
  white-space: pre-wrap;
  word-break: break-word;
  line-height: 1.5;
  border: 1px solid var(--color-border);
}

/* OCR Error */
.ocr-error {
  margin-top: 1rem;
  padding: 0.75rem 1rem;
  background: rgba(211, 47, 47, 0.04);
  border-radius: var(--radius);
  border: 1.5px solid rgba(211, 47, 47, 0.2);
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.ocr-error-icon {
  font-size: 0.875rem;
}

.ocr-error-text {
  font-size: 0.8125rem;
  color: #c62828;
  flex: 1;
}

/* OCR Transitions */
.ocr-slide-enter-active {
  transition: all 0.25s ease;
}
.ocr-slide-leave-active {
  transition: all 0.2s ease;
}
.ocr-slide-enter-from {
  opacity: 0;
  transform: translateY(-0.5rem);
  max-height: 0;
  overflow: hidden;
}
.ocr-slide-enter-to {
  opacity: 1;
  transform: translateY(0);
  max-height: 300px;
  overflow: hidden;
}
.ocr-slide-leave-to {
  opacity: 0;
  transform: translateY(-0.5rem);
  max-height: 0;
  overflow: hidden;
}
</style>
