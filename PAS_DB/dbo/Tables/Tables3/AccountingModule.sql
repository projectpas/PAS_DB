CREATE TABLE [dbo].[AccountingModule] (
    [AccountingModuleId]   INT           IDENTITY (1, 1) NOT NULL,
    [AccountingModuleName] VARCHAR (100) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [AccountingModule_DC_CD] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [AccountingModule_DC_UD] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [AccountingModule_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [AccountingModule_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AccountingModule] PRIMARY KEY CLUSTERED ([AccountingModuleId] ASC),
    CONSTRAINT [Un_AccountingModuleName] UNIQUE NONCLUSTERED ([AccountingModuleName] ASC, [MasterCompanyId] ASC)
);

