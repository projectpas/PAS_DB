﻿CREATE TYPE [dbo].[WorkOrderMaterialListType] AS TABLE (
    [WorkOrderMaterialsId]       BIGINT          NULL,
    [WorkOrderId]                BIGINT          NULL,
    [WorkFlowWorkOrderId]        BIGINT          NULL,
    [ItemMasterId]               BIGINT          NULL,
    [TaskId]                     BIGINT          NULL,
    [ConditionCodeId]            SMALLINT        NULL,
    [ItemClassificationId]       BIGINT          NULL,
    [Quantity]                   SMALLINT        NULL,
    [UnitOfMeasureId]            BIGINT          NULL,
    [UnitCost]                   DECIMAL (18, 2) NULL,
    [ExtendedCost]               DECIMAL (18, 2) NULL,
    [Memo]                       VARCHAR (500)   NULL,
    [IsDeferred]                 BIT             NULL,
    [QuantityReserved]           INT             NULL,
    [QuantityIssued]             INT             NULL,
    [IssuedById]                 INT             NULL,
    [IssuedDate]                 DATETIME        NULL,
    [ReservedById]               INT             NULL,
    [ReservedDate]               DATETIME        NULL,
    [IsAltPart]                  BIT             NULL,
    [AltPartMasterPartId]        BIGINT          NULL,
    [PartStatusId]               INT             NULL,
    [UnReservedQty]              INT             NULL,
    [UnIssuedQty]                INT             NULL,
    [ParentWorkOrderMaterialsId] BIGINT          NULL,
    [ItemMappingId]              BIGINT          NULL,
    [TotalReserved]              INT             NULL,
    [TotalIssued]                INT             NULL,
    [TotalUnReserved]            INT             NULL,
    [TotalUnIssued]              INT             NULL,
    [ProvisionId]                INT             NULL,
    [MaterialMandatoriesId]      INT             NULL,
    [IsFromWorkFlow]             BIT             NULL,
    [IsEquPart]                  BIT             NULL,
    [IsDeleted]                  BIT             NULL);

