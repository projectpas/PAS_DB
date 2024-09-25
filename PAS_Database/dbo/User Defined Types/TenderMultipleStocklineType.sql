﻿CREATE TYPE [dbo].[TenderMultipleStocklineType] AS TABLE (
    [WorkOrderMaterialsId]    BIGINT          NULL,
    [PartNumber]              VARCHAR (200)   NULL,
    [PartDescription]         VARCHAR (MAX)   NULL,
    [UOM]                     VARCHAR (100)   NULL,
    [Condition]               VARCHAR (256)   NULL,
    [Quantity]                INT             NULL,
    [CustomerName]            VARCHAR (100)   NULL,
    [CustomerCode]            VARCHAR (100)   NULL,
    [IsSerialized]            BIT             NULL,
    [SerialNumberNotProvided] BIT             NULL,
    [SerialNumber]            VARCHAR (150)   NULL,
    [WorkOrderNum]            VARCHAR (30)    NULL,
    [Manufacturer]            VARCHAR (100)   NULL,
    [Receiver]                VARCHAR (150)   NULL,
    [ReceivedDate]            DATETIME2 (7)   NULL,
    [Provision]               VARCHAR (150)   NULL,
    [Site]                    VARCHAR (250)   NULL,
    [WareHouse]               VARCHAR (250)   NULL,
    [Location]                VARCHAR (250)   NULL,
    [Shelf]                   VARCHAR (250)   NULL,
    [Bin]                     VARCHAR (250)   NULL,
    [IsKitType]               BIT             NULL,
    [ItemMasterId]            BIGINT          NULL,
    [UnitOfMeasureId]         BIGINT          NULL,
    [ConditionId]             BIGINT          NULL,
    [CustomerId]              BIGINT          NULL,
    [WorkOrderId]             BIGINT          NULL,
    [Manufacturerid]          BIGINT          NULL,
    [ProvisionId]             BIGINT          NULL,
    [SiteId]                  BIGINT          NULL,
    [WareHouseId]             BIGINT          NULL,
    [LocationId]              BIGINT          NULL,
    [ShelfId]                 BIGINT          NULL,
    [BinId]                   BIGINT          NULL,
    [MasterCompanyId]         INT             NULL,
    [WorkFlowWorkOrderId]     BIGINT          NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [UnitCost]                DECIMAL (18, 2) NULL,
    [EvidenceId]              INT             NULL,
    [Memo]                    VARCHAR (MAX)   NULL,
    [ObtainFromTypeId]        INT             NULL,
    [ObtainFrom]              BIGINT          NULL,
    [ObtainFromName]          VARCHAR (500)   NULL,
    [OwnerTypeId]             INT             NULL,
    [Owner]                   BIGINT          NULL,
    [OwnerName]               VARCHAR (500)   NULL,
    [TraceableToTypeId]       INT             NULL,
    [TraceableTo]             BIGINT          NULL,
    [TraceableToName]         VARCHAR (500)   NULL,
    [InspectionBy]            BIGINT          NULL,
    [InspectionDate]          DATETIME2 (7)   NULL);


