CREATE TABLE [dbo].[ConditionAudit] (
    [ConditionAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ConditionId]      BIGINT         NOT NULL,
    [Description]      VARCHAR (256)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    [SequenceNo]       VARCHAR (256)  NOT NULL,
    [Code]             VARCHAR (100)  NULL,
    [GroupCode]        VARCHAR (20)   NULL,
    CONSTRAINT [PK_ConditionAudit] PRIMARY KEY CLUSTERED ([ConditionAuditId] ASC)
);



