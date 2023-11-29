CREATE TABLE [dbo].[LeafNode] (
    [LeafNodeId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                 VARCHAR (256) NOT NULL,
    [ParentId]             BIGINT        NULL,
    [IsLeafNode]           BIT           NULL,
    [GLAccountId]          VARCHAR (MAX) NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_LeafNode_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_LeafNode_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_LeafNode_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_LeafNode_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReportingStructureId] BIGINT        NULL,
    [IsPositive]           BIT           NULL,
    [SequenceNumber]       BIGINT        NULL,
    CONSTRAINT [PK_LeafNode] PRIMARY KEY CLUSTERED ([LeafNodeId] ASC),
    CONSTRAINT [FK_LeafNode_ReportingStructure] FOREIGN KEY ([ReportingStructureId]) REFERENCES [dbo].[ReportingStructure] ([ReportingStructureId])
);


GO
CREATE TRIGGER [dbo].[Trg_LeafNodeAudit]
   ON  [dbo].[LeafNode]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
INSERT INTO LeafNodeAudit
SELECT * FROM INSERTED
SET NOCOUNT ON;
END