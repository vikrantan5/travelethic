-- ============================================================================
-- COMPLETE SUPABASE DATABASE SETUP FOR TRAVELETHIC PROJECT
-- ============================================================================
-- This script sets up the complete database schema for the TravelEthic application
-- Run this script in your Supabase SQL Editor to create all necessary tables
-- ============================================================================

-- STEP 1: Create Custom Types/Enums
-- ============================================================================

-- Create enum type for plan task status
CREATE TYPE plan_task_status AS ENUM ('queued', 'in_progress', 'success', 'error');

-- ============================================================================
-- STEP 2: Create Authentication & User Management Tables
-- ============================================================================

-- User table
CREATE TABLE "user" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "emailVerified" BOOLEAN NOT NULL,
    "image" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- Create unique index on email
CREATE UNIQUE INDEX "user_email_key" ON "user"("email");

-- Session table for user sessions
CREATE TABLE "session" (
    "id" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "token" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "ipAddress" TEXT,
    "userAgent" TEXT,
    "userId" TEXT NOT NULL,
    CONSTRAINT "session_pkey" PRIMARY KEY ("id")
);

-- Create unique index on token
CREATE UNIQUE INDEX "session_token_key" ON "session"("token");

-- Add foreign key constraint
ALTER TABLE "session" ADD CONSTRAINT "session_userId_fkey" 
    FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Account table for OAuth and authentication providers
CREATE TABLE "account" (
    "id" TEXT NOT NULL,
    "accountId" TEXT NOT NULL,
    "providerId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "accessToken" TEXT,
    "refreshToken" TEXT,
    "idToken" TEXT,
    "accessTokenExpiresAt" TIMESTAMP(3),
    "refreshTokenExpiresAt" TIMESTAMP(3),
    "scope" TEXT,
    "password" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);

-- Add foreign key constraint
ALTER TABLE "account" ADD CONSTRAINT "account_userId_fkey" 
    FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Verification table for email verification
CREATE TABLE "verification" (
    "id" TEXT NOT NULL,
    "identifier" TEXT NOT NULL,
    "value" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3),
    "updatedAt" TIMESTAMP(3),
    CONSTRAINT "verification_pkey" PRIMARY KEY ("id")
);

-- JWKS table for authentication keys
CREATE TABLE "jwks" (
    "id" TEXT NOT NULL,
    "publicKey" TEXT NOT NULL,
    "privateKey" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "jwks_pkey" PRIMARY KEY ("id")
);

-- ============================================================================
-- STEP 3: Create Trip Planning Tables
-- ============================================================================

-- Main trip plan table
CREATE TABLE "trip_plan" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "destination" TEXT NOT NULL,
    "startingLocation" TEXT NOT NULL,
    "travelDatesStart" TEXT NOT NULL,
    "travelDatesEnd" TEXT,
    "dateInputType" TEXT NOT NULL DEFAULT 'picker',
    "duration" INTEGER,
    "travelingWith" TEXT NOT NULL,
    "adults" INTEGER NOT NULL DEFAULT 1,
    "children" INTEGER NOT NULL DEFAULT 0,
    "ageGroups" TEXT[],
    "budget" DOUBLE PRECISION NOT NULL,
    "budgetCurrency" TEXT NOT NULL DEFAULT 'USD',
    "travelStyle" TEXT NOT NULL,
    "budgetFlexible" BOOLEAN NOT NULL DEFAULT false,
    "vibes" TEXT[],
    "priorities" TEXT[],
    "interests" TEXT,
    "rooms" INTEGER NOT NULL DEFAULT 1,
    "pace" INTEGER[],
    "beenThereBefore" TEXT,
    "lovedPlaces" TEXT,
    "additionalInfo" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "userId" TEXT,
    CONSTRAINT "trip_plan_pkey" PRIMARY KEY ("id")
);

-- Add foreign key constraint
ALTER TABLE "trip_plan" ADD CONSTRAINT "trip_plan_userId_fkey" 
    FOREIGN KEY ("userId") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Trip plan status table
CREATE TABLE IF NOT EXISTS trip_plan_status (
    id TEXT NOT NULL,
    "tripPlanId" TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    "currentStep" TEXT,
    error TEXT,
    "startedAt" TIMESTAMP WITHOUT TIME ZONE,
    "completedAt" TIMESTAMP WITHOUT TIME ZONE,
    "createdAt" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT trip_plan_status_pkey PRIMARY KEY (id)
);

