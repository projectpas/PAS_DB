CREATE TABLE [dbo].[ContactTagAudit] (
    [AuditContactTagId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ContactTagId]      BIGINT         NULL,
    [TagName]           VARCHAR (100)  NULL,
    [Description]       VARCHAR (500)  NULL,
    [SequenceNo]        INT            NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  NULL,
    [UpdatedDate]       DATETIME2 (7)  NULL,
    [IsActive]          BIT            CONSTRAINT [DF_ContactTagAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_ContactTagAudit_IsDeleted] DEFAULT ((0)) NULL,
    [MasterCompanyId]   INT            NULL,
    CONSTRAINT [PK_ContactTagAudit] PRIMARY KEY CLUSTERED ([AuditContactTagId] ASC)
);

