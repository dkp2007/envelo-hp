import Groq from 'groq-sdk'

const GROQ_KEY = import.meta.env.VITE_GROQ_API_KEY
const HF_KEY = import.meta.env.VITE_HF_API_KEY

const groq = GROQ_KEY ? new Groq({ dangerouslyAllowBrowser: true, apiKey: GROQ_KEY }) : null

/**
 * Parse receipt text using AI — tries Groq first, then Hugging Face.
 * Both return the same structured JSON.
 */
export async function parseWithAI(ocrText) {
  const prompt = {
    system: `You are an Indian receipt parser. Given OCR text from a receipt/bill, extract structured data.

RULES:
1. AMOUNT: Find the final amount the customer paid. Look for GRAND TOTAL, TOTAL, NET AMOUNT, AMOUNT PAYABLE in that order. The amount MUST be > 0. NEVER return 0. If no total found, sum all item prices.
2. NAME: Short purchase description (max 40 chars). Example: "Mechanical Keyboard", "Grocery Shopping". NOT invoice numbers or headers.
3. MERCHANT: Store/company name from TOP of receipt. Usually the first bold/caps line.
4. DATE: Bill date in YYYY-MM-DD format.
5. CATEGORY: One of: Rent, Food, Fun, Savings, Other. electronics/gadgets → Fun, food/groceries → Food, rent/housing → Rent, medicines → Rent, travel → Fun.

Return ONLY valid JSON, no markdown fences, no explanation:
{"name":"item name","amount":6015.64,"date":"2026-08-30","category":"Fun","merchant":"Store Name"}`,
    user: `Extract bill data from this OCR text:\n\n${ocrText.substring(0, 3000)}`
  }

  // Try Groq first
  if (groq) {
    try {
      const result = await callGroq(prompt)
      if (result && result.amount > 0) return result
    } catch (err) {
      console.warn('Groq AI failed:', err.message)
    }
  }

  // Fallback to Hugging Face
  if (HF_KEY) {
    try {
      const result = await callHuggingFace(prompt)
      if (result && result.amount > 0) return result
    } catch (err) {
      console.warn('HuggingFace AI failed:', err.message)
    }
  }

  return null
}

async function callGroq(prompt) {
  const completion = await groq.chat.completions.create({
    model: 'openai/gpt-oss-20b',
    messages: [
      { role: 'system', content: prompt.system },
      { role: 'user', content: prompt.user },
    ],
    temperature: 0.1,
    max_tokens: 300,
  })

  const content = completion.choices[0]?.message?.content || ''
  return extractJSON(content)
}

async function callHuggingFace(prompt) {
  const combinedPrompt = `${prompt.system}\n\n${prompt.user}`

  const res = await fetch(
    'https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${HF_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        inputs: combinedPrompt,
        parameters: {
          max_new_tokens: 300,
          temperature: 0.1,
          return_full_text: false,
        },
      }),
    }
  )

  if (!res.ok) {
    const errText = await res.text()
    throw new Error(`HF API ${res.status}: ${errText}`)
  }

  const data = await res.json()
  const content = Array.isArray(data) ? data[0]?.generated_text : data.generated_text || ''
  return extractJSON(content)
}

function extractJSON(content) {
  if (!content) return null

  // Try to find JSON in the response
  let jsonStr = content
  const fenceMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/)
  if (fenceMatch) jsonStr = fenceMatch[1]

  const jsonMatch = jsonStr.match(/\{[\s\S]*?\}/)
  if (!jsonMatch) return null

  try {
    const parsed = JSON.parse(jsonMatch[0])
    return {
      name: parsed.name || null,
      amount: typeof parsed.amount === 'number' ? parsed.amount : null,
      date: parsed.date || null,
      category: parsed.category || null,
      merchant: parsed.merchant || null,
    }
  } catch {
    return null
  }
}
