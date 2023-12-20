CREATE TABLE [dbo].[ActionAudit] (
    [ActionAuditId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ActionId]        BIGINT         NOT NULL,
    [Description]     VARCHAR (200)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NULL,
    [UpdatedDate]     DATETIME2 (7)  NULL,
    [IsActive]        BIT            NULL,
    [IsDeleted]       BIT            NULL,
    CONSTRAINT [PK__ActionAu__31C48C371912AA3A] PRIMARY KEY CLUSTERED ([ActionAuditId] ASC),
    CONSTRAINT [FK_ActionAudit_Action] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId])
);

