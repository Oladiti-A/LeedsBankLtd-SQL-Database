-- LeedsBankLtd: Relational database for an online banking system
-- Designed from an ER model and normalised to 3NF
-- Author: Oladiti Abdulahi
CREATE DATABASE LeedsBankLtd. 
-- -- Table: Addresses.
CREATE TABLE Addresses (AddressID int IDENTITY(1,1) NOT NULL,
Address1 nvarchar (50) NOT NULL,
Address2 nvarchar (50) NULL,
City nvarchar (50) NOT NULL,
Postcode nvarchar (10) NOT NULL,
Country nvarchar (50) NOT NULL DEFAULT 'UK',
CONSTRAINT PK_Address PRIMARY KEY (AddressID));
-- Now we proceed to create our customers Table
-- Table: Customers
-- Links to Addresses table via AddressID foreign key
CREATE TABLE Customers (
CustomerID int IDENTITY(1,1) NOT NULL,
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL,
DateOfBirth DATE NOT NULL,
Username nvarchar(50) NOT NULL,
PasswordHash nvarchar(256)  NOT NULL,
Email nvarchar(100) NULL,
Telephone nvarchar(20) NULL,
AddressID int NOT NULL,
ClosureDate DATE NULL,
CONSTRAINT PK_Customers
	PRIMARY KEY (CustomerID),
CONSTRAINT FK_Customers_Addresses
	FOREIGN KEY (AddressID)
	REFERENCES Addresses(AddressID),
CONSTRAINT UQ_Customers_Username
	UNIQUE (Username),
CONSTRAINT UQ_Customers_Email
	UNIQUE (Email),
CONSTRAINT CHK_Customers_DOB
	CHECK (DateOfBirth < GETDATE()));
