CREATE TABLE [dbo].[CustomerInternationalShippingAudit] (
    [CustomerInternationalShippingAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerInternationalShippingId]      BIGINT          NOT NULL,
    [CustomerId]                           BIGINT          NOT NULL,
    [ExportLicense]                        VARCHAR (200)   NULL,
    [StartDate]                            DATETIME        NULL,
    [Amount]                               DECIMAL (18, 3) NULL,
    [IsPrimary]                            BIT             NOT NULL,
    [Description]                          NVARCHAR (500)  NULL,
    [ExpirationDate]                       DATETIME        NULL,
    [ShipToCountryId]                      BIGINT          NOT NULL,
    [MasterCompanyId]                      INT             NOT NULL,
    [CreatedBy]                            VARCHAR (256)   NOT NULL,
    [UpdatedBy]                            VARCHAR (256)   NOT NULL,
    [CreatedDate]                          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                          DATETIME2 (7)   NOT NULL,
    [IsActive]                             BIT             CONSTRAINT [CustomerInternationalShippingAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                            BIT             CONSTRAINT [CustomerInternationalShippingAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InternationalShippingAudit] PRIMARY KEY CLUSTERED ([CustomerInternationalShippingAuditId] ASC),
    CONSTRAINT [FK_CustomerInternationalShippingAudit_CustomerInternationalShipping] FOREIGN KEY ([CustomerInternationalShippingId]) REFERENCES [dbo].[CustomerInternationalShipping] ([CustomerInternationalShippingId])
);

