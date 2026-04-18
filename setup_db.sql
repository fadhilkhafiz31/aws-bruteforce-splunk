USE securebank_db;

-- 1. Create Extra Users
INSERT INTO users (username, password_hash, email, display_name, role, created_at, updated_at)
VALUES 
('Jack', 'Jack', 'jack@test.com' ,' JackTheRipper', 'user', now(), now()),
('Mia', 'Mia', 'mia@test.com' ,' Mia Wong', 'user', now(), now()),
('Oliver', 'Oliver', 'oliver@test.com' ,' Oliver Twist', 'user', now(), now());

-- 2. Create Transactions Table
DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
  id VARCHAR(50) PRIMARY KEY,
  owner VARCHAR(50) NOT NULL,
  date DATETIME NOT NULL,
  description VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  type VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL,
  flagged BOOLEAN DEFAULT FALSE,
  flag_reason VARCHAR(255),
  category VARCHAR(50)
);

-- 3. Insert realistic transactions from Jan to April 2026
INSERT INTO transactions (id, owner, date, description, amount, type, status, flagged, flag_reason, category)
VALUES
-- January 2026
('TXN-20260105-001', 'user123', '2026-01-05 09:00:00', 'Salary Credit — MIS Department', 4200.00, 'credit', 'completed', false, null, 'Income'),
('TXN-20260110-001', 'Jack', '2026-01-10 14:30:00', 'Online Purchase — Amazon', -149.99, 'debit', 'completed', false, null, 'Shopping'),
('TXN-20260112-001', 'Mia', '2026-01-12 18:20:00', 'Grocery — Lotus Stores', -80.50, 'debit', 'completed', false, null, 'Food'),
('TXN-20260115-001', 'Oliver', '2026-01-15 08:45:00', 'Petrol — Shell Station', -60.00, 'debit', 'completed', false, null, 'Transport'),
('TXN-20260118-001', 'user123', '2026-01-18 11:15:00', 'Online Transfer — Utilities', -120.00, 'debit', 'completed', false, null, 'Bills'),
('TXN-20260122-001', 'Jack', '2026-01-22 02:30:15', 'International Wire — Unknown Recipient', -4500.00, 'debit', 'completed', true, 'Unusual hour + large international transfer', 'Transfer'),
('TXN-20260125-001', 'user123', '2026-01-25 15:40:00', 'ATM Withdrawal — Kuala Lumpur', -300.00, 'debit', 'completed', false, null, 'Cash'),

-- February 2026
('TXN-20260205-001', 'user123', '2026-02-05 09:00:00', 'Salary Credit — MIS Department', 4200.00, 'credit', 'completed', false, null, 'Income'),
('TXN-20260208-001', 'Mia', '2026-02-08 19:10:00', 'Dining — McDonald''s', -35.20, 'debit', 'completed', false, null, 'Food'),
('TXN-20260214-001', 'Jack', '2026-02-14 20:00:00', 'Jewelry Store — Valentine Gift', -1500.00, 'debit', 'completed', false, null, 'Shopping'),
('TXN-20260218-001', 'Oliver', '2026-02-18 10:05:00', 'Standing Order — Loan Repayment', -1200.00, 'debit', 'completed', false, null, 'Loan'),
('TXN-20260220-001', 'user123', '2026-02-20 12:30:00', 'Online Purchase — Shopee', -210.00, 'debit', 'completed', false, null, 'Shopping'),
('TXN-20260222-001', 'Mia', '2026-02-22 14:15:00', 'ATM Withdrawal — Penang', -500.00, 'debit', 'completed', false, null, 'Cash'),
('TXN-20260222-002', 'Mia', '2026-02-22 14:16:15', 'ATM Withdrawal — Penang', -500.00, 'debit', 'completed', true, 'Duplicate ATM withdrawal — same machine, 75 seconds apart', 'Cash'),
('TXN-20260228-001', 'user123', '2026-02-28 09:45:00', 'Petrol — Petronas', -90.00, 'debit', 'completed', false, null, 'Transport'),

-- March 2026
('TXN-20260305-001', 'user123', '2026-03-05 09:00:00', 'Salary Credit — MIS Department', 4200.00, 'credit', 'completed', false, null, 'Income'),
('TXN-20260310-001', 'Oliver', '2026-03-10 11:20:00', 'Online Transfer — Rent', -1500.00, 'debit', 'completed', false, null, 'Bills'),
('TXN-20260312-001', 'Jack', '2026-03-12 16:40:00', 'Grocery — Lotus Stores', -115.30, 'debit', 'completed', false, null, 'Food'),
('TXN-20260315-001', 'Mia', '2026-03-15 03:15:00', 'Online Purchase — Unknown IP', -899.99, 'debit', 'pending', true, 'Large e-commerce transaction from flagged IP address', 'Shopping'),
('TXN-20260318-001', 'user123', '2026-03-18 13:10:00', 'Dining — Starbucks', -18.50, 'debit', 'completed', false, null, 'Food'),
('TXN-20260322-001', 'Oliver', '2026-03-22 10:00:00', 'Flight Ticket — AirAsia', -350.00, 'debit', 'completed', false, null, 'Travel'),
('TXN-20260325-001', 'Jack', '2026-03-25 14:50:00', 'ATM Withdrawal — Johor Bahru', -400.00, 'debit', 'completed', false, null, 'Cash'),
('TXN-20260328-001', 'user123', '2026-03-28 09:30:00', 'Utility Bill — Tenaga Nasional', -145.20, 'debit', 'completed', false, null, 'Bills'),

-- April 2026
('TXN-20260401-001', 'user123', '2026-04-01 09:14:22', 'Salary Credit — MIS Department', 4200.00, 'credit', 'completed', false, null, 'Income'),
('TXN-20260401-002', 'user123', '2026-04-01 11:30:05', 'Online Transfer — Utilities', -185.50, 'debit', 'completed', false, null, 'Bills'),
('TXN-20260402-003', 'otheruser', '2026-04-02 02:47:13', 'International Wire — Unknown Recipient', -3800.00, 'debit', 'completed', true, 'Unusual hour + large international transfer', 'Transfer'),
('TXN-20260402-004', 'Jack', '2026-04-02 08:20:00', 'Grocery — Lotus Stores', -62.30, 'debit', 'completed', false, null, 'Food'),
('TXN-20260403-005', 'Mia', '2026-04-03 14:05:44', 'ATM Withdrawal — Petaling Jaya', -500.00, 'debit', 'completed', false, null, 'Cash'),
('TXN-20260403-006', 'Mia', '2026-04-03 14:07:02', 'ATM Withdrawal — Kuala Lumpur', -500.00, 'debit', 'completed', true, 'Duplicate ATM withdrawal — different location, 78 seconds apart', 'Cash'),
('TXN-20260404-007', 'Oliver', '2026-04-04 10:15:30', 'Online Purchase — Amazon', -149.99, 'debit', 'completed', false, null, 'Shopping'),
('TXN-20260404-008', 'Oliver', '2026-04-04 10:16:45', 'Online Purchase — Amazon', -149.99, 'debit', 'pending', true, 'Duplicate transaction — same amount, same merchant, 75 seconds apart', 'Shopping'),
('TXN-20260405-009', 'user123', '2026-04-05 16:00:00', 'Petrol — Shell Station', -80.00, 'debit', 'completed', false, null, 'Transport'),
('TXN-20260406-010', 'user123', '2026-04-06 09:00:00', 'Standing Order — Loan Repayment', -1200.00, 'debit', 'completed', false, null, 'Loan');
