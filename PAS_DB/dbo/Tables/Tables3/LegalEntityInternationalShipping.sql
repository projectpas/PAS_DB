CREATE TABLE [dbo].[LegalEntityInternationalShipping] (
    [LegalEntityInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                      BIGINT          NOT NULL,
    [ExportLicense]                      VARCHAR (200)   NULL,
    [StartDate]                          DATETIME        NULL,
    [Amount]                             DECIMAL (18, 3) NULL,
    [IsPrimary]                          BIT             CONSTRAINT [LegalEntityInternationalShipping_DC_IsPrimary] DEFAULT ((0)) NOT NULL,
    [Description]                        VARCHAR (250)   NULL,
    [ExpirationDate]                     DATETIME        NULL,
    [ShipToCountryId]                    BIGINT          NOT NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (256)   NOT NULL,
    [UpdatedBy]                          VARCHAR (256)   NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [LegalEntityInternationalShipping_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [LegalEntityInternationalShipping_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [LegalEntityInternationalShipping_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [LegalEntityInternationalShipping_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityInternationalShipping] PRIMARY KEY CLUSTERED ([LegalEntityInternationalShippingId] ASC),
    CONSTRAINT [FK_LegalEntityInternationalShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityInternationalShippingAudit]

   ON  [dbo].[LegalEntityInternationalShipping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityInternationalShippingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END