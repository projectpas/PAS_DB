﻿CREATE TYPE [dbo].[NonPOInvoicePartDetailsType] AS TABLE (
    [NonPOInvoicePartDetailsId] BIGINT          NULL,
    [NonPOInvoiceId]            BIGINT          NULL,
    [EntryDate]                 DATETIME2 (7)   NULL,
    [Amount]                    DECIMAL (18, 2) NULL,
    [CurrencyId]                BIGINT          NULL,
    [FXRate]                    DECIMAL (18, 2) NULL,
    [GlAccountId]               BIGINT          NULL,
    [InvoiceNum]                VARCHAR (256)   NULL,
    [Invoicedate]               DATETIME2 (7)   NULL,
    [ManagementStructureId]     INT             NULL,
    [LastMSLevel]               VARCHAR (200)   NULL,
    [AllMSlevels]               VARCHAR (MAX)   NULL,
    [Memo]                      VARCHAR (500)   NULL,
    [JournalType]               VARCHAR (200)   NULL,
    [MasterCompanyId]           INT             NULL,
    [CreatedBy]                 VARCHAR (50)    NULL,
    [UpdatedBy]                 VARCHAR (50)    NULL,
    [IsDeleted]                 BIT             NULL,
    [Item]                      VARCHAR (250)   NULL,
    [Description]               VARCHAR (500)   NULL,
    [UnitOfMeasureId]           BIGINT          NULL,
    [Qty]                       BIGINT          NULL,
    [ExtendedPrice]             DECIMAL (18, 2) NULL,
    [TaxTypeId]                 BIGINT          NULL);



