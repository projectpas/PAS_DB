CREATE TABLE [dbo].[ExpertiseTypeAudit] (
    [ExpertiseTypeAuditId] SMALLINT       IDENTITY (1, 1) NOT NULL,
    [ExpertiseTypeId]      SMALLINT       NOT NULL,
    [Description]          VARCHAR (100)  NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NULL,
    [UpdatedBy]            VARCHAR (256)  NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NULL,
    [IsDeleted]            BIT            NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ExpertiseTypeAudit] PRIMARY KEY CLUSTERED ([ExpertiseTypeAuditId] ASC)
);

