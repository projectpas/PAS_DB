CREATE TABLE [dbo].[JobTypeAudit] (
    [JobTypeAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [JobTypeId]       SMALLINT       NOT NULL,
    [JobTypeName]     VARCHAR (30)   NOT NULL,
    [JobTypeMemo]     NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_JobTypeAudit] PRIMARY KEY CLUSTERED ([JobTypeAuditId] ASC),
    CONSTRAINT [FK_JobTypeAudit_JobType] FOREIGN KEY ([JobTypeId]) REFERENCES [dbo].[JobType] ([JobTypeId])
);

