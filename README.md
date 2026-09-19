# LeedsBankLtd — Relational Database Design (SQL Server)

A complete relational database system for a fictional online banking platform, designed and implemented from first principles as part of my MSc Data Science coursework. Built in Microsoft SQL Server Management Studio using T-SQL, normalised to Third Normal Form (3NF), with stored procedures, views, a trigger and a user-defined function automating core banking operations.

---

## Project Brief

Acting as the appointed database consultant, the objective was to design a robust, secure and efficient database capable of managing customer information, bank accounts and products, transactions, overdue fees and repayment records for a bank processing hundreds of transactions daily.

## Database Design

**7 normalised tables**, each serving a single, well-defined purpose:

| Table | Purpose |
|---|---|
| Addresses | Customer address details, separated out to satisfy 3NF |
| Customers | Personal customer information |
| Accounts | Bank products and account details (Savings, Checking, Loan, Credit Card, Investment) |
| CustomerAccounts | Linking table resolving the many-to-many relationship between customers and accounts |
| Transactions | Every financial movement in the system |
| OverdueFees | Late payment charges linked to transactions |
| Repayments | Payments made towards overdue fees |

### Normalisation

The database was normalised through 1NF, 2NF and 3NF. The key 3NF decision was separating address data into its own table, removing a transitive dependency (Postcode → City) that would otherwise have existed directly inside the Customers table.
## Database Objects

- **4 stored procedures**: `uspSearchAccounts` (partial-match account search), `uspPaymentsDueSoon` (upcoming payment monitoring using `GETDATE()` and `DATEDIFF`), `uspInsertCustomer` (validated customer creation, checking for duplicate usernames/emails before insert), `uspUpdateCustomer` (selective field updates using `ISNULL`, so unchanged fields are never overwritten)
- **2 views**: `vw_TransactionsWithFees` (joins 5 tables, auto-labels each transaction as Overdue/Pending/Completed via a `CASE` statement), `vw_CustomerAccountSummary` (per-customer balance and account count for credit assessment)
- **1 trigger**: `trg_CloseAccountOnFinalPayment` — automatically closes a Loan or Credit Card account when its final payment brings the balance to zero
- **1 scalar function**: `GetCustomerOutstandingBalance` — returns a customer's total outstanding overdue balance for risk assessment

## Notable Query

A `SELECT` query identifying customers who have repaid less than 50% of their total overdue fees, using `INNER JOIN` across 4 tables, `GROUP BY`, and a `HAVING` clause to filter the aggregated result, one of the more advanced analytical queries in the project.

## Governance, Security & Resilience

Beyond the schema itself, the project includes a full design brief covering:
- **Data integrity & concurrency**: entity/referential/domain integrity via keys and `CHECK` constraints; `READ COMMITTED` isolation to prevent dirty reads; ACID compliance for financial transactions
- **Security**: role-based access control design (Teller / Branch Manager / Senior Admin), password hashing (`NVARCHAR(256)`, never plain text), parameterised stored procedures to eliminate SQL injection risk, UK GDPR considerations
- **Backup & recovery**: a three-tier backup schedule (full weekly, differential nightly, transaction log hourly) designed to meet a stated recovery requirement of under one hour, following the 3-2-1 backup rule

---

## Author

**Abdulahi Oladiti** — MSc Data Science, University of Salford
[LinkedIn](https://www.linkedin.com/in/oladiti-abdulahi-6925311a9/)
