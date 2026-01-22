CREATE TABLE [dbo].[ItemTypeAudit] (
    [AuditItemTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [ItemTypeId]      INT            NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    CONSTRAINT [PK_ItemTypeAudit] PRIMARY KEY CLUSTERED ([AuditItemTypeId] ASC)
);

