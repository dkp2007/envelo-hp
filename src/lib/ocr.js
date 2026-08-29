import { createWorker } from 'tesseract.js'
import { groq } from './groq.js'

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
 */
export async function parseBillWithAI(ocrText) {
  if (!ocrText || ocrText.trim().length < 5) {
    return parseBillFallback(ocrText || '')
  }

  try {
    const completion = await groq.chat.completions.create({
      model: 'openai/gpt-oss-20b',
      messages: [
        {
          role: 'system',
          content: `You are an Indian receipt parser. Given OCR text from a receipt/bill, extract structured data.

RULES:
1. AMOUNT: Find the final amount the customer paid. Look for GRAND TOTAL, TOTAL, NET AMOUNT, AMOUNT PAYABLE in that order. The amount MUST be > 0. NEVER return 0. If you cannot find a total, sum all item prices.
2. NAME: Short purchase description (max 40 chars). Example: "Mechanical Keyboard", "Grocery Shopping". NOT invoice numbers or headers.
3. MERCHANT: Store/company name from top of receipt.
4. DATE: Bill date in YYYY-MM-DD format.
5. CATEGORY: One of: Rent, Food, Fun, Savings, Other. Map items to categories: electronics/gadgets → Fun, food/groceries → Food, rent/housing → Rent, medicines → Rent, travel → Fun.

Return ONLY valid JSON, no markdown fences:
{"name":"item name","amount":6015.64,"date":"2026-08-30","category":"Fun","merchant":"Store Name"}`
        },
        {
          role: 'user',
          content: `OCR text:\n${ocrText.substring(0, 3000)}`
        }
      ],
      temperature: 0.1,
      max_tokens: 300,
    })

    const content = completion.choices[0]?.message?.content || ''

    // Extract JSON from the response
    let jsonStr = content
    const fenceMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/)
    if (fenceMatch) {
      jsonStr = fenceMatch[1]
    }
    const jsonMatch = jsonStr.match(/\{[\s\S]*\}/)
    if (!jsonMatch) throw new Error('No JSON in AI response')

    const parsed = JSON.parse(jsonMatch[0])

    // Validate amount — if 0 or null, try regex fallback
    let amount = typeof parsed.amount === 'number' ? parsed.amount : null
    if (!amount || amount <= 0) {
      const fallback = parseBillFallback(ocrText)
      amount = fallback.amount
    }

    return {
      name: parsed.name || null,
      amount: amount,
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
 * Robust fallback parser using regex.
 * Handles Tesseract quirks: extra spaces around ₹, line breaks in amounts, etc.
 */
function parseBillFallback(text) {
  if (!text) return { name: null, amount: null, date: null, category: null, merchant: null }

  // Normalize text: collapse multiple spaces, handle line breaks around ₹
  const normalized = text
    .replace(/\r/g, '')
    .replace(/₹\s*\n\s*/g, '₹ ')     // ₹ on one line, number on next
    .replace(/\n\s*₹/g, ' ₹')         // number on one line, ₹ on next
    .replace(/[ \t]{2,}/g, ' ')        // collapse whitespace
    .replace(/[A-Z]\s+[A-Z]/g, m => m.replace(/\s/g, '')) // fix spaced caps like "G R A N D" → "GRAND"

  let amount = null

  // Priority 1: GRAND TOTAL / TOTAL AMOUNT / NET AMOUNT
  const grandPatterns = [
    /grand\s*total\s*[:\-]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
    /(?:total|net\s*amount|amount\s*payable|bill\s*total|total\s*due|total\s*amount)\s*[:\-]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
  ]

  for (const pat of grandPatterns) {
    const m = normalized.match(pat)
    if (m) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000) { amount = val; break }
    }
  }

  // Priority 2: ₹ symbol followed by a number (on same line)
  if (!amount) {
    const allRupee = [...normalized.matchAll(/(?:₹|Rs\.?|INR)\s*([\d,]+\.?\d{1,2})\b/gi)]
    // Pick the largest amount after ₹ (likely the total, not subtotals)
    for (const m of allRupee) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000 && (!amount || val > amount)) {
        amount = val
      }
    }
  }

  // Priority 3: Number followed by ₹
  if (!amount) {
    const numBeforeRupee = [...normalized.matchAll(/([\d,]+\.?\d{1,2})\s*(?:₹|Rs|INR)\b/gi)]
    for (const m of numBeforeRupee) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000 && (!amount || val > amount)) {
        amount = val
      }
    }
  }

  // Priority 4: SUBTOTAL line (if nothing else found)
  if (!amount) {
    const subMatch = normalized.match(/sub\s*total\s*[:\-]?\s*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i)
    if (subMatch) {
      amount = parseFloat(subMatch[1].replace(/,/g, ''))
    }
  }

  // Find date
  let date = null
  // Format: DD MMM YYYY (e.g., "AUG 30, 2026" or "30 Aug 2026")
  const monthNames = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec'
  const datePatterns = [
    new RegExp(`(\\d{1,2})\\s*(${monthNames})\\w*\\s*[:,]?\\s*(\\d{4})`, 'i'),
    new RegExp(`(${monthNames})\\w*\\s+(\\d{1,2})\\s*[:,]?\\s*(\\d{4})`, 'i'),
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

  // Find name and merchant
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2)
  const noisePattern = /page|thank|welcome|www\.|invoice|bill\s*no|gst|tax\s*inv|qr|barcode|\d{10,}|receipt|retain|warranty|return/i
  const cleanLines = lines.filter(l => !noisePattern.test(l) && !l.match(/^[\d\s\-/:.₹]+$/))

  const name = cleanLines.find(l =>
    l.length > 3 && l.length < 60 &&
    !l.match(/total|amount|date|qty|rate|item|subtotal|grand|payment|status|cashier|phone|gstin/i)
  )?.substring(0, 40) || null

  const merchant = cleanLines.find(l =>
    l.length > 3 && l.length < 40 &&
    l.match(/^[A-Z]/) &&
    !l.match(/total|amount|date|subtotal|grand|payment|status|cashier|receipt|item|description|qty|rate|phone|gstin/i)
  )?.substring(0, 40) || null

  // Infer category from text
  let category = null
  const lowerText = text.toLowerCase()
  if (lowerText.match(/grocery|food|restaurant|cafe|swiggy|zomato|tea|coffee|milk|rice|wheat|snack|meal|lunch|dinner|breakfast|fruit|vegetable|meat|chicken|fish/)) {
    category = 'Food'
  } else if (lowerText.match(/electronic|gadget|keyboard|mouse|laptop|phone|headphone|speaker|cable|charger|screen|monitor|tv|camera|gaming|software/)) {
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
