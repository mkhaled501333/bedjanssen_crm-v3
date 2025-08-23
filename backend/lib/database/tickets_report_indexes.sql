-- Indexes for Tickets Report Service Queries
-- Based on analysis of tickets_report_service.dart queries
-- These indexes will optimize the complex JOIN queries with WHERE conditions

-- =============================================================================
-- TICKETS TABLE INDEXES
-- =============================================================================

-- Primary index for tickets table (already exists as PRIMARY KEY)
-- CREATE INDEX idx_tickets_id ON tickets(id);

-- Most frequently used WHERE condition: company filtering
CREATE INDEX idx_tickets_company_id ON tickets(company_id);

-- Status filtering (very common in WHERE clauses)
CREATE INDEX idx_tickets_status ON tickets(status);

-- Priority filtering
CREATE INDEX idx_tickets_priority ON tickets(priority);

-- Date range filtering (used in WHERE DATE(created_at) >= ? AND DATE(created_at) <= ?)
CREATE INDEX idx_tickets_created_at ON tickets(created_at);

-- Foreign key indexes for JOINs
CREATE INDEX idx_tickets_customer_id ON tickets(customer_id);
CREATE INDEX idx_tickets_ticket_cat_id ON tickets(ticket_cat_id);
CREATE INDEX idx_tickets_created_by ON tickets(created_by);
CREATE INDEX idx_tickets_closed_by ON tickets(closed_by);

-- Composite indexes for common WHERE condition combinations
CREATE INDEX idx_tickets_company_status ON tickets(company_id, status);
CREATE INDEX idx_tickets_company_priority ON tickets(company_id, priority);
CREATE INDEX idx_tickets_company_date ON tickets(company_id, created_at);
CREATE INDEX idx_tickets_company_customer ON tickets(company_id, customer_id);
CREATE INDEX idx_tickets_company_category ON tickets(company_id, ticket_cat_id);

-- Composite index for the most common query pattern: company + date range + status
CREATE INDEX idx_tickets_company_date_status ON tickets(company_id, created_at, status);

-- Full composite index for complex filtering (covering most WHERE conditions)
CREATE INDEX idx_tickets_complex_filter ON tickets(company_id, customer_id, ticket_cat_id, status, priority, created_at);

-- =============================================================================
-- CUSTOMERS TABLE INDEXES
-- =============================================================================

-- Foreign key indexes for JOINs
CREATE INDEX idx_customers_company_id ON customers(company_id);
CREATE INDEX idx_customers_governomate_id ON customers(governomate_id);
CREATE INDEX idx_customers_city_id ON customers(city_id);
CREATE INDEX idx_customers_created_by ON customers(created_by);

-- Search optimization for customer name
CREATE INDEX idx_customers_name ON customers(name);

-- Composite indexes for common combinations
CREATE INDEX idx_customers_company_name ON customers(company_id, name);

-- =============================================================================
-- TICKET_CATEGORIES TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_ticket_categories_id ON ticket_categories(id);

-- Search optimization for category name
CREATE INDEX idx_ticket_categories_name ON ticket_categories(name);
CREATE INDEX idx_ticket_categories_company_id ON ticket_categories(company_id);

-- =============================================================================
-- TICKET_ITEMS TABLE INDEXES
-- =============================================================================

-- Foreign key indexes for JOINs
CREATE INDEX idx_ticket_items_ticket_id ON ticket_items(ticket_id);
CREATE INDEX idx_ticket_items_product_id ON ticket_items(product_id);
CREATE INDEX idx_ticket_items_request_reason_id ON ticket_items(request_reason_id);
CREATE INDEX idx_ticket_items_created_by ON ticket_items(created_by);
CREATE INDEX idx_ticket_items_company_id ON ticket_items(company_id);

-- For ORDER BY optimization in batch queries
CREATE INDEX idx_ticket_items_ticket_created ON ticket_items(ticket_id, created_at);

