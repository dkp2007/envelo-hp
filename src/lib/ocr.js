import { createWorker } from 'tesseract.js'
import { parseWithAI } from './ai.js'

/**
 * Extract text from an image using Tesseract.js OCR.
 */
export async function extractTextFromImage(file, onProgress) {
  let worker = null
  try {
    if (onProgress) onProgress(15)

    worker = await createWorker('eng', 1, {
      logger: (m) => {
        if (m.status === 'recognizing text' && onProgress) {
          onProgress(20 + Math.round(m.progress * 35))
        }
      },
    })

    if (onProgress) onProgress(20)
    const { data: { text } } = await worker.recognize(file)
    if (onProgress) onProgress(55)

    console.log('[OCR] Raw text extracted:', text?.substring(0, 500))
    return text || ''
  } catch (err) {
    console.error('[OCR] Tesseract failed:', err)
    throw new Error(`OCR failed: ${err.message || 'Could not read image text'}`)
  } finally {
    if (worker) {
      try { await worker.terminate() } catch { /* ignore */ }
    }
  }
}

/**
 * Parse OCR text → structured bill data.
 * Tries AI first (Groq → HuggingFace), then regex fallback.
 */
export async function parseBillWithAI(ocrText) {
  if (!ocrText || ocrText.trim().length < 5) {
    return parseBillFallback(ocrText || '')
  }

  // Try AI providers
  try {
    const aiResult = await parseWithAI(ocrText)
    if (aiResult && aiResult.amount > 0) {
      console.log('[OCR] AI result:', aiResult)
      return aiResult
    }
  } catch (err) {
    console.warn('[OCR] AI parsing failed:', err.message)
  }

  // Fallback to regex
  console.log('[OCR] Using regex fallback')
  return parseBillFallback(ocrText)
}

/**
 * Brutally robust regex fallback.
 * Handles: extra spaces around ₹, line breaks, garbled OCR, no ₹ symbol at all.
 */
