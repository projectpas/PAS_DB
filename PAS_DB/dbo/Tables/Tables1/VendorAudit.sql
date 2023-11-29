﻿CREATE TABLE [dbo].[VendorAudit] (
    [AuditVendorId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorId]                BIGINT          NOT NULL,
    [VendorTypeId]            INT             NOT NULL,
    [VendorName]              VARCHAR (100)   NOT NULL,
    [VendorCode]              VARCHAR (100)   NOT NULL,
    [DoingBusinessAsName]     VARCHAR (50)    NULL,
    [IsParent]                BIT             NOT NULL,
    [VendorParentId]          BIGINT          NULL,
    [VendorPhone]             VARCHAR (256)   NULL,
    [VendorPhoneExt]          VARCHAR (10)    NULL,
    [VendorEmail]             VARCHAR (200)   NULL,
    [AddressId]               BIGINT          NOT NULL,
    [IsAddressForBilling]     BIT             NOT NULL,
    [IsAddressForShipping]    BIT             NOT NULL,
    [IsVendorAlsoCustomer]    BIT             NOT NULL,
    [RelatedCustomerId]       BIGINT          NULL,
    [IsAllowNettingAPAR]      BIT             NOT NULL,
    [VendorContractReference] VARCHAR (30)    NULL,
    [IsPreferredVendor]       BIT             NOT NULL,
    [LicenseNumber]           VARCHAR (30)    NULL,
    [VendorURL]               VARCHAR (50)    NULL,
    [IsCertified]             BIT             NOT NULL,
    [VendorAudit]             BIT             NOT NULL,
    [EDI]                     BIT             NOT NULL,
    [EDIDescription]          VARCHAR (100)   NULL,
    [AeroExchange]            BIT             NOT NULL,
    [AeroExchangeDescription] VARCHAR (100)   NULL,
    [CreditLimit]             DECIMAL (18, 2) NULL,
    [CreditTermsId]           INT             NULL,
    [CurrencyId]              INT             NULL,
    [DiscountId]              BIGINT          NULL,
    [Is1099Required]          BIT             NOT NULL,
    [IsAllow]                 BIT             NOT NULL,
    [IsWarning]               BIT             NOT NULL,
    [IsRestrict]              BIT             NOT NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             NOT NULL,
    [IsDeleted]               BIT             NOT NULL,
    [BillingAddressId]        BIGINT          NULL,
    [ShippingAddressId]       BIGINT          NULL,
    [IsTradeRestricted]       BIT             NULL,
    [TradeRestrictedMemo]     NVARCHAR (MAX)  NULL,
    [IsTrackScoreCard]        BIT             NULL,
    [IsVendorOnHold]          BIT             DEFAULT ((0)) NULL,
    [TaxIdNumber]             NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_VendorAudit] PRIMARY KEY CLUSTERED ([AuditVendorId] ASC),
    CONSTRAINT [FK_VendorAudit_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);









