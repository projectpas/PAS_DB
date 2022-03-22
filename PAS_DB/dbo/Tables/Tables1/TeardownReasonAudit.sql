﻿CREATE TABLE [dbo].[TeardownReasonAudit] (
    [AuditTeardownReasonId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TeardownReasonId]      BIGINT         NOT NULL,
    [Reason]                VARCHAR (1000) NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [CommonTeardownTypeId]  BIGINT         DEFAULT ((0)) NOT NULL,
    [TeardownType]          VARCHAR (256)  NULL,
    CONSTRAINT [PK_TeardownReasonAudit] PRIMARY KEY CLUSTERED ([AuditTeardownReasonId] ASC)
);

