CREATE TABLE [dbo].[LegalEntityShipping] (
    [LegalEntityShippingId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                BIGINT         NOT NULL,
    [LegalEntityShippingAddressId] BIGINT         NOT NULL,
    [ShipVia]                      VARCHAR (400)  NULL,
    [ShippingAccountInfo]          VARCHAR (200)  NOT NULL,
    [Memo]                         NVARCHAR (MAX) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  CONSTRAINT [LegalEntityShipping_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  CONSTRAINT [LegalEntityShipping_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT            CONSTRAINT [LegalEntityShipping_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT            CONSTRAINT [LegalEntityShipping_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsPrimary]                    BIT            DEFAULT ((0)) NOT NULL,
    [ShipViaId]                    BIGINT         NOT NULL,
    [ShippingTermsId]              BIGINT         NULL,
    CONSTRAINT [PK_LegalEntityShipping] PRIMARY KEY CLUSTERED ([LegalEntityShippingId] ASC),
    CONSTRAINT [FK_LegalEntityShipping_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityShipping_LegalEntityShippingAddress] FOREIGN KEY ([LegalEntityShippingAddressId]) REFERENCES [dbo].[LegalEntityShippingAddress] ([LegalEntityShippingAddressId]),
    CONSTRAINT [FK_LegalEntityShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_LegalEntityShipping_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [Unique_LegalEntityShipping] UNIQUE NONCLUSTERED ([LegalEntityShippingAddressId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);




GO






CREATE TRIGGER [dbo].[Trg_LegalEntityShippingAudit]

   ON  [dbo].[LegalEntityShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityShippingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END