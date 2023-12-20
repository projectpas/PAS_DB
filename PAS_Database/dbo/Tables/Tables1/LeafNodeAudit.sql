CREATE TABLE [dbo].[LeafNodeAudit] (
    [AuditLeafNodeId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [LeafNodeId]           BIGINT        NOT NULL,
    [Name]                 VARCHAR (256) NOT NULL,
    [ParentId]             BIGINT        NULL,
    [IsLeafNode]           BIT           NULL,
    [GLAccountId]          VARCHAR (MAX) NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_LeafNodeAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_LeafNodeAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_LeafNodeAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_LeafNodeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReportingStructureId] BIGINT        NULL,
    [IsPositive]           BIT           NULL,
    [SequenceNumber]       BIGINT        NULL,
    CONSTRAINT [PK_LeafNodeAudit] PRIMARY KEY CLUSTERED ([AuditLeafNodeId] ASC)
);

