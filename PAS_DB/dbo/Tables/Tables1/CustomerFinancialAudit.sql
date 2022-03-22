﻿CREATE TABLE [dbo].[CustomerFinancialAudit] (
    [CustomerFinancialAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerFinancialId]      BIGINT          NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [MarkUpPercentageId]       BIGINT          NULL,
    [DiscountId]               BIGINT          NULL,
    [CreditLimit]              DECIMAL (18, 2) NOT NULL,
    [CreditTermsId]            INT             NOT NULL,
    [CurrencyId]               INT             NOT NULL,
    [AllowNettingOfAPAR]       BIT             NOT NULL,
    [AllowPartialBilling]      BIT             NOT NULL,
    [AllowProformaBilling]     BIT             NOT NULL,
    [IsTaxExempt]              BIT             NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             NOT NULL,
    [IsDeleted]                BIT             NOT NULL,
    CONSTRAINT [PK_CustomerFinancialAudit] PRIMARY KEY CLUSTERED ([CustomerFinancialAuditId] ASC),
    CONSTRAINT [FK_CustomerFinancialAudit_CustomerFinancial] FOREIGN KEY ([CustomerFinancialId]) REFERENCES [dbo].[CustomerFinancial] ([CustomerFinancialId])
);

