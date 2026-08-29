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
      model: 'openai/gpt-oss-20b',
      messages: [
        {
          role: 'system',
          content: `You are an expert Indian receipt/bill parser. Extract structured data from OCR text of receipts, invoices, and bills.

CRITICAL RULES:
1. IGNORE all noise: page numbers, QR codes, barcode text, 'Page X of Y', 'Thank you', 'www.', email addresses, phone numbers, GSTIN numbers
2. The AMOUNT must be a real positive number greater than 0. Look for these keywords in order of priority:
   - GRAND TOTAL, TOTAL AMOUNT, NET AMOUNT, AMOUNT PAYABLE, BILL TOTAL
   - Then: SUB TOTAL, SUBTOTAL, TOTAL
   - Then: CASH, CARD, UPI, PAYMENT amounts
   - NEVER return 0. If you cannot find any amount, return null
3. The NAME should be a SHORT description of what was purchased (max 40 chars). Examples: 'Big Bazaar Groceries', 'Swiggy Order', 'PVR Tickets', 'Amazon Purchase'. NEVER use invoice numbers, 'Tax Invoice', or page headers.
4. The MERCHANT is the store/company name from the TOP of the receipt. Usually the first meaningful line after noise. Examples: 'Big Bazaar', 'DMart', 'Reliance Fresh', 'Akash Enterprises'. NEVER return garbage text.
5. The DATE should be the bill/invoice date in YYYY-MM-DD format. Common Indian formats: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD MMM YYYY. Use null if not found.
6. The CATEGORY is inferred from items: groceries/food items → Food, clothes/shoes → Fun, electronics/gadgets → Fun, rent/housing → Rent, medicines → Rent, travel → Fun. One of: Rent, Food, Fun, Savings, Other.

Return ONLY a valid JSON object (no markdown, no code fences, no explanation):
{"name":"Big Bazaar Groceries","amount":1234,"date":"2025-08-29","category":"Food","merchant":"Big Bazaar"}`
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

  // Find amount — try multiple strategies
  let amount = null
  const amountPatterns = [
    // Priority 1: Total keywords (most reliable)
    /(?:grand\s*total|total\s*amount|net\s*amount|amount\s*payable|bill\s*total|total\s*due)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
    // Priority 2: Just 'total'
    /(?:total|sub\s*total|subtotal)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
    // Priority 3: Currency symbol before number
    /(?:₹|Rs\.?|INR)\s*([\d,]+\.?\d*)/i,
    // Priority 4: Number before currency
    /([\d,]+\.?\d*)\s*(?:₹|Rs|INR)/i,
    // Priority 5: Payment method amounts
    /(?:cash|card|upi|payment)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i,
  ]
  for (const pat of amountPatterns) {
    const matches = text.matchAll(new RegExp(pat.source, 'gi'))
    for (const m of matches) {
      const val = parseFloat(m[1].replace(/,/g, ''))
      if (val > 0 && val < 10000000) {
        amount = val
        break
      }
    }
    if (amount) break
  }

  // Find date
  let date = null
  const datePatterns = [
    /(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})/,
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

  // Filter noise lines for name/merchant
  const noisePattern = /page|thank|welcome|www\.|invoice\s*no|bill\s*no|gst|tax\s*inv|qr|barcode|\d{10,}/i
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2 && !l.match(/^[\d\s\-/:.]+$/) && !noisePattern.test(l))
  const name = lines[0]?.substring(0, 60) || null
  const merchant = lines.find(l => l.length > 3 && !l.match(/total|amount|date|invoice|bill|qty|rate|item/i))?.substring(0, 40) || null

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
