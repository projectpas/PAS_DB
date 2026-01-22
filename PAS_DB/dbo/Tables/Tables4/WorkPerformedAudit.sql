CREATE TABLE [dbo].[WorkPerformedAudit] (
    [WorkPerformedAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkPerformedId]      BIGINT         NULL,
    [WorkPerformedCode]    VARCHAR (30)   NULL,
    [Description]          VARCHAR (500)  NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NULL,
    [CreatedBy]            VARCHAR (256)  NULL,
    [UpdatedBy]            VARCHAR (256)  NULL,
    [CreatedDate]          DATETIME2 (7)  NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NULL,
    [IsDeleted]            BIT            NULL
);

