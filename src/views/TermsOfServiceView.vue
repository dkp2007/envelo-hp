<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <div class="legal-page">
    <div class="legal-nav">
      <button class="back-btn" @click="router.push('/')">← Back to Envelo</button>
    </div>

    <div class="legal-card">
      <div class="legal-header">
        <img src="/wordmark.png" alt="Envelo" class="legal-wordmark" />
        <h1 class="legal-title">Terms of Service</h1>
        <p class="legal-date">Last updated: August 29, 2025</p>
      </div>

      <div class="legal-body">
        <section class="legal-section">
          <h2>1. Acceptance of Terms</h2>
          <p>By accessing or using Envelo ("the Service", "the App"), you agree to be bound by these Terms of Service ("Terms"). If you disagree with any part of these Terms, you may not access or use the Service. We reserve the right to modify these Terms at any time, and your continued use of the Service constitutes acceptance of any changes.</p>
        </section>

        <section class="legal-section">
          <h2>2. Description of Service</h2>
          <p>Envelo is a personal finance and budgeting application that helps users track income and expenses, manage budgets through an envelope system, set savings goals, and generate financial reports. The Service may include AI-generated financial insights and recommendations.</p>
          <p>We reserve the right to modify, suspend, or discontinue any part of the Service at any time without prior notice.</p>
        </section>

        <section class="legal-section">
          <h2>3. Account Registration</h2>
          <p>To use Envelo, you must create an account by providing accurate and complete information. You may register via Google OAuth or email and password authentication.</p>
          <ul>
            <li>You are responsible for maintaining the confidentiality of your account credentials</li>
            <li>You must be at least 18 years of age to create an account</li>
            <li>You must provide accurate, current, and complete information during registration</li>
            <li>You are responsible for all activity that occurs under your account</li>
            <li>You must notify us immediately of any unauthorized use of your account</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>4. Acceptable Use</h2>
          <p>You agree to use Envelo only for lawful purposes and in accordance with these Terms. You agree not to:</p>
          <ul>
            <li>Use the Service for any fraudulent or illegal purpose</li>
            <li>Attempt to gain unauthorized access to any part of the Service or other users' accounts</li>
            <li>Interfere with, disrupt, or create an undue burden on the Service or its infrastructure</li>
            <li>Use automated systems (bots, scrapers) to access or interact with the Service</li>
            <li>Reverse engineer, decompile, or disassemble any part of the application</li>
            <li>Upload malicious code, viruses, or any harmful content</li>
            <li>Impersonate another person or misrepresent your identity</li>
            <li>Resell, sublicense, or commercially exploit the Service without written permission</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>5. Your Data</h2>
          <h3>5.1 Ownership</h3>
          <p>You retain full ownership of all financial data, uploaded documents, and personal information you input into Envelo. We do not claim any ownership rights over your data.</p>

          <h3>5.2 License to Process</h3>
          <p>By using the Service, you grant us a limited, non-exclusive license to process your data solely for the purpose of providing and improving the Service. This includes AI-powered analysis of your financial data to generate insights and recommendations.</p>

          <h3>5.3 Data Portability</h3>
          <p>You can export your data at any time through the Reports page (PDF and Excel formats). If you close your account, all your data will be permanently deleted within 30 days.</p>
        </section>

        <section class="legal-section">
          <h2>6. AI-Generated Content</h2>
          <p>Envelo provides AI-generated financial insights, recommendations, and stress test analyses through third-party AI services. Please note:</p>
          <ul>
            <li>AI-generated content is for informational and educational purposes only</li>
            <li>AI insights do not constitute professional financial advice</li>
            <li>We do not guarantee the accuracy, completeness, or reliability of AI-generated content</li>
            <li>You should consult a qualified financial advisor before making significant financial decisions</li>
            <li>AI responses may vary and should not be treated as definitive financial guidance</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>7. Intellectual Property</h2>
          <p>The Service, including its design, code, features, branding, and documentation, is owned by Envelo and protected by copyright, trademark, and other intellectual property laws. You may not copy, modify, distribute, sell, or lease any part of our Service without our express written permission.</p>
        </section>

        <section class="legal-section">
          <h2>8. Payment and Billing</h2>
          <p>Envelo currently operates on a free plan basis. We reserve the right to introduce paid features, subscription tiers, or pricing changes in the future. If paid features are introduced, you will be notified in advance and given the option to accept or decline the new terms.</p>
        </section>

        <section class="legal-section">
          <h2>9. Disclaimers</h2>
          <p>THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED. WE DISCLAIM ALL WARRANTIES, INCLUDING BUT NOT LIMITED TO:</p>
          <ul>
            <li>Merchantability, fitness for a particular purpose, and non-infringement</li>
            <li>That the Service will be uninterrupted, timely, secure, or error-free</li>
            <li>That the results obtained from using the Service will be accurate or reliable</li>
            <li>That any errors in the Service will be corrected</li>
          </ul>
          <p>Envelo is a budgeting tool, not a licensed financial advisor, broker, or tax professional. The information and tools provided should not be considered professional financial, legal, or tax advice.</p>
        </section>

        <section class="legal-section">
          <h2>10. Limitation of Liability</h2>
          <p>To the maximum extent permitted by applicable law, Envelo and its affiliates, officers, employees, and agents shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to:</p>
          <ul>
            <li>Loss of profits, data, business opportunities, or goodwill</li>
            <li>Damages resulting from financial decisions made based on the Service</li>
            <li>Damages resulting from unauthorized access to or alteration of your data</li>
            <li>Damages resulting from third-party services or AI-generated content</li>
          </ul>
          <p>Our total liability to you for all claims arising from or relating to the Service shall not exceed the amount you paid us in the twelve (12) months preceding the claim, or ₹1,000, whichever is greater.</p>
        </section>

        <section class="legal-section">
          <h2>11. Indemnification</h2>
          <p>You agree to indemnify, defend, and hold harmless Envelo and its officers, directors, employees, and agents from any claims, liabilities, damages, losses, and expenses (including legal fees) arising from your use of the Service, violation of these Terms, or violation of any rights of another party.</p>
        </section>

        <section class="legal-section">
          <h2>12. Termination</h2>
          <p>We may terminate or suspend your account and access to the Service immediately, without prior notice or liability, for any reason, including but not limited to a breach of these Terms.</p>
          <p>You may terminate your account at any time by using the "Delete Account" option in Settings. Upon termination, your right to use the Service ceases immediately, and all associated data will be deleted within 30 days.</p>
        </section>

        <section class="legal-section">
          <h2>13. Governing Law</h2>
          <p>These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes arising under these Terms shall be resolved in the courts of competent jurisdiction in India.</p>
        </section>

        <section class="legal-section">
          <h2>14. Changes to Terms</h2>
          <p>We reserve the right to modify these Terms at any time. We will notify you of any material changes by posting the updated Terms on this page with a new "Last updated" date. Your continued use of the Service after such changes constitutes acceptance of the updated Terms.</p>
        </section>

        <section class="legal-section">
          <h2>15. Contact</h2>
          <p>If you have any questions about these Terms, please contact us through the <router-link to="/help" class="inline-link">Help & Support</router-link> page or email us at legal@envelo.app.</p>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.legal-page {
  min-height: 100vh;
  background: var(--color-bg);
  padding: 2rem;
}

