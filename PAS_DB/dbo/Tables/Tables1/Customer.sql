CREATE TABLE [dbo].[Customer] (
    [CustomerId]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerAffiliationId] INT            NULL,
    [CustomerTypeId]        INT            NOT NULL,
    [Name]                  VARCHAR (100)  NOT NULL,
    [CustomerCode]          VARCHAR (100)  NOT NULL,
    [DoingBuinessAsName]    VARCHAR (50)   NULL,
    [IsParent]              BIT            CONSTRAINT [Customer_DC_IsParent] DEFAULT ((0)) NOT NULL,
    [ParentId]              BIGINT         NULL,
    [CustomerPhone]         VARCHAR (20)   NULL,
    [CustomerPhoneExt]      VARCHAR (20)   NULL,
    [Email]                 VARCHAR (200)  NULL,
    [AddressId]             BIGINT         NOT NULL,
    [IsAddressForBilling]   BIT            CONSTRAINT [DF__Customer__IsAddr__18D6A699] DEFAULT ((0)) NOT NULL,
    [IsAddressForShipping]  BIT            CONSTRAINT [DF__Customer__IsAddr__19CACAD2] DEFAULT ((0)) NOT NULL,
    [IsCustomerAlsoVendor]  BIT            NOT NULL,
    [ContractReference]     VARCHAR (100)  NULL,
    [IsPBHCustomer]         BIT            NOT NULL,
    [PBHCustomerMemo]       VARCHAR (MAX)  NULL,
    [CustomerURL]           NVARCHAR (500) NULL,
    [RestrictPMA]           BIT            NOT NULL,
    [RestrictDER]           BIT            CONSTRAINT [Customer_DC_RestrictBER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId] BIGINT         NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Customer_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Customer_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [Customer_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [Customer_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsCRMCustomer]         BIT            CONSTRAINT [Customer_DC_IsCRM] DEFAULT ((0)) NOT NULL,
    [BillingAddressId]      BIGINT         NULL,
    [ShippingAddressId]     BIGINT         NULL,
    [IsTradeRestricted]     BIT            NULL,
    [TradeRestrictedMemo]   NVARCHAR (MAX) NULL,
    [IsTrackScoreCard]      BIT            NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED ([CustomerId] ASC),
    CONSTRAINT [FK_Customer_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_Customer_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_Customer_CustomerAffiliation] FOREIGN KEY ([CustomerAffiliationId]) REFERENCES [dbo].[CustomerAffiliation] ([CustomerAffiliationId]),
    CONSTRAINT [FK_Customer_CustomerType] FOREIGN KEY ([CustomerTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_Customer_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_Customer_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_Customer_Email] UNIQUE NONCLUSTERED ([Email] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_CustomerCode] UNIQUE NONCLUSTERED ([CustomerCode] ASC, [MasterCompanyId] ASC)
);




GO


CREATE TRIGGER [dbo].[Trg_CustomerAudit]

   ON  [dbo].[Customer]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END