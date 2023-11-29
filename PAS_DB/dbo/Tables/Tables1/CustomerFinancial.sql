CREATE TABLE [dbo].[CustomerFinancial] (
    [CustomerFinancialId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]           BIGINT          NOT NULL,
    [MarkUpPercentageId]   BIGINT          NULL,
    [DiscountId]           BIGINT          NULL,
    [CreditLimit]          DECIMAL (18, 2) NOT NULL,
    [CreditTermsId]        INT             NOT NULL,
    [CurrencyId]           INT             NOT NULL,
    [AllowNettingOfAPAR]   BIT             CONSTRAINT [CustomerFinancial_AllowNettingOfAPAR] DEFAULT ((0)) NOT NULL,
    [AllowPartialBilling]  BIT             CONSTRAINT [CustomerFinancial_AllowPartialBilling] DEFAULT ((0)) NOT NULL,
    [AllowProformaBilling] BIT             CONSTRAINT [CustomerFinancial_AllowProformaBilling] DEFAULT ((0)) NOT NULL,
    [IsTaxExempt]          BIT             CONSTRAINT [CustomerFinancial_IsTaxExempt] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]      INT             CONSTRAINT [CustomerFinancial_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]            VARCHAR (256)   CONSTRAINT [CustomerFinancial_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]            VARCHAR (256)   CONSTRAINT [CustomerFinancial_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [CustomerFinancial_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [CustomerFinancial_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [CustomerFinancial_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [CustomerFinancial_Delete] DEFAULT ((0)) NOT NULL,
    [IsCustomerSetting]    BIT             NULL,
    CONSTRAINT [PK_CustomerFinancial] PRIMARY KEY CLUSTERED ([CustomerFinancialId] ASC),
    CONSTRAINT [FK_CustomerFinancial_CreditTerms] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_CustomerFinancial_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_CustomerFinancial_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerFinancial_Discount] FOREIGN KEY ([DiscountId]) REFERENCES [dbo].[Discount] ([DiscountId]),
    CONSTRAINT [FK_CustomerFinancial_MarkUppercentage] FOREIGN KEY ([MarkUpPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_CustomerFinancial_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_CustomerFinancial_CustomerId] UNIQUE NONCLUSTERED ([CustomerId] ASC)
);




GO




CREATE TRIGGER [dbo].[Trg_CustomerFinancialAudit]

   ON  [dbo].[CustomerFinancial]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO CustomerFinancialAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END