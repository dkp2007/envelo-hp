-- ============================================================
-- MIGRATION 010: Add OCR extraction columns to transactions
-- ============================================================

-- Add OCR-extracted fields to transactions
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS merchant text;
ALTER TABLE public.transactions ADD COLUMN IF NOT EXISTS ocr_raw_text text;

-- Index for searching by merchant name
CREATE INDEX IF NOT EXISTS idx_transactions_merchant ON public.transactions(merchant);
