CREATE TABLE [dbo].[LegalEntityInterShipViaDetailsAudit] (
    [AuditShippingViaDetailsId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingViaDetailsId]               BIGINT         NOT NULL,
    [LegalEntityInternationalShippingId] BIGINT         NOT NULL,
    [LegalEntityId]                      BIGINT         NOT NULL,
    [ShippingAccountInfo]                VARCHAR (200)  NULL,
    [Memo]                               NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NULL,
    [UpdatedBy]                          VARCHAR (256)  NULL,
    [CreatedDate]                        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  NOT NULL,
    [IsActive]                           BIT            NULL,
    [IsDeleted]                          BIT            NULL,
    [IsPrimary]                          BIT            NULL,
    [ShipViaId]                          BIGINT         NULL,
    CONSTRAINT [PK_LegalEntityInterShipViaDetailsAudit] PRIMARY KEY CLUSTERED ([AuditShippingViaDetailsId] ASC)
);

