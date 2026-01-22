CREATE TABLE [dbo].[StandardAudit] (
    [StandardAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [StandardId]      INT            NOT NULL,
    [StandardName]    VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_StandardAudit] PRIMARY KEY CLUSTERED ([StandardAuditId] ASC)
);

