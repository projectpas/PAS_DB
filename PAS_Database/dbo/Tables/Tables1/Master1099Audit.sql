CREATE TABLE [dbo].[Master1099Audit] (
    [AuditMaster1099Id] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Master1099Id]      BIGINT         NOT NULL,
    [Description]       VARCHAR (100)  NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [Name]              VARCHAR (150)  NULL,
    [SequenceNo]        INT            NULL,
    CONSTRAINT [PK_Master1099Audit] PRIMARY KEY CLUSTERED ([AuditMaster1099Id] ASC)
);

