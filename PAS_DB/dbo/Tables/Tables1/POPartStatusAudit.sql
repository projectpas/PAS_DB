CREATE TABLE [dbo].[POPartStatusAudit] (
    [AuditPOPartStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [POPartStatusId]      BIGINT         NOT NULL,
    [PartStatus]          VARCHAR (256)  NOT NULL,
    [Description]         VARCHAR (MAX)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [SequenceNo]          INT            NULL,
    CONSTRAINT [PK_POPartStatusAudit] PRIMARY KEY CLUSTERED ([AuditPOPartStatusId] ASC)
);

