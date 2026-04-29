CREATE TABLE [dbo].[ImportModule] (
    [ImportModuleId]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleName]              VARCHAR (100) NOT NULL,
    [ReferenceTable]          VARCHAR (100) NOT NULL,
    [ReferenceColumnName]     VARCHAR (100) NOT NULL,
    [ModuleParentTable]       VARCHAR (100) NULL,
    [ParentPrimaryColumnName] VARCHAR (100) NULL,
    [ChildTable]              VARCHAR (100) NULL,
    [CodeTypeId]              BIGINT        NULL,
    [Description]             VARCHAR (500) NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (50)  NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_ImportModule_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (50)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_ImportModule_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF__ImportModule__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF__ImportModule__IsDeleted] DEFAULT ((0)) NOT NULL,
    [DisplayModuleName]       VARCHAR (100) CONSTRAINT [DF_ImportModule_DisplayModuleName] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ImportModule] PRIMARY KEY CLUSTERED ([ImportModuleId] ASC)
);

