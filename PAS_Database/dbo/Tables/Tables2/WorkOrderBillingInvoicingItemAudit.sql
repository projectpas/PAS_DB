﻿CREATE TABLE [dbo].[WorkOrderBillingInvoicingItemAudit] (
    [AuditWOBillingInvoicingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WOBillingInvoicingItemId]      BIGINT          NOT NULL,
    [WOBillingInvoicingId]          BIGINT          NOT NULL,
    [NoofPieces]                    INT             NOT NULL,
    [WorkOrderPartId]               BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [UnitPrice]                     DECIMAL (20, 2) NULL,
    [SubTotal]                      DECIMAL (20, 2) NULL,
    [TaxRate]                       DECIMAL (20, 2) NULL,
    [SalesTax]                      DECIMAL (20, 2) NULL,
    [OtherTax]                      DECIMAL (20, 2) NULL,
    [MiscCharges]                   DECIMAL (20, 2) NULL,
    [Freight]                       DECIMAL (20, 2) NULL,
    [PDFPath]                       NVARCHAR (MAX)  NULL,
    [VersionNo]                     VARCHAR (20)    NULL,
    [IsVersionIncrease]             BIT             NULL,
    [IsPerformaInvoice]             BIT             NULL,
    [IsInvoicePosted]               BIT             NULL,
    [MaterialCost]                  DECIMAL (18, 2) NULL,
    [LaborCost]                     DECIMAL (18, 2) NULL,
    [OtherTaxRate]                  DECIMAL (18, 2) NULL,
    [GrandTotal]                    DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_WorkOrderBillingInvoicingItemAudit] PRIMARY KEY CLUSTERED ([AuditWOBillingInvoicingItemId] ASC)
);







