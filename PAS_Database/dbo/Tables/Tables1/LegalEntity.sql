CREATE TABLE [dbo].[LegalEntity] (
    [LegalEntityId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                    VARCHAR (100) NOT NULL,
    [DoingLegalAs]            VARCHAR (50)  NULL,
    [AddressId]               BIGINT        NOT NULL,
    [PhoneNumber]             VARCHAR (30)  NOT NULL,
    [FaxNumber]               VARCHAR (30)  NULL,
    [FunctionalCurrencyId]    INT           NOT NULL,
    [ReportingCurrencyId]     INT           NOT NULL,
    [IsBalancingEntity]       BIT           CONSTRAINT [CONSTRAINT_LegalEntity_IsBalancingEntity] DEFAULT ((1)) NOT NULL,
    [CageCode]                VARCHAR (50)  NULL,
    [FAALicense]              VARCHAR (50)  NULL,
    [TaxId]                   VARCHAR (100) NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_legalentity_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_legalentity_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [LegalEntity_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [LegalEntity_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CompanyCode]             VARCHAR (256) NOT NULL,
    [InvoiceAddressPosition]  INT           CONSTRAINT [DF_LegalEntity_InvoiceAddressPosition] DEFAULT ((0)) NULL,
    [InvoiceFaxPhonePosition] INT           CONSTRAINT [DF_LegalEntity_InvoiceFaxPhonePosition] DEFAULT ((0)) NULL,
    [LastLevel]               BIT           DEFAULT ((0)) NOT NULL,
    [AttachmentId]            BIGINT        NULL,
    [PhoneExt]                VARCHAR (20)  NULL,
    [CompanyName]             VARCHAR (256) NOT NULL,
    [IsAddressForBilling]     BIT           DEFAULT ((0)) NOT NULL,
    [IsAddressForShipping]    BIT           DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_LegalEntity] PRIMARY KEY CLUSTERED ([LegalEntityId] ASC),
    CONSTRAINT [FK_LegalEntity_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_LegalEntity_FunctionalCurrency] FOREIGN KEY ([FunctionalCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_LegalEntity_Ledger] FOREIGN KEY ([LedgerId]) REFERENCES [dbo].[Ledger] ([LedgerId]),
    CONSTRAINT [FK_LegalEntity_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_LegalEntity_ReportingCurrency] FOREIGN KEY ([ReportingCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [Unique_LegalEntity] UNIQUE NONCLUSTERED ([CompanyCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_LegalEntity_Name] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);








GO




Create TRIGGER [dbo].[Trg_LegalEntityAudit] ON [dbo].[LegalEntity]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[LegalEntityAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END