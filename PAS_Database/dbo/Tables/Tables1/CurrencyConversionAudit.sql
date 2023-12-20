CREATE TABLE [dbo].[CurrencyConversionAudit] (
    [CurrencyConversionAuditId] INT             IDENTITY (1, 1) NOT NULL,
    [CurrencyConversionId]      INT             NULL,
    [CurrencyTypeId]            INT             NULL,
    [FromCurrencyId]            INT             NULL,
    [ToCurrencyId]              INT             NULL,
    [ConversionRate]            DECIMAL (18, 2) NULL,
    [CurrencyRateDate]          DATETIME        NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_CurrencyConversionAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_CurrencyConversionAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_CurrencyConversionAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_CurrencyConversionAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CurrencyConversionAudit] PRIMARY KEY CLUSTERED ([CurrencyConversionAuditId] ASC)
);