-- Now we proceed to create our Accounts Table
-- Stores all bank products and account details
-- AccountType and Status use CHECK constraints
-- To ensure only valid values are entered
-- ReferenceNumber is optional and only used for loans
CREATE TABLE Accounts (
AccountID int IDENTITY(1,1) NOT NULL,
AccountName nvarchar(50) NOT NULL,
AccountType nvarchar(20) NOT NULL,
OpeningDate DATE NOT NULL,
AccountStatus nvarchar(10) NOT NULL DEFAULT 'Active',
ClosureOrFreezeDate DATE NULL,
ReferenceNumber nvarchar(20) NULL,
Balance DECIMAL(18,2)  NOT NULL DEFAULT 0,
    CONSTRAINT PK_Accounts
        PRIMARY KEY (AccountID),
    CONSTRAINT CHK_Accounts_Type
        CHECK (AccountType IN (
            'Savings',
            'Checking',
            'Loan',
            'Credit Card',
            'Investment')),
    CONSTRAINT CHK_Accounts_Status
        CHECK (AccountStatus IN (
            'Active',
            'Dormant',
            'Closed',
            'Frozen')),
    CONSTRAINT UQ_Accounts_ReferenceNumber
        UNIQUE (ReferenceNumber)
);
-- Now we proceed to create our CustomerAccounts Table
-- This is our linking table connecting Customers 
-- and Accounts in a Many to Many relationship
-- One customer can have many accounts
-- One account can be shared by many customers
-- (joint accounts)
CREATE TABLE CustomerAccounts (
    CustomerAccountID int IDENTITY(1,1) NOT NULL,
    CustomerID int NOT NULL,
    AccountID int NOT NULL,
    DateLinked DATE  NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_CustomerAccounts
        PRIMARY KEY (CustomerAccountID),
    CONSTRAINT FK_CustomerAccounts_Customers
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),
    CONSTRAINT FK_CustomerAccounts_Accounts
        FOREIGN KEY (AccountID)
        REFERENCES Accounts(AccountID),
    CONSTRAINT UQ_CustomerAccounts
        UNIQUE (CustomerID, AccountID)
);
-- Now we proceed to create our  Transactions Table
-- Records every single money movement in the bank
-- CompletionDate is NULL when payment is still pending
-- DueDate only applies to Loan and Credit Card payments
-- Links to CustomerAccounts to know WHO and WHICH account
CREATE TABLE Transactions (
    TransactionID int IDENTITY(1,1) NOT NULL,
    CustomerAccountID  int NOT NULL,
    Amount DECIMAL(18,2)  NOT NULL,
    TransactionType nvarchar(20) NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT GETDATE(),
    DueDate DATETIME NULL,
    CompletionDate DATETIME NULL,
    CONSTRAINT PK_Transactions
        PRIMARY KEY (TransactionID),
    CONSTRAINT FK_Transactions_CustomerAccounts
        FOREIGN KEY (CustomerAccountID)
        REFERENCES CustomerAccounts(CustomerAccountID),
    CONSTRAINT CHK_Transactions_Type
        CHECK (TransactionType IN (
            'Deposit',
            'Withdrawal',
            'Transfer',
            'Loan Payment',
            'Credit Payment')),
    CONSTRAINT CHK_Transactions_Amount
        CHECK (Amount > 0)
);
-- Now we proceed to create our OverdueFees Table
-- Tracks late payment charges for missed or 
-- overdue loan and credit card payments
-- Links to Transactions to know which payment was late
-- Tracks total owed, repaid and outstanding balance
-- as required by the brief
CREATE TABLE OverdueFees (
    OverdueFeeID int IDENTITY(1,1) NOT NULL,
    TransactionID int NOT NULL,
    DaysOverdue int NOT NULL,
    FeeAmount DECIMAL(18,2)  NOT NULL,
    TotalOwed DECIMAL(18,2)  NOT NULL,
    TotalRepaid DECIMAL(18,2)  NOT NULL DEFAULT 0,
    OutstandingBalance DECIMAL(18,2)  NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_OverdueFees
        PRIMARY KEY (OverdueFeeID),
    CONSTRAINT FK_OverdueFees_Transactions
        FOREIGN KEY (TransactionID)
        REFERENCES Transactions(TransactionID),
    CONSTRAINT CHK_OverdueFees_Days
        CHECK (DaysOverdue > 0),
    CONSTRAINT CHK_OverdueFees_FeeAmount
        CHECK (FeeAmount > 0),
    CONSTRAINT CHK_OverdueFees_TotalOwed
        CHECK (TotalOwed > 0),
    CONSTRAINT CHK_OverdueFees_TotalRepaid
        CHECK (TotalRepaid >= 0),
    CONSTRAINT CHK_OverdueFees_Outstanding
        CHECK (OutstandingBalance >= 0)
);
-- Now we proceed to create our Repayments Table
-- Records every payment a customer makes 
-- towards their overdue fees
-- A customer can make multiple partial payments
-- towards the same overdue fee
-- Payment method is restricted to exactly 3 options
-- as specified in the brief
CREATE TABLE Repayments (
    RepaymentID int IDENTITY(1,1) NOT NULL,
    CustomerID int NOT NULL,
    OverdueFeeID int NOT NULL,
    RepaymentDateTime DATETIME NOT NULL DEFAULT GETDATE(),
    Amount DECIMAL(18,2) NOT NULL,
    PaymentMethod nvarchar(20) NOT NULL,
    CONSTRAINT PK_Repayments
        PRIMARY KEY (RepaymentID),
    CONSTRAINT FK_Repayments_Customers
        FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),
    CONSTRAINT FK_Repayments_OverdueFees
        FOREIGN KEY (OverdueFeeID)
        REFERENCES OverdueFees(OverdueFeeID),
    CONSTRAINT CHK_Repayments_Method
        CHECK (PaymentMethod IN (
            'Bank Transfer',
            'Card',
            'Cash')),
    CONSTRAINT CHK_Repayments_Amount
        CHECK (Amount > 0)
);
-- Now (Insert) the tables with the appropriate number of records
-- inserting 8 addresses for our customers
-- one extra for a branch address
INSERT INTO Addresses 
    (Address1, Address2, City, Postcode, Country)
VALUES
    ('12 Oak Street',     NULL,        'Manchester',   'M1 1AB', 'UK'),
    ('45 High Street',    'Flat 3',    'London',       'E1 6RF', 'UK'),
    ('78 Church Lane',    NULL,        'Birmingham',   'B1 2CD', 'UK'),
    ('23 Victoria Road',  'Suite 2',   'Leeds',        'LS1 4AP','UK'),
    ('56 Park Avenue',    NULL,        'Liverpool',    'L1 8JQ', 'UK'),
    ('90 Bridge Street',  'Floor 2',   'Sheffield',    'S1 2GH', 'UK'),
    ('34 Queen Street',   NULL,        'Bristol',      'BS1 4DJ','UK'),
    ('15 King Road',      'Apt 5',     'Nottingham',   'NG1 3AX','UK');
-- Now (Insert) the tables with the appropriate number of records of Customers
-- All 8 customers now have unique emails
-- Mix of customers with and without telephone
-- Fatima has ClosureDate as she closed her account
-- but data retained for marketing as per brief
INSERT INTO Customers
    (FirstName, LastName, DateOfBirth, Username, 
     PasswordHash, Email, Telephone, AddressID, ClosureDate)