-- Composite index for the batch query pattern
CREATE INDEX idx_ticket_items_batch_query ON ticket_items(ticket_id, product_id, request_reason_id, created_at);

-- =============================================================================
-- TICKETCALL TABLE INDEXES
-- =============================================================================

-- Foreign key indexes for JOINs
CREATE INDEX idx_ticketcall_ticket_id ON ticketcall(ticket_id);
CREATE INDEX idx_ticketcall_company_id ON ticketcall(company_id);
CREATE INDEX idx_ticketcall_call_cat_id ON ticketcall(call_cat_id);
CREATE INDEX idx_ticketcall_created_by ON ticketcall(created_by);

-- For the COUNT(*) GROUP BY optimization in subquery
CREATE INDEX idx_ticketcall_count_optimization ON ticketcall(ticket_id, company_id);

-- =============================================================================
-- PRODUCT_INFO TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_product_info_id ON product_info(id);

CREATE INDEX idx_product_info_company_id ON product_info(company_id);
CREATE INDEX idx_product_info_created_by ON product_info(created_by);

-- =============================================================================
-- REQUEST_REASONS TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_request_reasons_id ON request_reasons(id);

CREATE INDEX idx_request_reasons_company_id ON request_reasons(company_id);
CREATE INDEX idx_request_reasons_created_by ON request_reasons(created_by);

-- =============================================================================
-- COMPANIES TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_companies_id ON companies(id);

-- Already has index on name from migrations
-- CREATE INDEX idx_companies_name ON companies(name);

-- =============================================================================
-- GOVERNORATES TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_governorates_id ON governorates(id);

-- =============================================================================
-- CITIES TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_cities_id ON cities(id);

-- Already has index on governorate_id from migrations
-- CREATE INDEX idx_cities_governorate_id ON cities(governorate_id);

-- =============================================================================
-- USERS TABLE INDEXES
-- =============================================================================

-- Foreign key index (already covered by PRIMARY KEY on id)
-- CREATE INDEX idx_users_id ON users(id);

CREATE INDEX idx_users_company_id ON users(company_id);
CREATE INDEX idx_users_is_active ON users(is_active);

-- =============================================================================
-- ADDITIONAL OPTIMIZATION INDEXES
-- =============================================================================

-- Index for search functionality (covers LIKE queries on description and name fields)
-- Note: For LIKE queries with leading wildcards ('%search%'), MySQL may not use indexes efficiently
-- Consider using FULLTEXT indexes for better search performance

-- For exact matches and prefix searches, these indexes help:
CREATE INDEX idx_tickets_description_prefix ON tickets(description(50));
CREATE INDEX idx_customers_name_prefix ON customers(name(50));

-- If using MySQL 5.7+, consider FULLTEXT indexes for better search performance:
-- CREATE FULLTEXT INDEX ft_tickets_description ON tickets(description);
-- CREATE FULLTEXT INDEX ft_customers_name ON customers(name);
-- CREATE FULLTEXT INDEX ft_ticket_categories_name ON ticket_categories(name);

-- =============================================================================
-- PERFORMANCE MONITORING INDEXES
-- =============================================================================

-- Indexes for potential future queries (based on data access patterns)
CREATE INDEX idx_tickets_updated_at ON tickets(updated_at);
CREATE INDEX idx_customers_updated_at ON customers(updated_at);
CREATE INDEX idx_ticket_items_updated_at ON ticket_items(updated_at);
CREATE INDEX idx_ticketcall_created_at ON ticketcall(created_at);

-- =============================================================================
-- SEARCH OPTIMIZATION INDEXES
-- =============================================================================

-- For search functionality - prefix indexes for LIKE queries
-- These help with pattern matching on text fields
CREATE INDEX idx_tickets_description_prefix ON tickets(description(50));
CREATE INDEX idx_customers_name_prefix ON customers(name(50));
