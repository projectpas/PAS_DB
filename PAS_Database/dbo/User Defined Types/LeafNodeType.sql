CREATE TYPE [dbo].[LeafNodeType] AS TABLE (
    [LeafNodeId]           BIGINT        NULL,
    [Name]                 VARCHAR (50)  NULL,
    [ParentId]             BIGINT        NULL,
    [IsLeafNode]           BIT           NULL,
    [GLAccountId]          VARCHAR (MAX) NULL,
    [ReportingStructureId] BIGINT        NULL,
    [IsPositive]           BIT           NULL);