VALUES
    ('Ali',    'Hassan', '1990-05-15', 'ali.hassan',
     'hashed_pwd_1', 'ali.hassan@email.com',   '07700111222', 1, NULL),

    ('Sara',   'Ahmed',  '1985-03-22', 'sara.ahmed',
     'hashed_pwd_2', 'sara.ahmed@email.com',   '07700333444', 2, NULL),

    ('Bob',    'Smith',  '1978-11-08', 'bob.smith',
     'hashed_pwd_3', 'bob.smith@email.com',    '07700555666', 3, NULL),

    ('Zara',   'Khan',   '1995-07-30', 'zara.khan',
     'hashed_pwd_4', 'zara.khan@email.com',    NULL,          4, NULL),

    ('James',  'Wilson', '1982-01-14', 'james.wilson',
     'hashed_pwd_5', 'james.wilson@email.com', '07700777888', 5, NULL),

    ('Emma',   'Brown',  '1993-09-25', 'emma.brown',
     'hashed_pwd_6', 'emma.brown@email.com',   NULL,          6, NULL),

    ('David',  'Jones',  '1975-12-03', 'david.jones',
     'hashed_pwd_7', 'david.jones@email.com',  '07700999000', 7, NULL),

    ('Fatima', 'Ali',    '1988-04-18', 'fatima.ali',
     'hashed_pwd_8', 'fatima.ali@email.com',   '07700112233', 8,
     '2024-01-01');
-- Now (Insert) the tables with the appropriate number of records of Accounts
-- Mix of all 5 account types from the brief
-- Mix of all 4 statuses for testing
-- Loan accounts have reference numbers
-- Balance represents current account balance
INSERT INTO Accounts
    (AccountName, AccountType, OpeningDate,
     AccountStatus, ClosureOrFreezeDate, ReferenceNumber, Balance)
VALUES
    ('Premier Savings',      'Savings',     '2020-01-15',
     'Active',  NULL, 'SAV001',  5000.00),

    ('Current Account',      'Checking',    '2019-06-20',
     'Active',  NULL, 'CHK001',  1250.75),

    ('Personal Loan',        'Loan',        '2021-03-10',
     'Active',  NULL, 'LOAN001', 8500.00),

    ('Credit Card Gold',     'Credit Card', '2022-07-05',
     'Active',  NULL, 'CRD001',  2300.50),

    ('Investment Portfolio', 'Investment',  '2018-11-30',
     'Active',  NULL, 'INV001',  15000.00),

    ('Home Loan',            'Loan',        '2020-09-15',
     'Active',  NULL, 'LOAN002', 45000.00),

    ('Basic Savings',        'Savings',     '2017-04-22',
     'Dormant', NULL, 'SAV002',  150.00),

    ('Business Checking',    'Checking',    '2021-01-10',
     'Frozen',  '2024-06-01', 'CHK002', 3200.00);
-- Now (Insert) the tables with the appropriate number of records of CustomerAccounts
-- Using ACTUAL IDs from the database
-- Customers: Ali=7, Sara=8, Bob=9, Zara=10,
-- James=11, Emma=12, David=13, Fatima=14
-- Accounts:  PremierSavings=3, CurrentAcc=4,
--            PersonalLoan=5, CreditCard=6,
--            Investment=7, HomeLoan=8,
--            BasicSavings=9, BusinessCheck=10
INSERT INTO CustomerAccounts
    (CustomerID, AccountID, DateLinked)
VALUES
    (7,  3,  '2020-01-15'),  -- Ali has Premier Savings
    (8,  3,  '2020-01-15'),  -- Sara has Premier Savings (joint!)
    (7,  4,  '2019-06-20'),  -- Ali has Current Account
    (8,  6,  '2022-07-05'),  -- Sara has Credit Card Gold
    (9,  5,  '2021-03-10'),  -- Bob has Personal Loan
    (10, 7,  '2018-11-30'),  -- Zara has Investment Portfolio
    (11, 8,  '2020-09-15'),  -- James has Home Loan
    (12, 9,  '2017-04-22'),  -- Emma has Basic Savings
    (13, 10, '2021-01-10'),  -- David has Business Checking
    (14, 4,  '2019-06-20');  -- Fatima has Current Account

-- Now (Insert) the tables with the appropriate number of records of Customer Transactions
-- Using ACTUAL CustomerAccountIDs from database
-- Mix of transaction types for testing
-- Some CompletionDate are NULL = pending payments
-- Some DueDate passed with NULL CompletionDate = OVERDUE
-- These overdue ones will generate OverdueFees
INSERT INTO Transactions
    (CustomerAccountID, Amount, TransactionType,
     TransactionDate, DueDate, CompletionDate)
