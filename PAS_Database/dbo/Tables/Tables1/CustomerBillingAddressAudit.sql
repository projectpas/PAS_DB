CREATE TABLE [dbo].[CustomerBillingAddressAudit] (
    [AuditCustomerBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerBillingAddressId]      BIGINT        NOT NULL,
    [CustomerId]                    BIGINT        NOT NULL,
    [AddressId]                     BIGINT        NOT NULL,
    [IsPrimary]                     BIT           NOT NULL,
    [SiteName]                      VARCHAR (100) NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [CustomerBillingAddressAudit_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [CustomerBillingAddressAudit_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TagName]                       VARCHAR (250) NULL,
    [ContactTagId]                  BIGINT        NULL,
    [Attention]                     VARCHAR (250) NULL,
    [InvDelPrefStatusId]            BIGINT        NULL,
    [Email]                         VARCHAR (50)  NULL,
    CONSTRAINT [PK_CustomerBillingAddressAudit] PRIMARY KEY CLUSTERED ([AuditCustomerBillingAddressId] ASC),
    CONSTRAINT [FK_CustomerBillingAddressAudit_CustomerBillingAddress] FOREIGN KEY ([CustomerBillingAddressId]) REFERENCES [dbo].[CustomerBillingAddress] ([CustomerBillingAddressId])
);

