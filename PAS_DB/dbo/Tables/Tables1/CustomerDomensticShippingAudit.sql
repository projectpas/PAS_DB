CREATE TABLE [dbo].[CustomerDomensticShippingAudit] (
    [CustomerDomensticShippingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerDomensticShippingId]      BIGINT        NOT NULL,
    [CustomerId]                       BIGINT        NOT NULL,
    [AddressId]                        BIGINT        NOT NULL,
    [IsPrimary]                        BIT           NOT NULL,
    [SiteName]                         VARCHAR (100) NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    [IsActive]                         BIT           NOT NULL,
    [IsDeleted]                        BIT           NOT NULL,
    [TagName]                          VARCHAR (250) NULL,
    [ContactTagId]                     BIGINT        NULL,
    [Attention]                        VARCHAR (250) NULL,
    CONSTRAINT [PK_CustomerShippingAddressAudit] PRIMARY KEY CLUSTERED ([CustomerDomensticShippingAuditId] ASC),
    CONSTRAINT [FK_CustomerShippingAddressAudit_CustomerShippingAddress] FOREIGN KEY ([CustomerDomensticShippingId]) REFERENCES [dbo].[CustomerDomensticShipping] ([CustomerDomensticShippingId])
);

