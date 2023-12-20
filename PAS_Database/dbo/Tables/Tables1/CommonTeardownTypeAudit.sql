CREATE TABLE [dbo].[CommonTeardownTypeAudit] (
    [CommonTeardownTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CommonTeardownTypeId]      BIGINT        NOT NULL,
    [Name]                      VARCHAR (256) NOT NULL,
    [Description]               VARCHAR (MAX) NULL,
    [IsTechnician]              BIT           NULL,
    [IsDate]                    BIT           NULL,
    [IsInspector]               BIT           NULL,
    [IsInspectorDate]           BIT           NULL,
    [IsDocument]                BIT           NULL,
    [TearDownCode]              VARCHAR (200) NULL,
    [Sequence]                  INT           NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    [DocumentModuleName]        VARCHAR (100) NULL,
    CONSTRAINT [PK_CommonTeardownTypeAudit] PRIMARY KEY CLUSTERED ([CommonTeardownTypeAuditId] ASC)
);