.legal-nav {
  max-width: 760px;
  margin: 0 auto 1.5rem;
}

.back-btn {
  font-size: 0.8125rem;
  font-weight: 500;
  font-family: var(--font-sans);
  color: var(--color-text-muted);
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  padding: 0.5rem 1rem;
  cursor: pointer;
  transition: color 0.2s, border-color 0.2s;
}

.back-btn:hover {
  color: var(--color-text);
  border-color: var(--color-graphite);
}

.legal-card {
  max-width: 760px;
  margin: 0 auto;
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: 3rem;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
}

.legal-header {
  text-align: center;
  margin-bottom: 2.5rem;
  padding-bottom: 2rem;
  border-bottom: 1px solid var(--color-bg);
}

.legal-wordmark {
  height: 36px;
  width: auto;
  object-fit: contain;
  margin-bottom: 1rem;
}

.legal-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.375rem;
}

.legal-date {
  font-size: 0.8125rem;
  color: var(--color-text-muted);
}

.legal-body {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.legal-section h2 {
  font-size: 1.0625rem;
  font-weight: 700;
  color: var(--color-text);
  margin-bottom: 0.75rem;
}

.legal-section h3 {
  font-size: 0.9375rem;
  font-weight: 600;
  color: var(--color-text);
  margin-top: 1rem;
  margin-bottom: 0.5rem;
}

.legal-section p {
  font-size: 0.875rem;
  line-height: 1.7;
  color: var(--color-text-muted);
  margin-bottom: 0.75rem;
}

.legal-section p strong {
  color: var(--color-text);
}

.legal-section ul {
  list-style: none;
  padding: 0;
  margin-bottom: 0.75rem;
}

.legal-section li {
  font-size: 0.875rem;
  line-height: 1.7;
  color: var(--color-text-muted);
  padding-left: 1.25rem;
  position: relative;
  margin-bottom: 0.25rem;
}

.legal-section li::before {
  content: '•';
  position: absolute;
  left: 0;
  color: var(--color-accent);
  font-weight: 700;
}

.legal-section li strong {
  color: var(--color-text);
}

.inline-link {
  color: var(--color-graphite);
  font-weight: 600;
  text-decoration: underline;
  text-decoration-color: var(--color-accent);
  text-underline-offset: 2px;
}

.inline-link:hover {
  color: var(--color-graphite);
}
</style>
