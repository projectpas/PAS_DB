CREATE TABLE [dbo].[TangibleClassAudit] (
    [TangibleClassAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TangibleClassId]      BIGINT         NOT NULL,
    [TangibleClassName]    VARCHAR (30)   NOT NULL,
    [TangibleClassMemo]    VARCHAR (1000) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [StatusCode]           VARCHAR (25)   NULL,
    CONSTRAINT [PK_TangibleClassAudit] PRIMARY KEY CLUSTERED ([TangibleClassAuditId] ASC)
);

