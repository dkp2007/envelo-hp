import { createWorker } from 'tesseract.js'
import { groq } from './groq.js'

/**
 * Extract text from an image using Tesseract.js OCR.
 * @param {File} file - image file
 * @param {Function} onProgress - progress callback (0-100)
 * @returns {Promise<string>} recognized text
 */
export async function extractTextFromImage(file, onProgress) {
  let worker = null
  try {
    if (onProgress) onProgress(15)

    // Create worker with eng language
    worker = await createWorker('eng', 1, {
      logger: (m) => {
        if (m.status === 'recognizing text' && onProgress) {
          // Map Tesseract progress (0-1) to our range (20-55)
          onProgress(20 + Math.round(m.progress * 35))
        }
      },
    })

    if (onProgress) onProgress(20)

    // Recognize the image
    const { data: { text } } = await worker.recognize(file)

    if (onProgress) onProgress(55)

    return text || ''
  } catch (err) {
    console.error('Tesseract OCR failed:', err)
    throw new Error(`OCR failed: ${err.message || 'Could not read image text'}`)
  } finally {
    if (worker) {
      try { await worker.terminate() } catch { /* ignore */ }
    }
  }
}

/**
 * Parse OCR text using Groq AI to extract structured bill data.
 * @param {string} ocrText - raw text from OCR
 * @returns {Promise<{ name: string, amount: number|null, date: string|null, category: string|null, merchant: string|null }>}
 */
export async function parseBillWithAI(ocrText) {
  if (!ocrText || ocrText.trim().length < 5) {
    return parseBillFallback(ocrText || '')
  }

  try {
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: `You are a bill/receipt parser. Extract structured data from Indian receipts and bills.

Return ONLY a JSON object with these fields (no markdown, no code fences, no extra text):
{
  "name": "short description of the transaction (e.g. 'Big Bazaar Groceries')",
  "amount": 1234.56,
  "date": "2025-08-29",
  "category": "Food",
  "merchant": "store/vendor name"
}

Rules:
- amount is a positive number (no currency symbol), use null if not found
- If you see multiple amounts, pick the TOTAL/FINAL amount
- category must be one of: Rent, Food, Fun, Savings, Salary, Freelance, Other
- date is YYYY-MM-DD format, use null if not found
- merchant is the store/vendor name from the header, use null if not found
- name is a short human-readable description of what was purchased`
        },
        {
          role: 'user',
          content: `Extract bill data from this OCR text:\n\n${ocrText.substring(0, 3000)}`
        }
      ],
      temperature: 0.1,
      max_tokens: 300,
    })

    const content = completion.choices[0]?.message?.content || ''

    // Extract JSON from the response (handle markdown code fences)
    let jsonStr = content
    const fenceMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/)
    if (fenceMatch) {
      jsonStr = fenceMatch[1]
    }
    const jsonMatch = jsonStr.match(/\{[\s\S]*\}/)
    if (!jsonMatch) throw new Error('No JSON in AI response')

    const parsed = JSON.parse(jsonMatch[0])
    return {
      name: parsed.name || null,
      amount: typeof parsed.amount === 'number' ? parsed.amount : null,
      date: parsed.date || null,
      category: parsed.category || null,
      merchant: parsed.merchant || null,
    }
  } catch (err) {
    console.warn('AI bill parsing failed, using regex fallback:', err.message)
    return parseBillFallback(ocrText)
  }
}

/**
 * Fallback parser using regex when AI is unavailable.
 */
function parseBillFallback(text) {
  if (!text) return { name: null, amount: null, date: null, category: null, merchant: null }

  // Find amount: ₹, Rs, INR, or keywords like Total, Amount
  let amount = null
  const amountPatterns = [
    /(?:₹|Rs\.?|INR)\s*([\d,]+\.?\d*)/i,
    /(?:total|grand total|amount due|balance due|net amount)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
    /([\d,]+\.?\d*)\s*(?:₹|Rs|INR)/i,
  ]
  for (const pat of amountPatterns) {
    const m = text.match(pat)
    if (m) {
      amount = parseFloat(m[1].replace(/,/g, ''))
      if (amount > 0 && amount < 10000000) break
      amount = null
    }
  }

  // Find date
  let date = null
  const datePatterns = [
    /(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})/,
    /(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{2,4})/i,
  ]
  for (const pat of datePatterns) {
    const m = text.match(pat)
    if (m) {
      try {
        const d = new Date(m[0])
        if (!isNaN(d.getTime()) && d.getFullYear() > 2000) {
          date = d.toISOString().split('T')[0]
          break
        }
      } catch { /* ignore */ }
    }
  }

  // First meaningful line as name/merchant
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2 && !l.match(/^[\d\s\-/:.]+$/))
  const name = lines[0]?.substring(0, 60) || null
  const merchant = lines.find(l => l.length > 3 && !l.match(/total|amount|date|invoice|bill/i))?.substring(0, 40) || null

  return { name, amount, date, category: null, merchant }
}

/**
 * Full pipeline: OCR image → AI parse → structured data.
 * @param {File} file - image file
 * @param {Function} onProgress - optional progress callback (0-100)
 * @returns {Promise<{ name, amount, date, category, merchant, rawText }>}
 */
export async function processBill(file, onProgress) {
  if (onProgress) onProgress(5)

  // Validate file
  if (!file || !file.type.startsWith('image/')) {
    throw new Error('Please upload an image file (JPG, PNG, or WebP)')
  }

  // Step 1: OCR
  const rawText = await extractTextFromImage(file, onProgress)
  if (onProgress) onProgress(60)

  // Step 2: AI parse (with fallback)
  const parsed = await parseBillWithAI(rawText)
  if (onProgress) onProgress(100)

  return { ...parsed, rawText }
}