VALUES
    -- Ali Premier Savings - completed deposit
    (2, 500.00, 'Deposit',
     '2024-01-10 09:00', NULL, '2024-01-10 09:00'),

    -- Ali Current Account - completed withdrawal
    (4, 250.00, 'Withdrawal',
     '2024-01-15 14:30', NULL, '2024-01-15 14:30'),

    -- Sara Credit Card - completed payment
    (5, 150.00, 'Credit Payment',
     '2024-02-01 10:00', '2024-02-01 00:00', '2024-02-01 10:00'),

    -- Bob Personal Loan - OVERDUE (DueDate passed, NULL CompletionDate)
    (6, 350.00, 'Loan Payment',
     '2024-01-01 08:00', '2024-01-31 00:00', NULL),

    -- James Home Loan - OVERDUE (DueDate passed, NULL CompletionDate)
    (8, 800.00, 'Loan Payment',
     '2024-01-05 09:00', '2024-01-31 00:00', NULL),

    -- Sara Premier Savings - completed deposit
    (3, 1000.00, 'Deposit',
     '2024-02-10 11:00', NULL, '2024-02-10 11:00'),

    -- Emma Basic Savings - completed withdrawal
    (9, 75.00, 'Withdrawal',
     '2024-02-15 16:00', NULL, '2024-02-15 16:00'),

    -- Sara Credit Card - OVERDUE
    (5, 200.00, 'Credit Payment',
     '2024-01-20 10:00', '2024-01-28 00:00', NULL),

    -- Ali Premier Savings - completed transfer
    (2, 300.00, 'Transfer',
     '2024-03-01 10:00', NULL, '2024-03-01 10:00'),

    -- Bob Personal Loan - OVERDUE second payment
    (6, 350.00, 'Loan Payment',
     '2024-03-01 08:00', '2024-03-31 00:00', NULL);

-- Now (Insert) the tables with the appropriate number of records of OverdueFees
-- Generated for the 4 overdue transactions
-- TransactionID 4 = Bob Loan Payment (overdue ~75 days)
-- TransactionID 5 = James Loan Payment (overdue ~75 days)
-- TransactionID 8 = Sara Credit Payment (overdue ~78 days)
-- TransactionID 10 = Bob second Loan Payment (overdue ~45 days)
-- FeeAmount = £10 per day overdue
-- TotalOwed = FeeAmount x DaysOverdue
-- OutstandingBalance = TotalOwed - TotalRepaid
INSERT INTO OverdueFees
    (TransactionID, DaysOverdue, FeeAmount,
     TotalOwed, TotalRepaid, OutstandingBalance)
VALUES
    (4,  75, 10.00, 750.00,  200.00, 550.00),
    (5,  75, 15.00, 1125.00, 100.00, 1025.00),
    (8,  78, 10.00, 780.00,  780.00, 0.00),
    (10, 45, 10.00, 450.00,  50.00,  400.00);
-- Now (Insert) the tables with the appropriate number of records of Repayments
-- Recording actual payments made towards overdue fees
-- Bob (CustomerID=9) paid OverdueFee 1 in two instalments
-- James (CustomerID=11) paid OverdueFee 2 partially
-- Sara (CustomerID=8) fully paid OverdueFee 3
-- Bob also paid OverdueFee 4 partially
-- Mix of all 3 payment methods from the brief
INSERT INTO Repayments
    (CustomerID, OverdueFeeID, RepaymentDateTime,
     Amount, PaymentMethod)
VALUES
    -- Bob paying OverdueFee 1 (£750 total) in instalments
    (9, 1, '2024-02-15 10:00', 100.00, 'Bank Transfer'),
    (9, 1, '2024-03-01 14:00', 100.00, 'Card'),

    -- James paying OverdueFee 2 (£1125 total) partially
    (11, 2, '2024-02-20 09:00', 100.00, 'Cash'),

    -- Sara fully paying OverdueFee 3 (£780 total)
    (8, 3, '2024-02-10 11:00', 390.00, 'Bank Transfer'),
    (8, 3, '2024-02-25 15:00', 390.00, 'Card'),

    -- Bob paying OverdueFee 4 (£450 total) partially
    (9, 4, '2024-03-05 10:00', 50.00,  'Bank Transfer'),

    -- Extra repayments for variety
    (8,  2, '2024-03-10 14:00', 25.00,  'Cash'),
    (11, 1, '2024-03-15 11:00', 75.00,  'Card');
-- Now Let's create Store Procedure
 --  Search bank accounts/products by name
-- Results sorted by most recently opened first
-- @AccountName parameter allows searching by name
-- Uses LIKE for partial matching
-- e.g. searching 'Sav' returns 'Premier Savings'
--      and 'Basic Savings'
CREATE PROCEDURE uspSearchAccounts
    @AccountName nvarchar(100)
AS
BEGIN
    SELECT
        AccountID,
        AccountName,
        AccountType,
        OpeningDate,
        AccountStatus,
        Balance,
        ReferenceNumber
    FROM Accounts
    WHERE AccountName LIKE '%' + @AccountName + '%'
    ORDER BY OpeningDate DESC;
