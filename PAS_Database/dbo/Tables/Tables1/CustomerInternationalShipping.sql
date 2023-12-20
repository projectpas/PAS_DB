CREATE TABLE [dbo].[CustomerInternationalShipping] (
    [CustomerInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]                      BIGINT          NOT NULL,
    [ExportLicense]                   VARCHAR (200)   NULL,
    [StartDate]                       DATETIME        NULL,
    [Amount]                          DECIMAL (18, 3) CONSTRAINT [DF_CustomerInternationalShipping_Amount] DEFAULT ((0)) NULL,
    [IsPrimary]                       BIT             CONSTRAINT [CustomerInternationalShipping_DC_IsPrimary] DEFAULT ((0)) NOT NULL,
    [Description]                     NVARCHAR (500)  NULL,
    [ExpirationDate]                  DATETIME        NULL,
    [ShipToCountryId]                 SMALLINT        NOT NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [CreatedBy]                       VARCHAR (256)   NOT NULL,
    [UpdatedBy]                       VARCHAR (256)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [CustomerInternationalShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [CustomerInternationalShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InternationalShipping] PRIMARY KEY CLUSTERED ([CustomerInternationalShippingId] ASC),
    CONSTRAINT [FK_CustomerInternationalShipping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerInternationalShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CustomerInternationalShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id])
);


GO


------------------------------

CREATE TRIGGER [dbo].[Trg_CustomerInternationalShippingAudit]

   ON  [dbo].[CustomerInternationalShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END