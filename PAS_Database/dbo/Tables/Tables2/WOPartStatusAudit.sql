CREATE TABLE [dbo].[WOPartStatusAudit] (
    [AuditWOPartStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WOPartStatusId]      BIGINT         NOT NULL,
    [PartStatus]          VARCHAR (256)  NOT NULL,
    [Description]         VARCHAR (MAX)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WOPartStatusAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WOPartStatusAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_WOPartStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_WOPartStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WOPartStatusAudit] PRIMARY KEY CLUSTERED ([AuditWOPartStatusId] ASC)
);

