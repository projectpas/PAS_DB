CREATE TABLE [dbo].[TagTypeAudit] (
    [AuditTagTypeId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [TagTypeId]       BIGINT         NOT NULL,
    [Name]            NVARCHAR (400) NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [Description]     VARCHAR (256)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_TagTypeAudit] PRIMARY KEY CLUSTERED ([AuditTagTypeId] ASC)
);

