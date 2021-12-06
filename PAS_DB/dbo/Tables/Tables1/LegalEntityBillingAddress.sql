CREATE TABLE [dbo].[LegalEntityBillingAddress] (
    [LegalEntityBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]               BIGINT        NOT NULL,
    [AddressId]                   BIGINT        NOT NULL,
    [IsPrimary]                   BIT           CONSTRAINT [CONSTRAINT_LegalEntityBillingAddress_IsPrimary] DEFAULT ((0)) NOT NULL,
    [SiteName]                    VARCHAR (256) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_CompanyBillingAddress_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_CompanyBillingAddress_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Attention]                   VARCHAR (100) NULL,
    CONSTRAINT [PK_CompanyBillingAddress] PRIMARY KEY CLUSTERED ([LegalEntityBillingAddressId] ASC),
    CONSTRAINT [FK_CompanyBillingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CompanyBillingAddress_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_CompanyBillingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityBillingAddressAudit]

   ON  [dbo].[LegalEntityBillingAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityBillingAddressAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END