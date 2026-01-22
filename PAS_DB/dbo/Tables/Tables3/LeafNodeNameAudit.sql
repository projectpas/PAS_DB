CREATE TABLE [dbo].[LeafNodeNameAudit] (
    [LeafNodeNameAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [LeafNodeNameId]      BIGINT         NOT NULL,
    [Name]                VARCHAR (256)  NOT NULL,
    [Description]         VARCHAR (MAX)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    CONSTRAINT [PK_LeafNodeNameAudit] PRIMARY KEY CLUSTERED ([LeafNodeNameAuditId] ASC)
);

