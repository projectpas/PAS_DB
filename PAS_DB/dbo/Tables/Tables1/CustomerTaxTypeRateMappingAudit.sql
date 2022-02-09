CREATE TABLE [dbo].[CustomerTaxTypeRateMappingAudit] (
    [AuditCustomerTaxTypeRateMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerTaxTypeRateMappingId]      BIGINT        NOT NULL,
    [CustomerId]                        BIGINT        NOT NULL,
    [TaxTypeId]                         TINYINT       NOT NULL,
    [TaxRateId]                         BIGINT        NOT NULL,
    [TaxType]                           VARCHAR (256) NOT NULL,
    [TaxRate]                           VARCHAR (256) NOT NULL,
    [MasterCompanyId]                   INT           NOT NULL,
    [CreatedBy]                         VARCHAR (256) NOT NULL,
    [UpdatedBy]                         VARCHAR (256) NOT NULL,
    [CreatedDate]                       DATETIME2 (7) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7) NOT NULL,
    [IsActive]                          BIT           NOT NULL,
    [IsDeleted]                         BIT           NOT NULL,
    [CustomerFinancialId]               BIGINT        NULL,
    [SiteId]                            BIGINT        NULL,
    [SiteName]                          VARCHAR (50)  NULL,
    CONSTRAINT [PK_CustomerTaxTypeRateMappingAudit] PRIMARY KEY CLUSTERED ([AuditCustomerTaxTypeRateMappingId] ASC),
    CONSTRAINT [FK_CustomerTaxTypeRateMappingAudit_CustomerTaxTypeRateMapping] FOREIGN KEY ([CustomerTaxTypeRateMappingId]) REFERENCES [dbo].[CustomerTaxTypeRateMapping] ([CustomerTaxTypeRateMappingId])
);



