CREATE TABLE [dbo].[EvidenceAudit] (
    [EvidenceAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EvidenceId]      INT           NOT NULL,
    [EvidenceName]    VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_EvidenceAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_EvidenceAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_EvidenceAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_EvidenceAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EvidenceAudit] PRIMARY KEY CLUSTERED ([EvidenceAuditId] ASC)
);

