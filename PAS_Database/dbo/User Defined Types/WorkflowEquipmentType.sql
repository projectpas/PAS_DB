CREATE TYPE [dbo].[WorkflowEquipmentType] AS TABLE (
    [WorkflowEquipmentListId] BIGINT          NULL,
    [WorkflowId]              BIGINT          NULL,
    [AssetId]                 BIGINT          NULL,
    [AssetTypeId]             BIGINT          NULL,
    [AssetDescription]        VARCHAR (500)   NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [PartNumber]              VARCHAR (500)   NULL,
    [TaskId]                  BIGINT          NULL,
    [Order]                   INT             NULL,
    [IsDeleted]               BIT             NULL);

