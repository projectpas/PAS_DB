CREATE TABLE [dbo].[PurchaseOrderAddress] (
    [POAddressId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]   BIGINT         NOT NULL,
    [UserType]          INT            DEFAULT ((0)) NOT NULL,
    [UserId]            BIGINT         DEFAULT ((0)) NOT NULL,
    [SiteId]            BIGINT         DEFAULT ((0)) NOT NULL,
    [SiteName]          VARCHAR (256)  NULL,
    [AddressId]         BIGINT         NOT NULL,
    [IsPoOnly]          BIT            NOT NULL,
    [IsShippingAdd]     BIT            NOT NULL,
    [ShippingAccountNo] VARCHAR (100)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [ContactId]         BIGINT         DEFAULT ((0)) NOT NULL,
    [ContactName]       VARCHAR (200)  NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [Line1]             VARCHAR (50)   NULL,
    [Line2]             VARCHAR (50)   NULL,
    [Line3]             VARCHAR (50)   NULL,
    [City]              VARCHAR (50)   NULL,
    [StateOrProvince]   VARCHAR (50)   NULL,
    [PostalCode]        VARCHAR (20)   NULL,
    [Country]           VARCHAR (50)   NULL,
    [CountryId]         INT            NULL,
    CONSTRAINT [PK_PurchaseOrderAddress] PRIMARY KEY CLUSTERED ([POAddressId] ASC),
    CONSTRAINT [FK_PurchaseOrderAddress_PurchaseOrder] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId])
);




GO




CREATE TRIGGER [dbo].[Trg_PurchaseOrderAddressAudit]

   ON  [dbo].[PurchaseOrderAddress]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO PurchaseOrderAddressAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END