END;
--Let's call one out.
EXEC uspSearchAccounts @AccountName = 'Savings';

-- Another Store Procedure to Return all loan or credit payments
-- due in less than 5 days from today
-- Shows pending payments due soon
-- CompletionDate IS NULL means payment not yet made
-- DATEDIFF calculates days between today and DueDate
CREATE PROCEDURE uspPaymentsDueSoon
AS
BEGIN
    SELECT
        t.TransactionID,
        c.FirstName,
        c.LastName,
        a.AccountName,
        a.AccountType,
        t.Amount,
        t.TransactionType,
        t.DueDate,
        DATEDIFF(DAY, GETDATE(), t.DueDate) AS DaysUntilDue
    FROM Transactions t
    INNER JOIN CustomerAccounts ca 
        ON t.CustomerAccountID = ca.CustomerAccountID
    INNER JOIN Customers c 
        ON ca.CustomerID = c.CustomerID
    INNER JOIN Accounts a 
        ON ca.AccountID = a.AccountID
    WHERE t.TransactionType IN ('Loan Payment', 'Credit Payment')
    AND t.CompletionDate IS NULL
    AND t.DueDate IS NOT NULL
    AND DATEDIFF(DAY, GETDATE(), t.DueDate) 
        BETWEEN 0 AND 5
    ORDER BY t.DueDate ASC;
END;
-- All our date are due, now let's use today's date with the new query by adding new row to our transaction table.
INSERT INTO Transactions
    (CustomerAccountID, Amount, TransactionType,
     TransactionDate, DueDate, CompletionDate)
VALUES
    (6, 350.00, 'Loan Payment',
     GETDATE(),
     DATEADD(DAY, 3, GETDATE()),
     NULL);
-- Now let's call the procedure
EXEC uspPaymentsDueSoon;

-- Another Store Procedure to Return a new bank customer
-- Takes all customer details as parameters
-- AddressID must already exist in Addresses table
-- Returns the new CustomerID after insertion
CREATE PROCEDURE uspInsertCustomer
    @FirstName    nvarchar(50),
    @LastName     nvarchar(50),
    @DateOfBirth  DATE,
    @Username     nvarchar(50),
    @PasswordHash nvarchar(256),
    @Email        nvarchar(100),
    @Telephone    nvarchar(20),
    @AddressID    int,
    @ClosureDate  DATE = NULL
AS
BEGIN
    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM Customers 
               WHERE Username = @Username)
    BEGIN
        PRINT 'Error: Username already exists!
               Please choose a different username.'
        RETURN
    END

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM Customers 
               WHERE Email = @Email)
    BEGIN
        PRINT 'Error: Email already registered!
               Please use a different email.'
        RETURN
    END

    -- Insert the new customer
    INSERT INTO Customers
        (FirstName, LastName, DateOfBirth,
         Username, PasswordHash, Email,
         Telephone, AddressID, ClosureDate)
    VALUES
        (@FirstName, @LastName, @DateOfBirth,
         @Username, @PasswordHash, @Email,
         @Telephone, @AddressID, @ClosureDate)

    -- Show the new CustomerID
    PRINT 'New customer added successfully!'
    PRINT 'New CustomerID = ' + 
           CAST(SCOPE_IDENTITY() AS NVARCHAR(10))
END;
-- Let's call it out
-- Add a brand new customer
EXEC uspInsertCustomer
    @FirstName    = 'Mohammed',
    @LastName     = 'Rahman',
    @DateOfBirth  = '1992-08-15',
    @Username     = 'mohammed.rahman',
    @PasswordHash = 'hashed_pwd_new',
    @Email        = 'mohammed.rahman@email.com',
    @Telephone    = '07700445566',
    @AddressID    = 1,
    @ClosureDate  = NULL;

 -- Another Store Procedure to Update existing customer details
-- Takes CustomerID to identify which customer
-- All other parameters are optional
-- If NULL is passed for any field it keeps 
-- the existing value unchanged
-- Uses ISNULL to only update provided fields

CREATE PROCEDURE uspUpdateCustomer
    @CustomerID int,
    @FirstName    nvarchar(50)  = NULL,
    @LastName     nvarchar(50)  = NULL,
    @Email        nvarchar(100) = NULL,
    @Telephone    nvarchar(20)  = NULL,
    @AddressID    int           = NULL,
    @ClosureDate  DATE          = NULL
