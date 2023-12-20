CREATE TABLE [dbo].[WingTypeAudit] (
    [WingTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WingTypeId]      BIGINT         NOT NULL,
    [WingTypeName]    VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WingTypeAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WingTypeAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_WingTypeAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_WingTypeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WingTypeAudit] PRIMARY KEY CLUSTERED ([WingTypeAuditId] ASC)
);

