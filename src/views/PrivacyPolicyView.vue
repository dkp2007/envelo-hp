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
        <h1 class="legal-title">Privacy Policy</h1>
        <p class="legal-date">Last updated: August 29, 2025</p>
      </div>

      <div class="legal-body">
        <section class="legal-section">
          <h2>1. Introduction</h2>
          <p>Welcome to Envelo ("we", "our", "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our personal finance and budgeting application.</p>
          <p>By using Envelo, you agree to the collection and use of information in accordance with this policy. If you do not agree with the terms of this policy, please discontinue use of our services immediately.</p>
        </section>

        <section class="legal-section">
          <h2>2. Information We Collect</h2>
          <h3>2.1 Personal Information</h3>
          <p>We may collect the following personal information when you create an account:</p>
          <ul>
            <li>Full name</li>
            <li>Email address</li>
            <li>Phone number (optional)</li>
            <li>Country and timezone preferences</li>
            <li>Avatar or profile photo</li>
          </ul>

          <h3>2.2 Financial Data</h3>
          <p>Envelo is designed to help you manage your finances. We store the financial data you voluntarily input, including:</p>
          <ul>
            <li>Income and expense transactions</li>
            <li>Budget categories and allocations</li>
            <li>Savings goals and targets</li>
            <li>Uploaded bills and receipts (images and PDFs)</li>
            <li>Reports and analytics data</li>
          </ul>

          <h3>2.3 Usage Data</h3>
          <p>We automatically collect certain information when you use the application, including:</p>
          <ul>
            <li>Device type and browser information</li>
            <li>IP address and approximate location</li>
            <li>Pages visited and features used</li>
            <li>Session duration and interaction patterns</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>3. How We Use Your Information</h2>
          <p>We use the information we collect to:</p>
          <ul>
            <li>Provide, maintain, and improve the Envelo application</li>
            <li>Personalize your experience and generate AI-powered financial insights</li>
            <li>Process your transactions and track your budget progress</li>
            <li>Send important account notifications and security alerts</li>
            <li>Respond to your support requests and communications</li>
            <li>Detect and prevent fraud, abuse, and security threats</li>
            <li>Comply with legal obligations</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>4. How We Share Your Information</h2>
          <p>We do <strong>not</strong> sell, trade, or rent your personal information to third parties. We may share your information only in the following circumstances:</p>
          <ul>
            <li><strong>Service Providers:</strong> We use Supabase for database hosting and authentication, and Groq for AI processing. These providers have access only to the information necessary to perform their services.</li>
            <li><strong>Legal Requirements:</strong> We may disclose your information if required by law or in response to valid requests by public authorities.</li>
            <li><strong>Business Transfers:</strong> In the event of a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction.</li>
            <li><strong>With Your Consent:</strong> We may share your information for any other purpose with your explicit consent.</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>5. Data Security</h2>
          <p>We implement industry-standard security measures to protect your data:</p>
          <ul>
            <li>All data is encrypted in transit using TLS/SSL</li>
            <li>Data at rest is encrypted using AES-256</li>
            <li>Row Level Security (RLS) ensures only you can access your data</li>
            <li>Authentication is handled via Google OAuth and Supabase Auth with secure token management</li>
            <li>We conduct regular security audits and vulnerability assessments</li>
          </ul>
          <p>While we strive to protect your information, no method of electronic transmission or storage is 100% secure. We cannot guarantee absolute security.</p>
        </section>

        <section class="legal-section">
          <h2>6. Data Retention</h2>
          <p>We retain your personal information and financial data for as long as your account is active or as needed to provide our services. When you delete your account, all associated data is permanently removed from our servers within 30 days, except where retention is required by law.</p>
        </section>

        <section class="legal-section">
          <h2>7. Your Rights</h2>
          <p>You have the right to:</p>
          <ul>
            <li><strong>Access</strong> — View all data stored in your Envelo account</li>
            <li><strong>Modify</strong> — Update your personal information and preferences in Settings</li>
            <li><strong>Export</strong> — Download your financial data as PDF or Excel from the Reports page</li>
            <li><strong>Delete</strong> — Permanently delete your account and all data from the Settings page</li>
            <li><strong>Restrict Processing</strong> — Request that we limit how we use your data</li>
          </ul>
        </section>

        <section class="legal-section">
          <h2>8. Cookies and Tracking</h2>
          <p>Envelo uses minimal cookies necessary for authentication and session management. We do not use advertising cookies or third-party tracking pixels. You can manage cookie settings through your browser preferences.</p>
        </section>

        <section class="legal-section">
          <h2>9. Children's Privacy</h2>
          <p>Envelo is not intended for users under the age of 18. We do not knowingly collect personal information from children. If we become aware that we have collected data from a child, we will take steps to delete it promptly.</p>
        </section>

        <section class="legal-section">
          <h2>10. Changes to This Policy</h2>
          <p>We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy on this page with an updated "Last updated" date. We encourage you to review this policy periodically.</p>
        </section>

        <section class="legal-section">
          <h2>11. Contact Us</h2>
          <p>If you have any questions about this Privacy Policy or our data practices, please contact us through the <router-link to="/help" class="inline-link">Help & Support</router-link> page or email us at privacy@envelo.app.</p>
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
