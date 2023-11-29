CREATE TABLE [dbo].[GLAccountClassAudit] (
    [GLAccountClassAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [GLAccountClassId]      BIGINT         NOT NULL,
    [GLAccountClassName]    VARCHAR (200)  NOT NULL,
    [GLAccountClassMemo]    NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [SequenceNumber]        INT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_GLAccountClassAudit] PRIMARY KEY CLUSTERED ([GLAccountClassAuditId] ASC),
    CONSTRAINT [FK_GLAccountClassAudit_GLAccountClass] FOREIGN KEY ([GLAccountClassId]) REFERENCES [dbo].[GLAccountClass] ([GLAccountClassId])
);



