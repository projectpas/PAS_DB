CREATE TABLE [dbo].[VendorInternationalShipViaDetails] (
    [VendorInternationalShipViaDetailsId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorInternationalShippingId]       BIGINT         NOT NULL,
    [ShipVia]                             VARCHAR (400)  NULL,
    [ShippingAccountInfo]                 VARCHAR (200)  NULL,
    [Memo]                                NVARCHAR (MAX) NULL,
    [MasterCompanyId]                     INT            NOT NULL,
    [IsPrimary]                           BIT            NOT NULL,
    [CreatedBy]                           VARCHAR (256)  NOT NULL,
    [UpdatedBy]                           VARCHAR (256)  NOT NULL,
    [CreatedDate]                         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)  NOT NULL,
    [IsActive]                            BIT            CONSTRAINT [VendorInternationalShipViaDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT            CONSTRAINT [ VendorInternationalShipViaDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ShipViaId]                           BIGINT         NULL,
    CONSTRAINT [PK_VendorInternationalShipViaDetails] PRIMARY KEY CLUSTERED ([VendorInternationalShipViaDetailsId] ASC),
    CONSTRAINT [FK_VendorInternationalShipViaDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorInternationalShipViaDetails_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_VendorInternationalShipViaDetails_VendorInternationalShipping] FOREIGN KEY ([VendorInternationalShippingId]) REFERENCES [dbo].[VendorInternationalShipping] ([VendorInternationalShippingId]),
    CONSTRAINT [Unique_VendorInternationalShipViaDetails] UNIQUE NONCLUSTERED ([VendorInternationalShippingId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_VendorInternationalShipViaDetailsAudit]

   ON  [dbo].[VendorInternationalShipViaDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShipViaDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO






CREATE TRIGGER [dbo].[Trg_VendorInternationalShipViaDetailsDelete]

   ON  [dbo].[VendorInternationalShipViaDetails]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShipViaDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END