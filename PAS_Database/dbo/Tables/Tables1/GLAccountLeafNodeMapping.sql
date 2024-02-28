CREATE TABLE [dbo].[GLAccountLeafNodeMapping] (
    [GLAccountLeafNodeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LeafNodeId]                 BIGINT        NOT NULL,
    [GLAccountId]                BIGINT        NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_GLAccountLeafNodeMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_GLAccountLeafNodeMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_GLAccountLeafNodeMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [IsPositive]                 BIT           NULL,
    [NewReportingStructureId]    BIGINT        NULL,
    [SequenceNumber]             INT           NULL,
    CONSTRAINT [PK_GLAccountLeafNodeMapping] PRIMARY KEY CLUSTERED ([GLAccountLeafNodeMappingId] ASC),
    CONSTRAINT [FK_GLAccountLeafNodeMapping_GLAccount] FOREIGN KEY ([GLAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_GLAccountLeafNodeMapping_LeafNode] FOREIGN KEY ([LeafNodeId]) REFERENCES [dbo].[LeafNode] ([LeafNodeId]),
    CONSTRAINT [FK_GLAccountLeafNodeMapping_MasterCompnay] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



