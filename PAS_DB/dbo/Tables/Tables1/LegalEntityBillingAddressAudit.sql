CREATE TABLE [dbo].[LegalEntityBillingAddressAudit] (
    [LegalEntityBillingAddressAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityBillingAddressId]      BIGINT        NOT NULL,
    [LegalEntityId]                    BIGINT        NOT NULL,
    [AddressId]                        BIGINT        NOT NULL,
    [IsPrimary]                        BIT           NOT NULL,
    [SiteName]                         VARCHAR (256) NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NULL,
    [UpdatedBy]                        VARCHAR (256) NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    [IsActive]                         BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT           DEFAULT ((0)) NOT NULL,
    [Attention]                        VARCHAR (100) NULL,
    CONSTRAINT [PK_LegalEntityBillingAddressAudit] PRIMARY KEY CLUSTERED ([LegalEntityBillingAddressAuditId] ASC)
);