function parseBillFallback(text) {
  if (!text) return { name: null, amount: null, date: null, category: null, merchant: null }

  // Normalize aggressively
  const normalized = text
    .replace(/\r/g, '')
    .replace(/₹\s*\n\s*/g, '₹ ')       // ₹ on one line, number next line
    .replace(/\n\s*₹/g, ' ₹')           // number on one line, ₹ next line
    .replace(/\s+₹\s+/g, ' ₹ ')         // normalize ₹ spacing
    .replace(/[ \t]{2,}/g, ' ')          // collapse whitespace
    .replace(/(\d)\s+(\d{3})/g, '$1$2') // fix split thousands like "6 015" → "6015"

  let amount = null

  // ── AMOUNT EXTRACTION ──

  // Strategy 1: "GRAND TOTAL" / "TOTAL" followed by any number
  const totalPatterns = [
    /(?:grand\s*total|g\s*total)\s*[:\-=]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d{0,2})\b/i,
    /(?:total|net\s*amount|amount\s*payable|bill\s*total|total\s*due|total\s*amount|balance\s*due)\s*[:\-=]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d{0,2})\b/i,
    /(?:sub\s*total|subtotal)\s*[:\-=]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d{0,2})\b/i,
  ]

  for (const pat of totalPatterns) {
    const matches = [...normalized.matchAll(new RegExp(pat.source, 'gi'))]
    for (const m of matches) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000) {
        amount = val
        break
      }
    }
    if (amount) break
  }

  // Strategy 2: Find ALL numbers with ₹ nearby, pick the largest (total > subtotal)
  if (!amount) {
    const rupeeAmounts = [...normalized.matchAll(/(?:₹|Rs\.?|INR)\s*([\d,]+\.?\d{0,2})\b/gi)]
    for (const m of rupeeAmounts) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000 && (!amount || val > amount)) {
        amount = val
      }
    }
  }

  // Strategy 3: Number followed by ₹
  if (!amount) {
    const numAmounts = [...normalized.matchAll(/([\d,]+\.?\d{0,2})\s*(?:₹|Rs\b|INR)/gi)]
    for (const m of numAmounts) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000 && (!amount || val > amount)) {
        amount = val
      }
    }
  }

  // Strategy 4: Find "TOTAL" or "GRAND" line and grab the LAST number on that line
  if (!amount) {
    const lines = normalized.split('\n')
    for (const line of lines) {
      if (/total|grand|payable|balance|due/i.test(line)) {
        const nums = [...line.matchAll(/([\d,]+\.?\d{0,2})/g)]
        // Pick the last/largest number on the TOTAL line
        for (let i = nums.length - 1; i >= 0; i--) {
          const val = parseFloat(nums[i][1].replace(/,/g, ''))
          if (val > 10 && val < 10000000) {
            amount = val
            break
          }
        }
        if (amount) break
      }
    }
  }

  // Strategy 5: ANY line with a large-ish number (last resort)
  if (!amount) {
    const allNums = [...normalized.matchAll(/([\d,]+\.\d{2})\b/g)]
    for (const m of allNums) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 50 && val < 10000000 && (!amount || val > amount)) {
        amount = val
      }
    }
  }

  console.log('[OCR] Regex amount:', amount)

  // ── DATE ──
  let date = null
  const monthNames = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
  const datePatterns = [
    new RegExp(`(\\d{1,2})\\s*(${monthNames})\\w*\\s*[,:]?\\s*(\\d{4})`, 'i'),
    new RegExp(`(${monthNames})\\w*\\s+(\\d{1,2})\\s*[,:]?\\s*(\\d{4})`, 'i'),
    /(\\d{1,2})[/.-](\\d{1,2})[/.-](\\d{2,4})/,
  ]
  for (const pat of datePatterns) {
    const m = normalized.match(pat)
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

  // ── NAME & MERCHANT ──
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2)
  const noisePattern = /page|thank|welcome|www\.|invoice|bill\s*no|gst|tax\s*inv|qr|barcode|\d{10,}|receipt|retain|warranty|return|status|paid|cashier|transaction/i
  const cleanLines = lines.filter(l => !noisePattern.test(l) && !l.match(/^[\d\s\-/:.₹]+$/))

  // Name: first meaningful short line (not an address)
  const name = cleanLines.find(l =>
    l.length > 3 && l.length < 60 &&
    !l.match(/total|amount|date|qty|rate|item|subtotal|grand|payment|status|cashier|phone|gstin|lane|town|road|street|nagar|colony|pin|\d{6}/i)
  )?.substring(0, 40) || null

  // Merchant: first ALL-CAPS or title-case line that's a store name
  const merchant = cleanLines.find(l =>
    l.length > 3 && l.length < 40 &&
    (l === l.toUpperCase() || l.match(/^[A-Z][a-z]/)) &&
    !l.match(/total|amount|date|subtotal|grand|payment|status|cashier|receipt|item|description|qty|rate|phone|gstin|lane|town|road|street|nagar|\d{6}/i)
  )?.substring(0, 40) || null

  // ── CATEGORY ──
  let category = null
  const lowerText = text.toLowerCase()
  if (lowerText.match(/grocery|food|restaurant|cafe|swiggy|zomato|tea|coffee|milk|rice|wheat|snack|meal|lunch|dinner|breakfast|fruit|vegetable|meat|chicken|fish/)) {
    category = 'Food'
  } else if (lowerText.match(/electronic|gadget|keyboard|mouse|laptop|phone|headphone|speaker|cable|charger|screen|monitor|tv|camera|gaming|software|microfiber|hdmi/i)) {
    category = 'Fun'
  } else if (lowerText.match(/rent|house|apartment|maintenance|electricity|water|gas|internet|wifi|broadband/)) {
    category = 'Rent'
  } else if (lowerText.match(/medicine|pharmacy|hospital|doctor|health|medical|insurance/)) {
    category = 'Rent'
  } else if (lowerText.match(/travel|fuel|petrol|diesel|uber|ola|train|bus|flight|hotel|taxi/)) {
    category = 'Fun'
  }

  return { name, amount, date, category, merchant }
}

/**
 * Full pipeline: OCR image → AI parse → structured data.
 */
export async function processBill(file, onProgress) {
  if (onProgress) onProgress(5)

  if (!file || !file.type.startsWith('image/')) {
    throw new Error('Please upload an image file (JPG, PNG, or WebP)')
  }

  const rawText = await extractTextFromImage(file, onProgress)
  if (onProgress) onProgress(60)

  const parsed = await parseBillWithAI(rawText)
  if (onProgress) onProgress(100)

  return { ...parsed, rawText }
}
