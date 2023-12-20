CREATE TABLE [dbo].[LeadSourceAudit] (
    [LeadSourceAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [LeadSourceId]      INT            NOT NULL,
    [Description]       NVARCHAR (MAX) NULL,
    [LeadSources]       VARCHAR (50)   NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF__LeadSourceAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_LeadSourceAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [SequenceNo]        INT            NULL
);

