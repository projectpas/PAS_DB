﻿CREATE TABLE [dbo].[SalesOrderBillingInvoicingAudit] (
    [AuditSOBillingInvoicingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOBillingInvoicingId]      BIGINT          NOT NULL,
    [SalesOrderId]              BIGINT          NOT NULL,
    [InvoiceTypeId]             BIGINT          NOT NULL,
    [InvoiceNo]                 VARCHAR (256)   NOT NULL,
    [CustomerId]                BIGINT          NOT NULL,
    [InvoiceDate]               DATETIME2 (7)   NULL,
    [PrintDate]                 DATETIME2 (7)   NULL,
    [ShipDate]                  DATETIME2 (7)   NULL,
    [EmployeeId]                BIGINT          NOT NULL,
    [RevType]                   VARCHAR (50)    NULL,
    [SoldToCustomerId]          BIGINT          NOT NULL,
    [SoldToSiteId]              BIGINT          NOT NULL,
    [BillToCustomerId]          BIGINT          NOT NULL,
    [BillToSiteId]              BIGINT          NOT NULL,
    [BillToAttention]           VARCHAR (256)   NULL,
    [ShipToCustomerId]          BIGINT          NOT NULL,
    [ShipToSiteId]              BIGINT          NOT NULL,
    [ShipToAttention]           VARCHAR (256)   NULL,
    [IsPartialInvoice]          BIT             NOT NULL,
    [CurrencyId]                INT             NULL,
    [AvailableCredit]           DECIMAL (20, 2) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [InvoiceStatus]             VARCHAR (50)    NULL,
    [InvoiceFilePath]           VARCHAR (200)   NULL,
    [GrandTotal]                DECIMAL (20, 2) NULL,
    [Level1]                    VARCHAR (200)   NULL,
    [Level2]                    VARCHAR (200)   NULL,
    [Level3]                    VARCHAR (200)   NULL,
    [Level4]                    VARCHAR (200)   NULL,
    [SubTotal]                  DECIMAL (20, 2) NULL,
    [TaxRate]                   DECIMAL (20, 2) NULL,
    [SalesTax]                  DECIMAL (20, 2) NULL,
    [OtherTax]                  DECIMAL (20, 2) NULL,
    [MiscCharges]               DECIMAL (20, 2) NULL,
    [Freight]                   DECIMAL (20, 2) NULL,
    [RemainingAmount]           DECIMAL (20, 2) NULL,
    [PostedDate]                DATETIME2 (7)   NULL,
    [Notes]                     NVARCHAR (MAX)  NULL,
    [SalesTotal]                DECIMAL (20, 2) NULL,
    [CreditMemoUsed]            DECIMAL (18, 2) NULL,
    [VersionNo]                 VARCHAR (100)   NULL,
    [IsVersionIncrease]         BIT             NULL,
    [IsProforma]                BIT             NULL,
    [IsBilling]                 BIT             NULL,
    [DepositAmount]             DECIMAL (18, 2) NULL,
    [UsedDeposit]               DECIMAL (18, 2) NULL,
    [BillToUserType]            INT             NULL,
    [ShipToUserType]            INT             NULL,
    [ProformaDeposit]           DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_SalesOrderBillingInvoicingAudit] PRIMARY KEY CLUSTERED ([AuditSOBillingInvoicingId] ASC),
    CONSTRAINT [FK_SalesOrderBillingInvoicingAudit_SalesOrderBillingInvoicing] FOREIGN KEY ([SOBillingInvoicingId]) REFERENCES [dbo].[SalesOrderBillingInvoicing] ([SOBillingInvoicingId])
);











