﻿CREATE TABLE [dbo].[LegalEntityAudit] (
    [LegalEntityAuditId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]           BIGINT        NOT NULL,
    [Name]                    VARCHAR (100) NULL,
    [DoingLegalAs]            VARCHAR (50)  NULL,
    [AddressId]               BIGINT        NULL,
    [PhoneNumber]             VARCHAR (30)  NULL,
    [FaxNumber]               VARCHAR (30)  NULL,
    [FunctionalCurrencyId]    INT           NULL,
    [ReportingCurrencyId]     INT           NULL,
    [IsBalancingEntity]       BIT           NULL,
    [CageCode]                VARCHAR (50)  NULL,
    [FAALicense]              VARCHAR (50)  NULL,
    [TaxId]                   VARCHAR (100) NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NULL,
    [UpdatedBy]               VARCHAR (256) NULL,
    [CreatedDate]             DATETIME2 (7) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) NOT NULL,
    [IsActive]                BIT           NULL,
    [IsDeleted]               BIT           NULL,
    [CompanyCode]             VARCHAR (256) NULL,
    [InvoiceAddressPosition]  INT           NULL,
    [InvoiceFaxPhonePosition] INT           NULL,
    [LastLevel]               BIT           DEFAULT ((0)) NOT NULL,
    [PhoneExt]                VARCHAR (20)  NULL,
    [AttachmentId]            BIGINT        NULL,
    [CompanyName]             VARCHAR (256) NULL,
    [IsAddressForBilling]     BIT           NULL,
    [IsAddressForShipping]    BIT           NULL,
    [LedgerId]                BIGINT        NULL,
    [TagName]                 VARCHAR (250) NULL,
    [BillingAddressId]        BIGINT        NULL,
    [ShippingAddressId]       BIGINT        NULL,
    [EASALicense]             VARCHAR (100) NULL,
    [CAACLicense]             VARCHAR (100) NULL,
    [TCCALicense]             VARCHAR (100) NULL,
    [TimeZoneId]              BIGINT        NULL,
    [IsPrintCheckNumber]      BIT           NULL,
    [IsTurnOffMgmt]           BIT           NULL,
    [CurrencyFormatId]        BIGINT        NULL,
    [DecimalPrecisionId]      BIGINT        NULL,
    [ShortDateTimeFormatId]   BIGINT        NULL,
    [LongDateTimeFormatId]    BIGINT        NULL,
    [TextTransformId]         BIGINT        NULL,
    [EnableLockScreen]        BIT           NULL,
    [TimeoutInMinutes]        INT           NULL,
    [UKCAALicense]            VARCHAR (200) NULL,
    CONSTRAINT [PK_LegalEntityAudit] PRIMARY KEY CLUSTERED ([LegalEntityAuditId] ASC)
);









