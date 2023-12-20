CREATE TABLE [dbo].[FindingAudit] (
    [AuditFindingId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [FindingId]       BIGINT         NOT NULL,
    [FindingCode]     VARCHAR (30)   NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_FindingAudit] PRIMARY KEY CLUSTERED ([AuditFindingId] ASC)
);

