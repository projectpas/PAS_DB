CREATE TABLE [dbo].[CustomerDomensticShipping] (
    [CustomerDomensticShippingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                  BIGINT        NOT NULL,
    [AddressId]                   BIGINT        NOT NULL,
    [IsPrimary]                   BIT           CONSTRAINT [DF__CustomerS__IsPri__1D9B5BB6] DEFAULT ((0)) NOT NULL,
    [SiteName]                    VARCHAR (100) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerShippingAddress_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerShippingAddress_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [CustomerShippingAddress_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [CustomerShippingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TagName]                     VARCHAR (250) NULL,
    [ContactTagId]                BIGINT        NULL,
    [Attention]                   VARCHAR (250) NULL,
    CONSTRAINT [PK_CustomerShippingAddress] PRIMARY KEY CLUSTERED ([CustomerDomensticShippingId] ASC),
    CONSTRAINT [FK_CustomerDomensticShipping_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_CustomerShippingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CustomerShippingAddress_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerShippingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerShippingAddressAudit]

   ON  [dbo].[CustomerDomensticShipping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerDomensticShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END