AS
BEGIN
    -- Check customer exists first
    IF NOT EXISTS (SELECT 1 FROM Customers
                   WHERE CustomerID = @CustomerID)
    BEGIN
        PRINT 'Error: Customer not found!'
        RETURN
    END

    -- Update only the fields that were provided
    UPDATE Customers
    SET
        FirstName   = ISNULL(@FirstName,  FirstName),
        LastName    = ISNULL(@LastName,   LastName),
        Email       = ISNULL(@Email,      Email),
        Telephone   = ISNULL(@Telephone,  Telephone),
        AddressID   = ISNULL(@AddressID,  AddressID),
        ClosureDate = ISNULL(@ClosureDate, ClosureDate)
    WHERE CustomerID = @CustomerID;

    PRINT 'Customer updated successfully!'
END;
-- How to Call it
-- Update just the telephone number for Ali (CustomerID=7)
EXEC uspUpdateCustomer
    @CustomerID = 7,
    @Telephone  = '07799999999';

-- Update email and address for Bob (CustomerID=9)
EXEC uspUpdateCustomer
    @CustomerID = 9,
    @Email      = 'bob.newemail@email.com',
    @AddressID  = 2;

-- Close a customer account (CustomerID=15)
EXEC uspUpdateCustomer
    @CustomerID  = 15,
    @ClosureDate = '2026-04-16';

-- Now Let's create a View showing all transactions
-- with their associated overdue fees
-- LEFT JOIN used so ALL transactions show
-- even those WITHOUT overdue fees
-- NULL appears for fee columns when no fee exists

CREATE VIEW vw_TransactionsWithFees
AS
SELECT
    t.TransactionID,
    c.FirstName,
    c.LastName,
    a.AccountName,
    a.AccountType,
    t.Amount,
    t.TransactionType,
    t.TransactionDate,
    t.DueDate,
    t.CompletionDate,
    CASE
        WHEN t.CompletionDate IS NULL
        AND t.DueDate < GETDATE()
        THEN 'Overdue'
        WHEN t.CompletionDate IS NULL
        THEN 'Pending'
        ELSE 'Completed'
    END AS PaymentStatus,
    ovf.OverdueFeeID,
    ovf.DaysOverdue,
    ovf.FeeAmount,
    ovf.TotalOwed,
    ovf.TotalRepaid,
    ovf.OutstandingBalance
FROM Transactions t
INNER JOIN CustomerAccounts ca
    ON t.CustomerAccountID = ca.CustomerAccountID
INNER JOIN Customers c
    ON ca.CustomerID = c.CustomerID
INNER JOIN Accounts a
    ON ca.AccountID = a.AccountID
LEFT JOIN OverdueFees ovf
    ON t.TransactionID = ovf.TransactionID;
 -- Now Let's check our view with this Query
 -- Query 1: See ALL transactions with fees
SELECT * FROM vw_TransactionsWithFees;

-- Query 2: See only OVERDUE transactions
SELECT * FROM vw_TransactionsWithFees
WHERE PaymentStatus = 'Overdue';

-- Query 3: See only transactions WITH fees
SELECT * FROM vw_TransactionsWithFees
WHERE OverdueFeeID IS NOT NULL;

-- Let's create Trigger
-- Create a trigger that automatically updates the status of a Loan or Credit Card account 
-- when the final scheduled payment is recorded as completed"
-- Task 4: Trigger to automatically close
-- Loan or Credit Card accounts when 
-- final payment is completed
-- Fires AFTER UPDATE on Transactions table
-- Checks if CompletionDate was just set
-- and if account balance is now zero
CREATE TRIGGER trg_CloseAccountOnFinalPayment
ON Transactions
AFTER UPDATE
AS
BEGIN
    -- Only fire when CompletionDate is being set
    -- (changing from NULL to a date value)
    IF UPDATE(CompletionDate)
    BEGIN
        -- Update account status to Closed
        -- when balance reaches zero
        UPDATE Accounts
        SET 
            AccountStatus = 'Closed',
            ClosureOrFreezeDate = GETDATE()
        FROM Accounts a
        INNER JOIN CustomerAccounts ca
            ON a.AccountID = ca.AccountID
        INNER JOIN inserted i
            ON ca.CustomerAccountID = i.CustomerAccountID
        INNER JOIN deleted d
            ON d.TransactionID = i.TransactionID
        WHERE 
            -- Payment just completed
            i.CompletionDate IS NOT NULL
            AND d.CompletionDate IS NULL
            -- Only for Loan or Credit Card types
            AND a.AccountType IN ('Loan', 'Credit Card')
            -- Account balance is now zero
            AND a.Balance = 0
            -- Account is currently Active
            AND a.AccountStatus = 'Active';

        -- Print confirmation message
        IF @@ROWCOUNT > 0
        BEGIN
            PRINT 'Account automatically closed 
                    final payment completed!'
        END
    END
