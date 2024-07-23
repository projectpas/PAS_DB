CREATE TABLE [dbo].[LegalEntityShippingAudit] (
    [AuditLegalEntityShippingId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [LegalEntityShippingId]        BIGINT         NOT NULL,
    [LegalEntityId]                BIGINT         NOT NULL,
    [LegalEntityShippingAddressId] BIGINT         NOT NULL,
    [ShipVia]                      VARCHAR (400)  NULL,
    [ShippingAccountInfo]          VARCHAR (200)  NULL,
    [Memo]                         NVARCHAR (MAX) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NULL,
    [UpdatedBy]                    VARCHAR (256)  NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            NULL,
    [IsDeleted]                    BIT            NULL,
    [IsPrimary]                    BIT            NULL,
    [ShipViaId]                    BIGINT         NULL,
    [ShippingTermsId]              BIGINT         NULL,
    CONSTRAINT [PK_LegalEntityShippingAudit] PRIMARY KEY CLUSTERED ([AuditLegalEntityShippingId] ASC)
);



