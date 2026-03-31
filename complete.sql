-- ============================================================
-- TripCraft / Travelethic - Complete Database Setup Script
-- ============================================================
-- This script sets up all required tables for the application
-- Run this script in your PostgreSQL/Supabase database
-- ============================================================

-- Drop existing tables (if needed for fresh setup)
-- WARNING: Uncomment these lines only if you want to reset the database
-- DROP TABLE IF EXISTS payment_transactions CASCADE;
-- DROP TABLE IF EXISTS user_planner_status CASCADE;
-- DROP TABLE IF EXISTS trip_plan_output CASCADE;
-- DROP TABLE IF EXISTS trip_plan_status CASCADE;
-- DROP TABLE IF EXISTS trip_plan CASCADE;
-- DROP TABLE IF EXISTS trip_history CASCADE;
-- DROP TABLE IF EXISTS plan_tasks CASCADE;
-- DROP TABLE IF EXISTS users CASCADE;

-- ============================================================
-- 1. USERS TABLE (JWT Authentication)
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(500) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- Create trigger function for auto-updating updated_at
CREATE OR REPLACE FUNCTION update_users_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_users_updated_at_trigger ON users;

-- Create trigger for users table
CREATE TRIGGER update_users_updated_at_trigger
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_users_updated_at();

-- ============================================================
-- 2. TRIP PLAN TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS trip_plan (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    destination TEXT NOT NULL,
    "startingLocation" TEXT NOT NULL,
    "travelDatesStart" TEXT NOT NULL,
    "travelDatesEnd" TEXT,
    "dateInputType" TEXT DEFAULT 'picker',
    duration INTEGER,
    "travelingWith" TEXT NOT NULL,
    adults INTEGER DEFAULT 1,
    children INTEGER DEFAULT 0,
    "ageGroups" TEXT[] DEFAULT '{}',
    budget DECIMAL(10, 2) NOT NULL,
    "budgetCurrency" TEXT DEFAULT 'USD',
    "travelStyle" TEXT NOT NULL,
    "budgetFlexible" BOOLEAN DEFAULT FALSE,
    vibes TEXT[] DEFAULT '{}',
    priorities TEXT[] DEFAULT '{}',
    interests TEXT,
    rooms INTEGER DEFAULT 1,
    pace INTEGER[] DEFAULT '{3}',
    "beenThereBefore" TEXT,
    "lovedPlaces" TEXT,
    "additionalInfo" TEXT,
    "userId" VARCHAR(255),
    "createdAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    "updatedAt" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY ("userId") REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes for trip_plan
CREATE INDEX IF NOT EXISTS idx_trip_plan_userId ON trip_plan("userId");
CREATE INDEX IF NOT EXISTS idx_trip_plan_createdAt ON trip_plan("createdAt");

-- Trigger function for trip_plan
CREATE OR REPLACE FUNCTION update_trip_plan_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and create trigger
DROP TRIGGER IF EXISTS update_trip_plan_updated_at_trigger ON trip_plan;

CREATE TRIGGER update_trip_plan_updated_at_trigger
    BEFORE UPDATE ON trip_plan
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_plan_updated_at();

-- ============================================================
-- 3. TRIP PLAN STATUS TABLE
-- ============================================================

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
    CONSTRAINT trip_plan_status_pkey PRIMARY KEY (id),
    CONSTRAINT unique_trip_plan_id UNIQUE ("tripPlanId")
);

-- Create index on tripPlanId for faster lookups
CREATE INDEX IF NOT EXISTS idx_trip_plan_status_trip_plan_id ON trip_plan_status("tripPlanId");

-- Trigger function for trip_plan_status
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for trip_plan_status
DROP TRIGGER IF EXISTS update_trip_plan_status_updated_at ON trip_plan_status;

CREATE TRIGGER update_trip_plan_status_updated_at
    BEFORE UPDATE ON trip_plan_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 4. TRIP PLAN OUTPUT TABLE
-- ============================================================

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

-- Create trigger for trip_plan_output
DROP TRIGGER IF EXISTS update_trip_plan_output_updated_at ON trip_plan_output;

CREATE TRIGGER update_trip_plan_output_updated_at
    BEFORE UPDATE ON trip_plan_output
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 5. TRIP HISTORY TABLE
-- ============================================================

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

-- ============================================================
-- 6. USER PLANNER STATUS TABLE (Payment Tracking)
-- ============================================================

CREATE TABLE IF NOT EXISTS user_planner_status (
    user_id VARCHAR(255) PRIMARY KEY,
    has_used_free_planner BOOLEAN DEFAULT FALSE,
    total_planners_created INTEGER DEFAULT 0,
    is_premium BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_user_planner_status_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_planner_status_user_id ON user_planner_status(user_id);
CREATE INDEX IF NOT EXISTS idx_user_planner_status_is_premium ON user_planner_status(is_premium);
CREATE INDEX IF NOT EXISTS idx_user_planner_status_premium ON user_planner_status(is_premium);

-- ============================================================
-- 7. PAYMENT TRANSACTIONS TABLE
-- ============================================================

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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (user_id) REFERENCES user_planner_status(user_id)
);

-- Create indexes for payment transactions
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_razorpay_order_id ON payment_transactions(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);

-- ============================================================
-- COMPLETION MESSAGE
-- ============================================================

DO $$
BEGIN
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Database setup completed successfully!';
    RAISE NOTICE '============================================================';
    RAISE NOTICE 'Created tables:';
    RAISE NOTICE '  1. users - User authentication';
    RAISE NOTICE '  2. trip_plan - Trip planning data';
    RAISE NOTICE '  3. trip_plan_status - Trip plan status tracking';
    RAISE NOTICE '  4. trip_plan_output - Generated itineraries';
    RAISE NOTICE '  5. trip_history - Historical trip records';
    RAISE NOTICE '  6. user_planner_status - User premium status';
    RAISE NOTICE '  7. payment_transactions - Payment records';
    RAISE NOTICE '============================================================';
END $$;
