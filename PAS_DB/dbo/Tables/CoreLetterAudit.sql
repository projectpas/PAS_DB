CREATE TABLE [dbo].[CoreLetterAudit] (
    [CoreLetterAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CoreLetterId]      INT            NULL,
    [HeaderName]        VARCHAR (100)  NULL,
    [LetterDescription] NVARCHAR (MAX) NULL,
    [LetterCode]        VARCHAR (50)   NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_CoreLetterAudit_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_CoreLetterAudit_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]          BIT            CONSTRAINT [DF_CoreLetterAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_CoreLetterAudit_IsDeleted] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_CoreLetterAudit] PRIMARY KEY CLUSTERED ([CoreLetterAuditId] ASC)
);
