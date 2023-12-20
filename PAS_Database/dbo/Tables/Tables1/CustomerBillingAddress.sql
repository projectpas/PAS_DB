CREATE TABLE [dbo].[CustomerBillingAddress] (
    [CustomerBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]               BIGINT        NOT NULL,
    [AddressId]                BIGINT        NOT NULL,
    [IsPrimary]                BIT           NOT NULL,
    [SiteName]                 VARCHAR (100) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerBillingAddress_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerBillingAddress_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_CustomerBillingAddress_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [CustomerBillingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TagName]                  VARCHAR (250) NULL,
    [ContactTagId]             BIGINT        NULL,
    [Attention]                VARCHAR (250) NULL,
    [InvDelPrefStatusId]       BIGINT        NULL,
    [Email]                    VARCHAR (50)  NULL,
    CONSTRAINT [PK_CustomerBillingAddress] PRIMARY KEY CLUSTERED ([CustomerBillingAddressId] ASC),
    CONSTRAINT [FK_CustomerBillingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CustomerBillingAddress_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_CustomerBillingAddress_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerBillingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_CustomerBillingAddressAudit]

   ON  [dbo].[CustomerBillingAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerBillingAddressAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END