﻿CREATE TABLE [dbo].[WarehouseAudit] (
    [WarehouseAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WarehouseId]      BIGINT         NOT NULL,
    [Name]             VARCHAR (100)  NOT NULL,
    [SiteId]           BIGINT         NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    [Line1]            VARCHAR (50)   NULL,
    [Line2]            VARCHAR (50)   NULL,
    [City]             VARCHAR (50)   NULL,
    [StateOrProvince]  VARCHAR (50)   NULL,
    [PostalCode]       VARCHAR (20)   NULL,
    [Country]          VARCHAR (50)   NULL,
    [LegalEntity]      VARCHAR (50)   NULL,
    [SiteName]         VARCHAR (50)   NULL,
    [WarehouseCode]    VARCHAR (200)  NULL
);



