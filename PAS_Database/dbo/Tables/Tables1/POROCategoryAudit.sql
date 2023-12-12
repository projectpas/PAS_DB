﻿CREATE TABLE [dbo].[POROCategoryAudit] (
    [POROCategoryAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [POROCategoryId]      VARCHAR (256)  NOT NULL,
    [CategoryName]        VARCHAR (30)   NOT NULL,
    [IsPO]                BIT            NULL,
    [IsRO]                BIT            NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL
);

