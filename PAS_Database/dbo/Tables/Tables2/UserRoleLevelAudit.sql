CREATE TABLE [dbo].[UserRoleLevelAudit] (
    [UserRoleLevelAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserRoleLevelId]      BIGINT        NOT NULL,
    [Description]          VARCHAR (100) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             NCHAR (10)    NULL,
    CONSTRAINT [PK_UserRoleLevelAudit] PRIMARY KEY CLUSTERED ([UserRoleLevelAuditId] ASC)
);