END;
-- Let's check if our Trigger worked by setting Bob's payment to zero
-- Step 1: Set Bob's Personal Loan balance to 0
UPDATE Accounts
SET Balance = 0
WHERE AccountID = 5;

-- Step 2: Complete Bob's loan payment
-- This should fire the trigger!
UPDATE Transactions
SET CompletionDate = GETDATE()
WHERE TransactionID = 4;

-- Step 3: Check if account was automatically closed
SELECT AccountID, AccountName, 
       AccountType, AccountStatus,
       ClosureOrFreezeDate
FROM Accounts
WHERE AccountID = 5;

-- Task 5: Find customers who paid less than 50%
-- of their overdue fees
-- Uses subquery to calculate payment percentage
-- Groups by customer to get total per customer
-- HAVING filters to less than 50%
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    COUNT(ovf.OverdueFeeID)        AS NumberOfFees,
    SUM(ovf.TotalOwed)             AS TotalOwed,
    SUM(ovf.TotalRepaid)           AS TotalRepaid,
    SUM(ovf.OutstandingBalance)    AS TotalOutstanding,
    CAST(
        SUM(ovf.TotalRepaid) * 100.0 /
        SUM(ovf.TotalOwed)
    AS DECIMAL(5,2))               AS PercentagePaid
FROM Customers c
INNER JOIN CustomerAccounts ca
    ON c.CustomerID = ca.CustomerID
INNER JOIN Transactions t
    ON ca.CustomerAccountID = t.CustomerAccountID
INNER JOIN OverdueFees ovf
    ON t.TransactionID = ovf.TransactionID
GROUP BY
    c.CustomerID,
    c.FirstName,
    c.LastName
HAVING
    SUM(ovf.TotalRepaid) * 100.0 /
    SUM(ovf.TotalOwed) < 50;

 --- Also let's list the count the customer
  -- Count of customers who paid less than 50%
SELECT COUNT(*) AS CustomersUnder50Percent
FROM (
    SELECT c.CustomerID
    FROM Customers c
    INNER JOIN CustomerAccounts ca
        ON c.CustomerID = ca.CustomerID
    INNER JOIN Transactions t
        ON ca.CustomerAccountID = t.CustomerAccountID
    INNER JOIN OverdueFees ovf
        ON t.TransactionID = ovf.TransactionID
    GROUP BY c.CustomerID
    HAVING SUM(ovf.TotalRepaid) * 100.0 /
           SUM(ovf.TotalOwed) < 50
) AS UnderPayers;

--TASK 7 Bonus Object
-- Bonus 1: View showing total balance
-- for each customer across all accounts
-- Useful for the bank to see customer wealth
CREATE VIEW vw_CustomerAccountSummary
AS
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email,
    COUNT(a.AccountID)      AS TotalAccounts,
    SUM(a.Balance)          AS TotalBalance,
    MIN(a.OpeningDate)      AS OldestAccount,
    MAX(a.OpeningDate)      AS NewestAccount
FROM Customers c
INNER JOIN CustomerAccounts ca
    ON c.CustomerID = ca.CustomerID
INNER JOIN Accounts a
    ON ca.AccountID = a.AccountID
GROUP BY
    c.CustomerID,
    c.FirstName,
    c.LastName,
    c.Email;
