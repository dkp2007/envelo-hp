<script setup>
import { ref } from 'vue'
import DashboardLayout from '@/layouts/DashboardLayout.vue'

const type = ref('expense')
const name = ref('')
const amount = ref('')
const category = ref('')
const date = ref(new Date().toISOString().split('T')[0])
const notes = ref('')

const billFile = ref(null)
const billPreview = ref(null)
const dragOver = ref(false)

const expenseCategories = [
  { value: 'rent', label: '🏠 Rent' },
  { value: 'food', label: '🍔 Food' },
  { value: 'fun', label: '🎮 Fun' },
  { value: 'savings', label: '💰 Savings' },
]

const incomeCategories = [
  { value: 'salary', label: '💼 Salary' },
  { value: 'freelance', label: '💻 Freelance' },
  { value: 'other', label: '📦 Other' },
]

const categories = ref(expenseCategories)

function switchType(t) {
  type.value = t
  category.value = ''
  categories.value = t === 'expense' ? expenseCategories : incomeCategories
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

function handleFile(file) {
  billFile.value = file
  if (file.type.startsWith('image/')) {
    billPreview.value = URL.createObjectURL(file)
  } else {
    billPreview.value = null
  }
}

function removeFile() {
  billFile.value = null
  billPreview.value = null
}
</script>

<template>
  <DashboardLayout>
    <div class="page">
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

          <form class="form" @submit.prevent>
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
                  v-for="cat in categories"
                  :key="cat.value"
                  type="button"
                  class="cat-btn"
                  :class="{ active: category === cat.value }"
                  @click="category = cat.value"
                >
                  {{ cat.label }}
                </button>
              </div>
            </div>

            <div class="field">
              <label class="label">Date</label>
              <input v-model="date" type="date" class="input" />
            </div>

            <div class="field">
              <label class="label">Notes (optional)</label>
              <textarea v-model="notes" placeholder="Any additional details..." class="input textarea" rows="3"></textarea>
            </div>

            <div class="form-actions">
              <button type="button" class="cancel-btn">Cancel</button>
              <button type="submit" class="submit-btn">
                {{ type === 'expense' ? 'Add Expense' : 'Add Income' }}
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

.category-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
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
}

.cat-btn:hover {
  color: var(--color-text);
}

.cat-btn.active {
  border-color: var(--color-graphite);
  color: var(--color-text);
  background: var(--color-surface);
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
}

.submit-btn:hover {
  background: var(--color-accent-hover);
  transform: translateY(-1px);
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
</style>
