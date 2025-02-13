CREATE TABLE [dbo].[ATAReferenceAudit] (
    [AuditATAReferenceId] INT           IDENTITY (1, 1) NOT NULL,
    [ATAReferenceId]      INT           NULL,
    [ATAReference]        VARCHAR (256) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [IsActive]            BIT           NOT NULL,
    [IsDeleted]           BIT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_ATAReferenceAudit] PRIMARY KEY CLUSTERED ([AuditATAReferenceId] ASC)
);

