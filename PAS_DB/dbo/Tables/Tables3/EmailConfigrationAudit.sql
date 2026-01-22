CREATE TABLE [dbo].[EmailConfigrationAudit] (
    [EmailConfigAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmailConfigId]      BIGINT         NOT NULL,
    [Header]             NVARCHAR (MAX) NOT NULL,
    [Footer]             NVARCHAR (MAX) NOT NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_EmailConfigrationAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_EmailConfigrationAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_EmailConfigrationAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_EmailConfigrationAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmailConfigrationAudit] PRIMARY KEY CLUSTERED ([EmailConfigAuditId] ASC)
);

