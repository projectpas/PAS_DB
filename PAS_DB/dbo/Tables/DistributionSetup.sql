CREATE TABLE [dbo].[DistributionSetup] (
    [ID]                   BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                 VARCHAR (200) NOT NULL,
    [GlAccountId]          BIGINT        NOT NULL,
    [GlAccountNumber]      VARCHAR (200) NOT NULL,
    [GlAccountName]        VARCHAR (200) NOT NULL,
    [JournalTypeId]        BIGINT        NOT NULL,
    [DistributionMasterId] BIGINT        NOT NULL,
    [IsDebit]              BIT           NULL,
    [DisplayNumber]        INT           NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DistributionSetup_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DistributionSetup_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DistributionSetup_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DistributionSetup_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DistributionSetup] PRIMARY KEY CLUSTERED ([ID] ASC)
);

