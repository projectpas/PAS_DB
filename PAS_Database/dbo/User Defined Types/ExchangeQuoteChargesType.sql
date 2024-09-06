﻿CREATE TYPE [dbo].[ExchangeQuoteChargesType] AS TABLE (
    [ExchangeQuoteChargesId]   BIGINT          NULL,
    [ExchangeQuoteId]          BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 INT             NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [BillingMethodId]          INT             NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NULL,
    [ExtendedCost]             DECIMAL (20, 2) NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [MasterCompanyId]          INT             NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   NULL,
    [UpdatedDate]              DATETIME2 (7)   NULL,
    [IsActive]                 BIT             NULL,
    [IsDeleted]                BIT             NULL);

