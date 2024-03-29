﻿CREATE TABLE [dbo].[SalesOrderQuoteChargesAudit] (
    [AuditSalesOrderQuoteChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteChargesId]      BIGINT          NOT NULL,
    [SalesOrderQuoteId]             BIGINT          NOT NULL,
    [SalesOrderQuotePartId]         BIGINT          NULL,
    [ChargesTypeId]                 BIGINT          NULL,
    [VendorId]                      BIGINT          NULL,
    [Quantity]                      INT             NULL,
    [MarkupPercentageId]            BIGINT          NULL,
    [Description]                   VARCHAR (256)   NULL,
    [UnitCost]                      DECIMAL (20, 2) NULL,
    [ExtendedCost]                  DECIMAL (20, 2) NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [MarkupFixedPrice]              DECIMAL (20, 2) NULL,
    [BillingMethodId]               INT             NULL,
    [BillingAmount]                 DECIMAL (20, 2) NULL,
    [BillingRate]                   DECIMAL (20, 2) NULL,
    [HeaderMarkupId]                BIGINT          NULL,
    [RefNum]                        VARCHAR (20)    NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [HeaderMarkupPercentageId]      BIGINT          NULL,
    [VendorName]                    NVARCHAR (100)  NULL,
    [ChargeName]                    NVARCHAR (100)  NULL,
    [MarkupName]                    NVARCHAR (100)  NULL,
    [ItemMasterId]                  BIGINT          NULL,
    [ConditionId]                   BIGINT          NULL,
    [UnitOfMeasureId]               BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuoteChargesAudit] PRIMARY KEY CLUSTERED ([AuditSalesOrderQuoteChargesId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteCharges_SalesOrderQuoteChargesAudit] FOREIGN KEY ([SalesOrderQuoteChargesId]) REFERENCES [dbo].[SalesOrderQuoteCharges] ([SalesOrderQuoteChargesId])
);







