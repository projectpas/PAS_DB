CREATE TABLE [dbo].[WorkScopeAudit] (
    [WorkScopeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkScopeId]      BIGINT         NOT NULL,
    [WorkScopeCode]    VARCHAR (256)  NOT NULL,
    [Description]      VARCHAR (500)  NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    [WorkScopeCodeNew] VARCHAR (50)   NULL,
    [ConditionId]      INT            NULL,
    CONSTRAINT [PK__WorkScop__D2984988BF1C48D4] PRIMARY KEY CLUSTERED ([WorkScopeAuditId] ASC)
);

