CREATE TYPE [dbo].[WorkOrderMaterialKitType] AS TABLE (
    [WorkOrderMaterialKitMappingId] BIGINT          NULL,
    [WorkOrderId]                   BIGINT          NULL,
    [WOPartNoId]                    BIGINT          NULL,
    [WorkflowWorkOrderId]           BIGINT          NULL,
    [KitId]                         BIGINT          NULL,
    [KitNumber]                     VARCHAR (256)   NULL,
    [ItemMasterId]                  BIGINT          NULL,
    [Quantity]                      INT             NULL,
    [UnitCost]                      DECIMAL (18, 2) NULL,
    [MasterCompanyId]               INT             NULL,
    [CreatedBy]                     VARCHAR (256)   NULL,
    [UpdatedBy]                     VARCHAR (256)   NULL,
    [CreatedDate]                   DATETIME2 (7)   NULL,
    [UpdatedDate]                   DATETIME2 (7)   NULL,
    [IsActive]                      BIT             NULL,
    [IsDeleted]                     BIT             NULL);

