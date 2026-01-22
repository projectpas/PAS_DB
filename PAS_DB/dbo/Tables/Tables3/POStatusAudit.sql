CREATE TABLE [dbo].[POStatusAudit] (
    [AuditPOStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [POStatusId]      BIGINT         NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_POStatusAudit] PRIMARY KEY CLUSTERED ([AuditPOStatusId] ASC)
);

