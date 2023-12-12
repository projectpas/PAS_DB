CREATE TABLE [dbo].[TaskAttributeAudit] (
    [TaskAttributeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TaskAttributeId]      BIGINT         NULL,
    [Description]          VARCHAR (100)  NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NULL,
    [CreatedBy]            VARCHAR (256)  NULL,
    [UpdatedBy]            VARCHAR (256)  NULL,
    [CreatedDate]          DATETIME2 (7)  NULL,
    [UpdatedDate]          DATETIME2 (7)  NULL,
    [IsActive]             BIT            NULL,
    [IsDeleted]            BIT            NULL,
    [Sequence]             BIGINT         DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([TaskAttributeAuditId] ASC)
);

