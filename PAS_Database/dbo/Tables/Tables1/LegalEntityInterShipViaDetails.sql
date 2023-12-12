CREATE TABLE [dbo].[LegalEntityInterShipViaDetails] (
    [ShippingViaDetailsId]               BIGINT         IDENTITY (1, 1) NOT NULL,
    [LegalEntityInternationalShippingId] BIGINT         NOT NULL,
    [LegalEntityId]                      BIGINT         NOT NULL,
    [ShippingAccountInfo]                VARCHAR (200)  NOT NULL,
    [Memo]                               NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  CONSTRAINT [LegalEntityInterShipViaDetails_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  CONSTRAINT [LegalEntityInterShipViaDetails_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT            DEFAULT ((0)) NOT NULL,
    [IsPrimary]                          BIT            DEFAULT ((0)) NOT NULL,
    [ShipViaId]                          BIGINT         NOT NULL,
    CONSTRAINT [PK_LegalEntityInterShipViaDetails] PRIMARY KEY CLUSTERED ([ShippingViaDetailsId] ASC),
    CONSTRAINT [FK_LegalEntityInterShipViaDetails_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityInterShipViaDetails_LegalEntityInternationalShipping] FOREIGN KEY ([LegalEntityInternationalShippingId]) REFERENCES [dbo].[LegalEntityInternationalShipping] ([LegalEntityInternationalShippingId]),
    CONSTRAINT [FK_LegalEntityInterShipViaDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_LegalEntityInterShipViaDetails_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [Unique_LegalEntityInterShipViaDetails] UNIQUE NONCLUSTERED ([LegalEntityInternationalShippingId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);


GO




----------------------------------

CREATE TRIGGER [dbo].[Trg_LegalEntityInterShipViaDetailsAudit]

   ON  [dbo].[LegalEntityInterShipViaDetails]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[LegalEntityInterShipViaDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END