-- Create index on tripPlanId for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_plan_status_trip_plan_id ON trip_plan_status("tripPlanId");

-- Trip plan output table
CREATE TABLE IF NOT EXISTS trip_plan_output (
    id TEXT NOT NULL,
    "tripPlanId" TEXT NOT NULL,
    itinerary TEXT NOT NULL,
    summary TEXT,
    "createdAt" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT trip_plan_output_pkey PRIMARY KEY (id)
);

-- Create index on tripPlanId for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_plan_output_trip_plan_id ON trip_plan_output("tripPlanId");

-- ============================================================================
-- STEP 4: Create Task Management Tables
-- ============================================================================

-- Plan tasks table for async task management
CREATE TABLE IF NOT EXISTS plan_tasks (
    id SERIAL PRIMARY KEY,
    trip_plan_id VARCHAR(50) NOT NULL,
    task_type VARCHAR(50) NOT NULL,
    status plan_task_status NOT NULL,
    input_data JSONB NOT NULL,
    output_data JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index on trip_plan_id for faster lookups
CREATE INDEX IF NOT EXISTS idx_plan_tasks_trip_plan_id ON plan_tasks(trip_plan_id);

-- Create index on status for faster filtering
CREATE INDEX IF NOT EXISTS idx_plan_tasks_status ON plan_tasks(status);

-- ============================================================================
-- STEP 5: Create Trip History Table
-- ============================================================================

-- Trip history table
CREATE TABLE IF NOT EXISTS trip_history (
    id VARCHAR(255) PRIMARY KEY,
    destination VARCHAR(500) NOT NULL,
    start_date VARCHAR(100),
    end_date VARCHAR(100),
    duration INTEGER NOT NULL,
    budget DECIMAL(10, 2),
    budget_currency VARCHAR(10) DEFAULT 'USD',
    travelers INTEGER DEFAULT 1,
    trip_plan_id VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_trip_history_created_at ON trip_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_trip_history_trip_plan_id ON trip_history(trip_plan_id);

-- Add comment
COMMENT ON TABLE trip_history IS 'Stores user trip history for past trips';

-- ============================================================================
-- STEP 6: Create Payment Tables
-- ============================================================================

-- User planner status table for tracking free/premium usage
CREATE TABLE IF NOT EXISTS user_planner_status (
    user_id VARCHAR(255) PRIMARY KEY,
    has_used_free_planner BOOLEAN DEFAULT FALSE,
    total_planners_created INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_planner_status_user_id ON user_planner_status(user_id);
CREATE INDEX IF NOT EXISTS idx_user_planner_status_is_premium ON user_planner_status(is_premium);

-- Payment transactions table for tracking payments
CREATE TABLE IF NOT EXISTS payment_transactions (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    razorpay_order_id VARCHAR(255) UNIQUE NOT NULL,
    razorpay_payment_id VARCHAR(255),
    razorpay_signature VARCHAR(255),
    amount INTEGER NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    plan_type VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES user_planner_status(user_id)
);

-- Create indexes for payment transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_razorpay_order_id ON payment_transactions(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

-- ============================================================================
-- STEP 7: Create Triggers and Functions
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create trigger for plan_tasks
CREATE TRIGGER update_plan_tasks_updated_at
    BEFORE UPDATE ON plan_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create trigger for trip_plan_status (using camelCase column name)
CREATE OR REPLACE FUNCTION update_trip_plan_status_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_trip_plan_status_updated_at
    BEFORE UPDATE ON trip_plan_status
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_plan_status_updated_at();

-- Create trigger for trip_plan_output (using camelCase column name)
CREATE OR REPLACE FUNCTION update_trip_plan_output_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_trip_plan_output_updated_at
    BEFORE UPDATE ON trip_plan_output
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_plan_output_updated_at();

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- All tables, indexes, triggers, and constraints have been created.
-- Your database is now ready for the TravelEthic application.
-- 
-- Next Steps:
-- 1. Update your .env files with the correct DATABASE_URL and DIRECT_URL
-- 2. Run Prisma migrations if needed: npx prisma migrate deploy
-- 3. Generate Prisma client: npx prisma generate
-- ============================================================================
