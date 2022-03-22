CREATE TABLE [dbo].[ModuleAudit] (
    [AuditModuleId]   INT           IDENTITY (1, 1) NOT NULL,
    [ModuleId]        INT           NOT NULL,
    [ModuleName]      VARCHAR (100) NOT NULL,
    [CodePrefix]      VARCHAR (10)  NOT NULL,
    [CodeSufix]       VARCHAR (10)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_ModuleAudit] PRIMARY KEY CLUSTERED ([AuditModuleId] ASC)
);

