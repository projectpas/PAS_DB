CREATE TABLE [dbo].[CustomerSettingsAudit] (
    [CustomerSettingsAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [Id]                      BIGINT          NOT NULL,
    [LegalEntityId]           BIGINT          NOT NULL,
    [CreditTermsId]           INT             NOT NULL,
    [CreditLimit]             DECIMAL (18, 2) NOT NULL,
    [CurrencyId]              INT             NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             NOT NULL,
    [IsDeleted]               BIT             NOT NULL,
    [LegalEntityName]         VARCHAR (256)   NULL,
    [CreditTerms]             VARCHAR (256)   NULL,
    [Currency]                VARCHAR (256)   NULL,
    CONSTRAINT [PK_CustomerSettingsAudit] PRIMARY KEY CLUSTERED ([CustomerSettingsAuditId] ASC)
);

