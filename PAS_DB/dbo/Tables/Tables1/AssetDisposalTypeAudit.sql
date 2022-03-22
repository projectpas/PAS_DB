﻿CREATE TABLE [dbo].[AssetDisposalTypeAudit] (
    [AssetDisposalTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetDisposalTypeId]      BIGINT         NOT NULL,
    [AssetDisposalCode]        VARCHAR (30)   NOT NULL,
    [AssetDisposalName]        VARCHAR (50)   NOT NULL,
    [AssetDisposalMemo]        NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL,
    CONSTRAINT [PK_AssetDisposalTypeAudit] PRIMARY KEY CLUSTERED ([AssetDisposalTypeAuditId] ASC),
    CONSTRAINT [FK_AssetDisposalTypeAudit_AssetDisposalType] FOREIGN KEY ([AssetDisposalTypeId]) REFERENCES [dbo].[AssetDisposalType] ([AssetDisposalTypeId])
);

