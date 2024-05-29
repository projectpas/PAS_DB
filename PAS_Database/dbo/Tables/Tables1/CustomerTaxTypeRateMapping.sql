CREATE TABLE [dbo].[CustomerTaxTypeRateMapping] (
    [CustomerTaxTypeRateMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                   BIGINT        NOT NULL,
    [TaxTypeId]                    TINYINT       NOT NULL,
    [TaxRateId]                    BIGINT        NULL,
    [TaxType]                      VARCHAR (256) NOT NULL,
    [TaxRate]                      VARCHAR (256) NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CustomerTaxTypeRateMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CustomerTaxTypeRateMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [D_CTM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [CustomerTaxTypeRateMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CustomerFinancialId]          BIGINT        NULL,
    [SiteId]                       BIGINT        NULL,
    [SiteName]                     VARCHAR (50)  NULL,
    [ShipFromSiteId]               BIGINT        NULL,
    [ShipFromSiteName]             VARCHAR (50)  NULL,
    [IsRepair]                     BIT           NULL,
    [IsProductSale]                BIT           NULL,
    [IsTaxExempt]                  BIT           NULL,
    [TaxId]                        BIGINT        NULL,
    CONSTRAINT [PK_CTTRMapping] PRIMARY KEY CLUSTERED ([CustomerTaxTypeRateMappingId] ASC),
    CONSTRAINT [FK_CustomerTaxTypeRateMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerTaxTypeRateMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CustomerIdTaxTypeRate] UNIQUE NONCLUSTERED ([CustomerId] ASC, [TaxRateId] ASC, [TaxTypeId] ASC, [SiteId] ASC, [ShipFromSiteId] ASC, [MasterCompanyId] ASC)
);










GO


CREATE TRIGGER [dbo].[Trg_CustomerTaxTypeRateMappingDelete]

   ON  [dbo].[CustomerTaxTypeRateMapping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerTaxTypeRateMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_CustomerTaxTypeRateMappingAudit]

   ON  [dbo].[CustomerTaxTypeRateMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerTaxTypeRateMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END