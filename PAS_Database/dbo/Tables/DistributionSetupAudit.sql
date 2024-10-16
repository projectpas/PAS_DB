﻿CREATE TABLE [dbo].[DistributionSetupAudit] (
    [DistributionSetupAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ID]                       BIGINT        NOT NULL,
    [Name]                     VARCHAR (200) NOT NULL,
    [GlAccountId]              BIGINT        NOT NULL,
    [GlAccountNumber]          VARCHAR (200) NOT NULL,
    [GlAccountName]            VARCHAR (200) NOT NULL,
    [JournalTypeId]            BIGINT        NOT NULL,
    [DistributionMasterId]     BIGINT        NOT NULL,
    [IsDebit]                  BIT           NULL,
    [DisplayNumber]            INT           NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_DistributionSetupAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_DistributionSetupAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF__DistributionSetupAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF__DistributionSetupAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [CRDRType]                 INT           NULL,
    [DistributionSetupCode]    VARCHAR (100) NOT NULL,
    [IsManualText]             BIT           NULL,
    [ManualText]               VARCHAR (100) NULL,
    [IsAutoPost]               BIT           NULL,
    CONSTRAINT [PK_DistributionSetupAudit] PRIMARY KEY CLUSTERED ([DistributionSetupAuditId] ASC)
);



