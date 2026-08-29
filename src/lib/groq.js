import Groq from 'groq-sdk'

const groq = new Groq({
  dangerouslyAllowBrowser: true,
  apiKey: import.meta.env.VITE_GROQ_API_KEY,
})

export { groq }
