CREATE TABLE [dbo].[Vendor] (
    [VendorId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorTypeId]            INT             NOT NULL,
    [VendorName]              VARCHAR (100)   NOT NULL,
    [VendorCode]              VARCHAR (100)   NOT NULL,
    [DoingBusinessAsName]     VARCHAR (50)    NULL,
    [IsParent]                BIT             CONSTRAINT [DF_Vendor_IsParent] DEFAULT ((0)) NOT NULL,
    [VendorParentId]          BIGINT          NULL,
    [VendorPhone]             VARCHAR (256)   NULL,
    [VendorPhoneExt]          VARCHAR (10)    NULL,
    [VendorEmail]             VARCHAR (200)   NULL,
    [AddressId]               BIGINT          NOT NULL,
    [IsAddressForBilling]     BIT             CONSTRAINT [Vendor_DC_IsAddressForBilling] DEFAULT ((0)) NOT NULL,
    [IsAddressForShipping]    BIT             CONSTRAINT [Vendor_DC_IsAddressForShipping] DEFAULT ((0)) NOT NULL,
    [IsVendorAlsoCustomer]    BIT             CONSTRAINT [Vendor_DC_IsVendorAlsoCustomer] DEFAULT ((0)) NOT NULL,
    [RelatedCustomerId]       BIGINT          NULL,
    [IsAllowNettingAPAR]      BIT             CONSTRAINT [DF__Vendor__IsAllowN__54AC64D5] DEFAULT ((0)) NOT NULL,
    [VendorContractReference] VARCHAR (30)    NULL,
    [IsPreferredVendor]       BIT             CONSTRAINT [Vendor_DC_IsPreferredVendor] DEFAULT ((0)) NOT NULL,
    [LicenseNumber]           VARCHAR (30)    NULL,
    [VendorURL]               VARCHAR (100)   NULL,
    [IsCertified]             BIT             CONSTRAINT [Vendor_DC_IsCertified] DEFAULT ((0)) NOT NULL,
    [VendorAudit]             BIT             CONSTRAINT [Vendor_DC_VendorAudit] DEFAULT ((0)) NOT NULL,
    [EDI]                     BIT             CONSTRAINT [Vendor_DC_EDI] DEFAULT ((0)) NOT NULL,
    [EDIDescription]          VARCHAR (100)   NULL,
    [AeroExchange]            BIT             CONSTRAINT [Vendor_DC_AeroExchange] DEFAULT ((0)) NOT NULL,
    [AeroExchangeDescription] VARCHAR (100)   NULL,
    [CreditLimit]             DECIMAL (18, 2) NULL,
    [CreditTermsId]           INT             NULL,
    [CurrencyId]              INT             NULL,
    [DiscountId]              BIGINT          NULL,
    [Is1099Required]          BIT             NOT NULL,
    [IsAllow]                 BIT             CONSTRAINT [DF__Vendor__IsAllow__7A3EA78E] DEFAULT ((0)) NOT NULL,
    [IsWarning]               BIT             CONSTRAINT [DF__Vendor__IsWarnin__794A8355] DEFAULT ((0)) NOT NULL,
    [IsRestrict]              BIT             CONSTRAINT [DF__Vendor__IsRestri__78565F1C] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [Vendor_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [Vendor_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [Vendor_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [Vendor_DC_Delete] DEFAULT ((0)) NOT NULL,
    [BillingAddressId]        BIGINT          NULL,
    [ShippingAddressId]       BIGINT          NULL,
    [IsTradeRestricted]       BIT             NULL,
    [TradeRestrictedMemo]     NVARCHAR (MAX)  NULL,
    [IsTrackScoreCard]        BIT             NULL,
    [IsVendorOnHold]          BIT             DEFAULT ((0)) NULL,
    [TaxIdNumber]             NVARCHAR (MAX)  NULL,
    [QuickBooksVendorId]      BIGINT          NULL,
    [IsUpdated]               BIT             NULL,
    [LastSyncDate]            DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Vendor] PRIMARY KEY CLUSTERED ([VendorId] ASC),
    CONSTRAINT [FK_Vendor_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_Vendor_CreditTerms] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_Vendor_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_Vendor_Customer] FOREIGN KEY ([RelatedCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_Vendor_Discount] FOREIGN KEY ([DiscountId]) REFERENCES [dbo].[Discount] ([DiscountId]),
    CONSTRAINT [FK_Vendor_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_Vendor_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Vendor_Vendor] FOREIGN KEY ([VendorParentId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_Vendor_VendorType] FOREIGN KEY ([VendorTypeId]) REFERENCES [dbo].[VendorType] ([VendorTypeId]),
    CONSTRAINT [UC_Vendor_Email] UNIQUE NONCLUSTERED ([VendorEmail] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_VendorCode] UNIQUE NONCLUSTERED ([VendorCode] ASC, [MasterCompanyId] ASC)
);






GO


CREATE TRIGGER [dbo].[Trg_VendorAudit]

   ON  [dbo].[Vendor]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[VendorAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END