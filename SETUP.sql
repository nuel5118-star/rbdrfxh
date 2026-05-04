-- BotCipher Mail — Full Database Setup
-- Run in Supabase SQL Editor

CREATE TABLE IF NOT EXISTS campaigns (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL, status TEXT DEFAULT 'draft',
  daily_cap INTEGER DEFAULT 500, per_inbox_cap INTEGER DEFAULT 100,
  max_new_leads_per_day INTEGER DEFAULT 0,
  send_hour_start INTEGER DEFAULT 9, send_hour_end INTEGER DEFAULT 17,
  skip_weekends BOOLEAN DEFAULT true, timezone TEXT DEFAULT 'America/New_York',
  start_date DATE, end_date DATE,
  stop_on_auto_reply BOOLEAN DEFAULT false, random_delay_max INTEGER DEFAULT 30,
  created_at TIMESTAMPTZ DEFAULT NOW(), updated_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS max_new_leads_per_day INTEGER DEFAULT 0;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS start_date DATE;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS end_date DATE;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS stop_on_auto_reply BOOLEAN DEFAULT false;
ALTER TABLE campaigns ADD COLUMN IF NOT EXISTS random_delay_max INTEGER DEFAULT 30;

CREATE TABLE IF NOT EXISTS campaign_steps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL, subject TEXT NOT NULL, body TEXT NOT NULL,
  delay_days INTEGER DEFAULT 2, send_hour_start INTEGER, send_hour_end INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
ALTER TABLE campaign_steps ADD COLUMN IF NOT EXISTS send_hour_start INTEGER;
ALTER TABLE campaign_steps ADD COLUMN IF NOT EXISTS send_hour_end INTEGER;

CREATE TABLE IF NOT EXISTS contacts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID REFERENCES campaigns(id) ON DELETE CASCADE,
  email TEXT NOT NULL, first_name TEXT, last_name TEXT, company TEXT,
  city TEXT, phone TEXT, business_url TEXT, timezone TEXT,
  custom_fields JSONB DEFAULT '{}',
  status TEXT DEFAULT 'active', lead_label TEXT,
  current_step INTEGER DEFAULT 0, assigned_inbox TEXT,
  next_send_at TIMESTAMPTZ, enrolled_at TIMESTAMPTZ DEFAULT NOW(), finished_at TIMESTAMPTZ,
  UNIQUE(campaign_id, email)
);
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS business_url TEXT;
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS timezone TEXT;
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS custom_fields JSONB DEFAULT '{}';
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS lead_label TEXT;

CREATE TABLE IF NOT EXISTS sequence_sends (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  campaign_id UUID, contact_id UUID, email TEXT, inbox TEXT,
  step_number INTEGER, subject TEXT, sent_at TIMESTAMPTZ DEFAULT NOW(), status TEXT DEFAULT 'sent'
);

CREATE TABLE IF NOT EXISTS email_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL, recipient TEXT, sender_name TEXT, subject TEXT,
  inbox TEXT, campaign TEXT, reply_body TEXT, clicked_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS blacklist (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL, reason TEXT, created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS inboxes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT UNIQUE NOT NULL, label TEXT, active BOOLEAN DEFAULT true,
  daily_cap INTEGER DEFAULT 100, created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY, webhook_url TEXT,
  daily_cap INTEGER DEFAULT 500, per_inbox_cap INTEGER DEFAULT 100,
  send_hour_start INTEGER DEFAULT 9, send_hour_end INTEGER DEFAULT 17,
  skip_weekends BOOLEAN DEFAULT true, timezone TEXT DEFAULT 'America/New_York',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO settings (daily_cap, per_inbox_cap, send_hour_start, send_hour_end, skip_weekends, timezone)
VALUES (500, 100, 9, 17, true, 'America/New_York') ON CONFLICT DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_contacts_campaign_status ON contacts(campaign_id, status);
CREATE INDEX IF NOT EXISTS idx_contacts_next_send ON contacts(next_send_at) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_contacts_email ON contacts(email);
CREATE INDEX IF NOT EXISTS idx_sequence_sends_campaign ON sequence_sends(campaign_id, step_number, sent_at);
CREATE INDEX IF NOT EXISTS idx_email_events_campaign ON email_events(campaign, type);
CREATE INDEX IF NOT EXISTS idx_email_events_recipient ON email_events(recipient, type);
CREATE INDEX IF NOT EXISTS idx_blacklist_email ON blacklist(email);
