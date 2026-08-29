import { createWorker } from 'tesseract.js'
import { groq } from './groq.js'

/**
 * Extract text from an image using Tesseract.js OCR.
 * @param {File|string} source - File object or image URL
 * @returns {Promise<string>} recognized text
 */
export async function extractTextFromImage(source) {
  const worker = await createWorker('eng')
  try {
    // Tesseract can accept a File or a URL
    const input = source instanceof File ? source : source
    const { data: { text } } = await worker.recognize(input)
    return text
  } finally {
    await worker.terminate()
  }
}

/**
 * Parse OCR text using Groq AI to extract structured bill data.
 * @param {string} ocrText - raw text from OCR
 * @returns {Promise<{ name: string, amount: number|null, date: string|null, category: string|null, merchant: string|null }>}
 */
export async function parseBillWithAI(ocrText) {
  try {
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: `You are a bill/receipt parser. Extract structured data from Indian receipts and bills.

Return ONLY a JSON object with these fields (no markdown, no code fences):
{
  "name": "short description of the transaction (e.g. 'Big Bazaar Groceries')",
  "amount": 1234.56 (number, no currency symbol),
  "date": "2025-08-29" (YYYY-MM-DD format, null if not found),
  "category": "Food" (one of: Rent, Food, Fun, Savings, Salary, Freelance, Other),
  "merchant": "store/vendor name" (null if not found)
}

Rules:
- amount should be a positive number (no minus sign)
- If you see multiple amounts, pick the TOTAL/FINAL amount
- category should match one of the listed categories
- date should be the transaction/purchase date, not the due date
- If you cannot determine a field, use null
- Extract the merchant/store name from the header or top of the bill`
        },
        {
          role: 'user',
          content: `Here is the OCR text from a bill/receipt:\n\n${ocrText}`
        }
      ],
      temperature: 0.1,
      max_tokens: 300,
    })

    const content = completion.choices[0]?.message?.content || ''

    // Try to parse JSON from the response (handle markdown code fences)
    const jsonMatch = content.match(/\{[\s\S]*\}/)
    if (!jsonMatch) throw new Error('No JSON in AI response')

    const parsed = JSON.parse(jsonMatch[0])
    return {
      name: parsed.name || null,
      amount: parsed.amount || null,
      date: parsed.date || null,
      category: parsed.category || null,
      merchant: parsed.merchant || null,
    }
  } catch (err) {
    console.error('AI bill parsing failed:', err)
    // Fallback: try basic regex extraction from OCR text
    return parseBillFallback(ocrText)
  }
}

/**
 * Fallback parser using regex — works when AI is unavailable.
 * Extracts amount and basic info from OCR text.
 */
function parseBillFallback(text) {
  // Try to find amount (₹ followed by digits)
  let amount = null
  const amountMatch = text.match(/(?:₹|Rs\.?|INR)\s*([\d,]+\.?\d*)/i)
    || text.match(/(?:total|amount|grand total|balance due)[:\s]*(?:₹|Rs\.?|INR)?\s*([\d,]+\.?\d*)/i)
  if (amountMatch) {
    amount = parseFloat(amountMatch[1].replace(/,/g, ''))
  }

  // Try to find date
  let date = null
  const dateMatch = text.match(/(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})/)
    || text.match(/(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+(\d{2,4})/i)
  if (dateMatch) {
    try {
      const d = new Date(dateMatch[0])
      if (!isNaN(d.getTime())) {
        date = d.toISOString().split('T')[0]
      }
    } catch { /* ignore */ }
  }

  // First non-empty line as merchant/name
  const lines = text.split('\n').map(l => l.trim()).filter(l => l.length > 2)
  const name = lines[0]?.substring(0, 60) || 'Bill Upload'

  return { name, amount, date, category: null, merchant: null }
}

/**
 * Full pipeline: OCR image → AI parse → structured data.
 * @param {File} file - image file
 * @param {Function} onProgress - optional progress callback (0-100)
 * @returns {Promise<{ name, amount, date, category, merchant, rawText }>}
 */
export async function processBill(file, onProgress) {
  if (onProgress) onProgress(10)

  // Step 1: OCR
  const rawText = await extractTextFromImage(file)
  if (onProgress) onProgress(60)

  // Step 2: AI parse
  const parsed = await parseBillWithAI(rawText)
  if (onProgress) onProgress(100)

  return { ...parsed, rawText }
}
