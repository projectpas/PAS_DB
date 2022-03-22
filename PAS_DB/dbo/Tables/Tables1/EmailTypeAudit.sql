CREATE TABLE [dbo].[EmailTypeAudit] (
    [EmailTypeAuditID] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmailTypeID]      BIGINT        NOT NULL,
    [Name]             VARCHAR (256) NOT NULL,
    [Description]      VARCHAR (MAX) NULL,
    [Memo]             VARCHAR (MAX) NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_EmailTypeAudit] PRIMARY KEY CLUSTERED ([EmailTypeAuditID] ASC)
);

