CREATE TABLE [dbo].[VendorBillingAddress] (
    [VendorBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]               BIGINT        NOT NULL,
    [AddressId]              BIGINT        NOT NULL,
    [IsPrimary]              BIT           CONSTRAINT [VendorBillingAddress_DC_IsPrimary] DEFAULT ((0)) NOT NULL,
    [SiteName]               VARCHAR (100) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [VendorBillingAddress_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [VendorBillingAddress_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [VendorBillingAddress_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [VendorBillingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsAddressForPayment]    BIT           CONSTRAINT [VendorBillingAddress_DC_IsAddressForPayment] DEFAULT ((0)) NULL,
    [ContactTagId]           BIGINT        NULL,
    [Attention]              VARCHAR (250) NULL,
    CONSTRAINT [PK_VendorBillingAddress] PRIMARY KEY CLUSTERED ([VendorBillingAddressId] ASC),
    CONSTRAINT [FK_VendorBillingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_VendorBillingAddress_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_VendorBillingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorBillingAddress_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO




CREATE TRIGGER [dbo].[Trg_VendorBillingAddressAudit]

   ON  [dbo].[VendorBillingAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorBillingAddressAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END