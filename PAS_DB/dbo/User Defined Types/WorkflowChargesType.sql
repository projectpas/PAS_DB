CREATE TYPE [dbo].[WorkflowChargesType] AS TABLE (
    [WorkflowChargesListId] BIGINT          NULL,
    [WorkflowId]            BIGINT          NULL,
    [WorkflowChargeTypeId]  TINYINT         NULL,
    [Description]           VARCHAR (500)   NULL,
    [Quantity]              TINYINT         NULL,
    [UnitCost]              DECIMAL (18, 2) NULL,
    [ExtendedCost]          DECIMAL (18, 2) NULL,
    [VendorId]              BIGINT          NULL,
    [VendorName]            VARCHAR (256)   NULL,
    [TaskId]                BIGINT          NULL,
    [IsDeleted]             BIT             NULL);

