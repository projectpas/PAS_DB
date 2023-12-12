﻿CREATE TABLE [dbo].[AccountingBatchManagementStructureDetails] (
    [CommonBatchMSId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReferenceId]     BIGINT        NOT NULL,
    [ModuleId]        INT           NOT NULL,
    [EntityMSID]      BIGINT        NULL,
    [Level1Id]        BIGINT        NULL,
    [Level2Id]        BIGINT        NULL,
    [Level3Id]        BIGINT        NULL,
    [Level4Id]        BIGINT        NULL,
    [Level5Id]        BIGINT        NULL,
    [Level6Id]        BIGINT        NULL,
    [Level7Id]        BIGINT        NULL,
    [Level8Id]        BIGINT        NULL,
    [Level9Id]        BIGINT        NULL,
    [Level10Id]       BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_AccountingBatchManagementStructureDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_AccountingBatchManagementStructureDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_AccountingBatchManagementStructureDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_AccountingBatchManagementStructureDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AccountingBatchManagementStructureDetails] PRIMARY KEY CLUSTERED ([CommonBatchMSId] ASC)
);

