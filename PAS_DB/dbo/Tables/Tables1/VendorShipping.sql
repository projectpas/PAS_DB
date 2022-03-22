CREATE TABLE [dbo].[VendorShipping] (
    [VendorShippingId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorId]                BIGINT         NOT NULL,
    [IsPrimary]               BIT            CONSTRAINT [VendorShipping_DC_IsPrimary] DEFAULT ((0)) NOT NULL,
    [VendorShippingAddressId] BIGINT         NOT NULL,
    [ShipVia]                 VARCHAR (30)   NULL,
    [ShippingAccountInfo]     VARCHAR (200)  NULL,
    [ShippingId]              VARCHAR (50)   NULL,
    [ShippingURL]             VARCHAR (50)   NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [VendorShipping_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [VendorShipping_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [VendorShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [VendorShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ShipViaId]               BIGINT         NULL,
    CONSTRAINT [PK_VendorShipping] PRIMARY KEY CLUSTERED ([VendorShippingId] ASC),
    CONSTRAINT [FK_VendorShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorShipping_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_VendorShipping_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorShipping_VendorShippingAddress] FOREIGN KEY ([VendorShippingAddressId]) REFERENCES [dbo].[VendorShippingAddress] ([VendorShippingAddressId]),
    CONSTRAINT [Unique_VendorShipping] UNIQUE NONCLUSTERED ([VendorId] ASC, [VendorShippingAddressId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);


GO


-----------------------------------------

CREATE TRIGGER [dbo].[Trg_VendorShippingAudit]

   ON  [dbo].[VendorShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END