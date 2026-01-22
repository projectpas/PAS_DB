CREATE TABLE [dbo].[ManagementStructureModule] (
    [ManagementStructureModuleId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleName]                  VARCHAR (256) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ManagmentStructureModule_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_ManagmentStructureModule_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_ManagmentStructureModule_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_ManagmentStructureModule_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagmentStructureModule] PRIMARY KEY CLUSTERED ([ManagementStructureModuleId] ASC)
);

