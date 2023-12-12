﻿CREATE TABLE [dbo].[PurchaseOrderAddressAudit] (
    [PurchaseOrderAddressAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [POAddressId]                 BIGINT         NOT NULL,
    [PurchaseOrderId]             BIGINT         NOT NULL,
    [UserType]                    INT            NOT NULL,
    [UserId]                      BIGINT         NOT NULL,
    [SiteId]                      BIGINT         NOT NULL,
    [SiteName]                    VARCHAR (256)  NULL,
    [AddressId]                   BIGINT         NOT NULL,
    [IsPoOnly]                    BIT            NOT NULL,
    [IsShippingAdd]               BIT            NOT NULL,
    [ShippingAccountNo]           VARCHAR (100)  NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [ContactId]                   BIGINT         NOT NULL,
    [ContactName]                 VARCHAR (50)   NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    [IsDeleted]                   BIT            NOT NULL,
    [Line1]                       VARCHAR (50)   NULL,
    [Line2]                       VARCHAR (50)   NULL,
    [Line3]                       VARCHAR (50)   NULL,
    [City]                        VARCHAR (50)   NULL,
    [StateOrProvince]             VARCHAR (50)   NULL,
    [PostalCode]                  VARCHAR (20)   NULL,
    [Country]                     VARCHAR (50)   NULL,
    [CountryId]                   INT            NULL,
    CONSTRAINT [PK_PurchaseOrderAddressAuditId] PRIMARY KEY CLUSTERED ([PurchaseOrderAddressAuditId] ASC)
);

