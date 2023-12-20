CREATE TABLE [dbo].[CurrencyConversion] (
    [CurrencyConversionId] INT             IDENTITY (1, 1) NOT NULL,
    [CurrencyTypeId]       INT             NULL,
    [FromCurrencyId]       INT             NULL,
    [ToCurrencyId]         INT             NULL,
    [ConversionRate]       DECIMAL (18, 2) NULL,
    [CurrencyRateDate]     DATETIME        NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_CurrencyConversion_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_CurrencyConversion_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [DF_CurrencyConversion_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_CurrencyConversion_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CurrencyConversion] PRIMARY KEY CLUSTERED ([CurrencyConversionId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_CurrencyConversionAudit]

   ON  [dbo].[CurrencyConversion]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CurrencyConversionAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END