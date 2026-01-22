CREATE TABLE [dbo].[WOListRBAudit] (
    [WOListRBAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WOListRBId]      BIGINT         NOT NULL,
    [Name]            VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (256)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [WOListRBType]    INT            NULL,
    CONSTRAINT [PK_WOListRBAudit] PRIMARY KEY CLUSTERED ([WOListRBAuditId] ASC)
);

