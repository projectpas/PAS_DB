CREATE TABLE [dbo].[NonPOInvoicePartDetails] (
    [NonPOInvoicePartDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [NonPOInvoiceId]            BIGINT          NOT NULL,
    [EntryDate]                 DATETIME2 (7)   NOT NULL,
    [Amount]                    DECIMAL (18, 2) NULL,
    [CurrencyId]                BIGINT          NULL,
    [FXRate]                    DECIMAL (18, 2) NULL,
    [GlAccountId]               BIGINT          NOT NULL,
    [InvoiceNum]                VARCHAR (256)   NULL,
    [Invoicedate]               DATETIME2 (7)   NULL,
    [ManagementStructureId]     INT             NOT NULL,
    [LastMSLevel]               VARCHAR (200)   NULL,
    [AllMSlevels]               VARCHAR (MAX)   NULL,
    [Memo]                      VARCHAR (500)   NULL,
    [JournalType]               VARCHAR (200)   NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (50)    NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_NonPOInvoicePartDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)    NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_NonPOInvoicePartDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF__NonPOInvoicePartDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF__NonPOInvoicePartDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Item]                      VARCHAR (250)   NULL,
    [Description]               VARCHAR (500)   NULL,
    [UnitOfMeasureId]           BIGINT          NULL,
    [Qty]                       BIGINT          NULL,
    [ExtendedPrice]             DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_NonPOInvoicePartDetails] PRIMARY KEY CLUSTERED ([NonPOInvoicePartDetailsId] ASC)
);



