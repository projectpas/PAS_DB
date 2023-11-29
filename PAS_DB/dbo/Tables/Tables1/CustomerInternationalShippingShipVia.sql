CREATE TABLE [dbo].[CustomerInternationalShippingShipVia] (
    [CustomerInternationalShippingShipViaId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerInternationalShippingId]        BIGINT         NOT NULL,
    [CustomerId]                             BIGINT         NOT NULL,
    [ShipVia]                                VARCHAR (400)  NULL,
    [ShippingAccountInfo]                    VARCHAR (200)  NULL,
    [Memo]                                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]                        INT            NOT NULL,
    [CreatedBy]                              VARCHAR (256)  NULL,
    [UpdatedBy]                              VARCHAR (256)  NULL,
    [CreatedDate]                            DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                            DATETIME2 (7)  NOT NULL,
    [IsActive]                               BIT            NULL,
    [IsDeleted]                              BIT            NULL,
    [IsPrimary]                              BIT            DEFAULT ((0)) NULL,
    [ShipViaId]                              BIGINT         NULL,
    CONSTRAINT [PK_ShippingViaDetails] PRIMARY KEY CLUSTERED ([CustomerInternationalShippingShipViaId] ASC),
    CONSTRAINT [FK_ShippingViaDetails_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [Unique_ShippingViaDetails] UNIQUE NONCLUSTERED ([CustomerId] ASC, [CustomerInternationalShippingId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);




GO


----------------------------------

CREATE TRIGGER [dbo].[Trg_ShippingViaDetailsAudit]

   ON  [dbo].[CustomerInternationalShippingShipVia]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerInternationalShippingShipViaAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END