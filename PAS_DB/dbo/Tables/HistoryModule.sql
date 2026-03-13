CREATE TABLE [dbo].[HistoryModule] (
    [HistoryModuleId]          INT           IDENTITY (1, 1) NOT NULL,
    [HistoryModuleName]        VARCHAR (100) NOT NULL,
    [HistoryModuleDisplayName] VARCHAR (100) NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [HistoryModule_DC_CD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [HistoryModule_DC_UD] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [HistoryModule_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [HistoryModule_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_HistoryModule] PRIMARY KEY CLUSTERED ([HistoryModuleId] ASC),
    CONSTRAINT [Un_HistoryModuleName] UNIQUE NONCLUSTERED ([HistoryModuleName] ASC, [MasterCompanyId] ASC)
);

