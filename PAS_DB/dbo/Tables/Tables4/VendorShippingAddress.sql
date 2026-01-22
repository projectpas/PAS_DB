CREATE TABLE [dbo].[VendorShippingAddress] (
    [VendorShippingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                BIGINT        NOT NULL,
    [AddressId]               BIGINT        NOT NULL,
    [IsPrimary]               BIT           CONSTRAINT [DF__VendorShi__IsPri__5A45429A] DEFAULT ((0)) NOT NULL,
    [SiteName]                VARCHAR (100) NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [VendorShippingAddress_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [VendorShippingAddress_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [VendorShippingAddress_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [VendorShippingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ContactTagId]            BIGINT        NULL,
    [Attention]               VARCHAR (250) NULL,
    CONSTRAINT [PK_VendorShippingAddress] PRIMARY KEY CLUSTERED ([VendorShippingAddressId] ASC),
    CONSTRAINT [FK_VendorShippingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_VendorShippingAddress_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_VendorShippingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorShippingAddress_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorShippingAddressAudit]

   ON  [dbo].[VendorShippingAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorShippingAddressAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END