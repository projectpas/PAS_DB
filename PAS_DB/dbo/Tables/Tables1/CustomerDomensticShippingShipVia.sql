CREATE TABLE [dbo].[CustomerDomensticShippingShipVia] (
    [CustomerDomensticShippingShipViaId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CustomerId]                         BIGINT         NOT NULL,
    [CustomerDomensticShippingId]        BIGINT         NOT NULL,
    [IsPrimary]                          BIT            CONSTRAINT [DF__CustomerS__IsPri__19025A79] DEFAULT ((0)) NOT NULL,
    [ShipVia]                            VARCHAR (400)  NULL,
    [ShippingAccountInfo]                VARCHAR (200)  NULL,
    [Memo]                               NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  NOT NULL,
    [IsActive]                           BIT            CONSTRAINT [CustomerShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT            CONSTRAINT [CustomerShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ShipViaId]                          BIGINT         NULL,
    CONSTRAINT [PK_CustomerShipping] PRIMARY KEY CLUSTERED ([CustomerDomensticShippingShipViaId] ASC),
    CONSTRAINT [FK_CustomerShipping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerShipping_CustomerShippingAddress] FOREIGN KEY ([CustomerDomensticShippingId]) REFERENCES [dbo].[CustomerDomensticShipping] ([CustomerDomensticShippingId]),
    CONSTRAINT [FK_CustomerShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CustomerShipping_ShippingViaId] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [Unique_CustomerShipping] UNIQUE NONCLUSTERED ([CustomerId] ASC, [CustomerDomensticShippingId] ASC, [ShipViaId] ASC, [ShippingAccountInfo] ASC, [MasterCompanyId] ASC)
);




GO


-----------------

CREATE TRIGGER [dbo].[Trg_CustomerShippingAudit]

   ON  [dbo].[CustomerDomensticShippingShipVia]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerDomensticShippingShipViaAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END