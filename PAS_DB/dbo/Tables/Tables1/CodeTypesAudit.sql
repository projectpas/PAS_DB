CREATE TABLE [dbo].[CodeTypesAudit] (
    [CodeTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CodeTypeId]      BIGINT         NOT NULL,
    [CodeType]        VARCHAR (100)  NOT NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_CodeTypesAudit] PRIMARY KEY CLUSTERED ([CodeTypeAuditId] ASC)
);

