CREATE TABLE [dbo].[ItemClassificationAudit] (
    [ItemClassificationAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemClassificationId]      BIGINT         NOT NULL,
    [ItemClassificationCode]    VARCHAR (30)   NOT NULL,
    [Description]               VARCHAR (100)  NOT NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [MastercompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  NOT NULL,
    [IsActive]                  BIT            NOT NULL,
    [IsDeleted]                 BIT            NOT NULL,
    [ItemTypeId]                INT            DEFAULT ((0)) NOT NULL,
    [ItemType]                  VARCHAR (100)  NULL
);