-- Bonus 2 UDF to Calculate Outstanding Balance
-- Bonus 2: UDF returning total outstanding
-- overdue balance for a specific customer
-- Useful for credit checks and risk assessment
CREATE FUNCTION dbo.GetCustomerOutstandingBalance
    (@CustomerID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalOutstanding DECIMAL(18,2)

    SELECT @TotalOutstanding = 
        ISNULL(SUM(ovf.OutstandingBalance), 0)
    FROM OverdueFees ovf
    INNER JOIN Transactions t
        ON ovf.TransactionID = t.TransactionID
    INNER JOIN CustomerAccounts ca
        ON t.CustomerAccountID = ca.CustomerAccountID
    WHERE ca.CustomerID = @CustomerID

    RETURN @TotalOutstanding
END;
-- HOW TO CALL BONUS OBJECTS
-- Call Bonus 1 View
SELECT * FROM vw_CustomerAccountSummary
ORDER BY TotalBalance DESC;

-- Call Bonus 2 Function for Bob (CustomerID=9)
SELECT dbo.GetCustomerOutstandingBalance(9) 
AS BobOutstandingBalance;

-- Use function for ALL customers
SELECT
    CustomerID,
    FirstName,
    LastName,
    dbo.GetCustomerOutstandingBalance(CustomerID)
    AS OutstandingBalance
FROM Customers
ORDER BY OutstandingBalance DESC;

-- Let's text all our Functions
-- Test 1a: Search for Savings accounts
EXEC uspSearchAccounts @AccountName = 'Savings';

-- Test 1b: Search for Loan accounts
EXEC uspSearchAccounts @AccountName = 'Loan';

-- Test 1c: Search for something that doesn't exist
EXEC uspSearchAccounts @AccountName = 'Mortgage';

-- Test 2a: Check payments due soon
-- Should show Bob's loan payment due in 3 days
EXEC uspPaymentsDueSoon;

-- Test 3a: Insert a valid new customer
EXEC uspInsertCustomer
    @FirstName    = 'John',
    @LastName     = 'Taylor',
    @DateOfBirth  = '1995-06-20',
    @Username     = 'john.taylor',
    @PasswordHash = 'hashed_pwd_new2',
    @Email        = 'john.taylor@email.com',
    @Telephone    = '07700998877',
    @AddressID    = 3,
    @ClosureDate  = NULL;

-- Test 3b: Try duplicate username
-- Should show error message!
EXEC uspInsertCustomer
    @FirstName    = 'Another',
    @LastName     = 'Person',
    @DateOfBirth  = '1990-01-01',
    @Username     = 'john.taylor',
    @PasswordHash = 'hashed_pwd_x',
    @Email        = 'different@email.com',
    @Telephone    = NULL,
    @AddressID    = 1,
    @ClosureDate  = NULL;

    -- Test 4a: Update Ali's telephone
EXEC uspUpdateCustomer
    @CustomerID = 7,
    @Telephone  = '07711223344';

-- Verify the change
SELECT CustomerID, FirstName, 
       LastName, Telephone
FROM Customers
WHERE CustomerID = 7;

-- Test 4b: Try updating customer that doesn't exist
EXEC uspUpdateCustomer
    @CustomerID = 999,
    @Telephone  = '07700000000';

    -- Test 5a: All transactions
SELECT * FROM vw_TransactionsWithFees;

-- Test 5b: Only overdue
SELECT * FROM vw_TransactionsWithFees
WHERE PaymentStatus = 'Overdue';

-- Test 5c: Only completed
SELECT * FROM vw_TransactionsWithFees
WHERE PaymentStatus = 'Completed';

-- Test 6: Check Personal Loan is closed
SELECT AccountID, AccountName,
       AccountStatus, ClosureOrFreezeDate
FROM Accounts
WHERE AccountType IN ('Loan', 'Credit Card');

-- Test 7a: Customers under 50%
SELECT
    c.CustomerID,
    c.FirstName,
    c.LastName,
    SUM(ovf.TotalOwed)     AS TotalOwed,
    SUM(ovf.TotalRepaid)   AS TotalRepaid,
    CAST(
        SUM(ovf.TotalRepaid) * 100.0 /
        SUM(ovf.TotalOwed)
    AS DECIMAL(5,2))       AS PercentagePaid
FROM Customers c
INNER JOIN CustomerAccounts ca
    ON c.CustomerID = ca.CustomerID
INNER JOIN Transactions t
    ON ca.CustomerAccountID = t.CustomerAccountID
INNER JOIN OverdueFees ovf
    ON t.TransactionID = ovf.TransactionID
GROUP BY c.CustomerID, c.FirstName, c.LastName
HAVING SUM(ovf.TotalRepaid) * 100.0 /
       SUM(ovf.TotalOwed) < 50;

-- Test 7b: Count of those customers
SELECT COUNT(*) AS CustomersUnder50Percent
FROM (
    SELECT c.CustomerID
    FROM Customers c
    INNER JOIN CustomerAccounts ca
        ON c.CustomerID = ca.CustomerID
    INNER JOIN Transactions t
        ON ca.CustomerAccountID = t.CustomerAccountID
    INNER JOIN OverdueFees ovf
        ON t.TransactionID = ovf.TransactionID
    GROUP BY c.CustomerID
    HAVING SUM(ovf.TotalRepaid) * 100.0 /
           SUM(ovf.TotalOwed) < 50
) AS UnderPayers;

-- Test 8a: Customer Account Summary View
SELECT * FROM vw_CustomerAccountSummary
ORDER BY TotalBalance DESC;

-- Test 8b: Outstanding balance for Bob
SELECT dbo.GetCustomerOutstandingBalance(9)
AS BobOutstandingBalance;

-- Test 8c: Outstanding balance for all customers
SELECT
    CustomerID,
    FirstName,
    LastName,
    dbo.GetCustomerOutstandingBalance(CustomerID)
    AS OutstandingBalance
FROM Customers
ORDER BY OutstandingBalance DESC;
SELECT*FROM Repayments
--- Let's backup our database project
BACKUP DATABASE LeedsBankLtd
TO DISK = 'C:\my picture analysis\LeedsBankLtd.bak'
WITH FORMAT,
     NAME = 'LeedsBankLtd Backup';
