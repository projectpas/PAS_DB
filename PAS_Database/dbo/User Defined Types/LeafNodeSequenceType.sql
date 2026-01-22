CREATE TYPE [dbo].[LeafNodeSequenceType] AS TABLE (
    [LeafNodeId]           BIGINT        NULL,
    [Name]                 VARCHAR (256) NULL,
    [PrintSequenceNumber]  INT           NULL,
    [MasterCompanyId]      INT           NULL,
    [ReportingStructureId] BIGINT        NULL);

