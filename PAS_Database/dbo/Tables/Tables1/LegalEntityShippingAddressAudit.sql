CREATE TABLE [dbo].[LegalEntityShippingAddressAudit] (
    [AuditLegalEntityShippingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityShippingAddressId]      BIGINT        NOT NULL,
    [LegalEntityId]                     BIGINT        NOT NULL,
    [AddressId]                         BIGINT        NOT NULL,
    [SiteName]                          VARCHAR (256) NULL,
    [IsPrimary]                         BIT           NOT NULL,
    [MasterCompanyId]                   INT           NOT NULL,
    [CreatedBy]                         VARCHAR (256) NOT NULL,
    [UpdatedBy]                         VARCHAR (256) NOT NULL,
    [CreatedDate]                       DATETIME2 (7) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7) NOT NULL,
    [IsActive]                          BIT           NOT NULL,
    [IsDeleted]                         BIT           NOT NULL,
    [Attention]                         VARCHAR (100) NULL,
    [TagName]                           VARCHAR (250) NULL,
    [ContactTagId]                      BIGINT        NULL,
    CONSTRAINT [PK_LegalEntityShippingAddressAudit] PRIMARY KEY CLUSTERED ([AuditLegalEntityShippingAddressId] ASC)
);

