CREATE TABLE [dbo].[LegalEntityInternationalShippingAudit] (
    [LegalEntityInternationalShippingAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [InternationalShippingId]                 BIGINT          NOT NULL,
    [LegalEntityId]                           BIGINT          NOT NULL,
    [ExportLicense]                           VARCHAR (200)   NULL,
    [StartDate]                               DATETIME        NULL,
    [Amount]                                  DECIMAL (18, 3) NULL,
    [IsPrimary]                               BIT             NULL,
    [Description]                             VARCHAR (250)   NULL,
    [ExpirationDate]                          DATETIME        NULL,
    [ShipToCountryId]                         BIGINT          NOT NULL,
    [MasterCompanyId]                         INT             NOT NULL,
    [CreatedBy]                               VARCHAR (256)   NULL,
    [UpdatedBy]                               VARCHAR (256)   NULL,
    [CreatedDate]                             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                             DATETIME2 (7)   NOT NULL,
    [IsActive]                                BIT             NULL,
    [IsDeleted]                               BIT             NULL,
    CONSTRAINT [PK_LegalEntityInternationalShippingAudit] PRIMARY KEY CLUSTERED ([LegalEntityInternationalShippingAuditId] ASC)
);

