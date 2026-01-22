CREATE TABLE [dbo].[VendorInternationalShipping] (
    [VendorInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorId]                      BIGINT          NOT NULL,
    [ExportLicense]                 VARCHAR (200)   NULL,
    [StartDate]                     DATETIME2 (7)   NULL,
    [Amount]                        DECIMAL (18, 3) NULL,
    [IsPrimary]                     BIT             NOT NULL,
    [Description]                   VARCHAR (250)   NULL,
    [ExpirationDate]                DATETIME        NULL,
    [ShipToCountryId]               SMALLINT        NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NULL,
    [UpdatedBy]                     VARCHAR (256)   NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [VendorInternationalShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [ VendorInternationalShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorInternationalShipping] PRIMARY KEY CLUSTERED ([VendorInternationalShippingId] ASC),
    CONSTRAINT [FK_VendorInternationalShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorInternationalShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_VendorInternationalShipping_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorInternationalShippingDelete]

   ON  [dbo].[VendorInternationalShipping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_VendorInternationalShippingAudit]

   ON  [dbo].[VendorInternationalShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END