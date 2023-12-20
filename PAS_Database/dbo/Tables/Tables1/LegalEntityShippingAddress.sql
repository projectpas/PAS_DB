CREATE TABLE [dbo].[LegalEntityShippingAddress] (
    [LegalEntityShippingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                BIGINT        NOT NULL,
    [AddressId]                    BIGINT        NOT NULL,
    [SiteName]                     VARCHAR (256) NULL,
    [IsPrimary]                    BIT           CONSTRAINT [DF_CompanyShippingAddress_IsPrimary] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [LegalEntityShippingAddress_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [LegalEntityShippingAddress_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [LegalEntityShippingAddress_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [LegalEntityShippingAddress_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Attention]                    VARCHAR (100) NULL,
    [TagName]                      VARCHAR (250) NULL,
    [ContactTagId]                 BIGINT        NULL,
    CONSTRAINT [PK_CompanyShippingAddress] PRIMARY KEY CLUSTERED ([LegalEntityShippingAddressId] ASC),
    CONSTRAINT [FK_CompanyShippingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CompanyShippingAddress_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_CompanyShippingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityShippingAddressAudit]

   ON  [dbo].[LegalEntityShippingAddress]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO LegalEntityShippingAddressAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END