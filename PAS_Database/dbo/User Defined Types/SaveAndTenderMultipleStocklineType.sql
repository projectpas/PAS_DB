﻿CREATE TYPE [dbo].[SaveAndTenderMultipleStocklineType] AS TABLE (
    [IsMaterialStocklineCreate] BIT             NULL,
    [IsCustomerStock]           BIT             NULL,
    [IsCustomerstockType]       BIT             NULL,
    [ItemMasterId]              BIGINT          NULL,
    [UnitOfMeasureId]           BIGINT          NULL,
    [ConditionId]               BIGINT          NULL,
    [Quantity]                  INT             NULL,
    [IsSerialized]              BIT             NULL,
    [SerialNumber]              VARCHAR (150)   NULL,
    [CustomerId]                BIGINT          NULL,
    [ObtainFromTypeId]          INT             NULL,
    [ObtainFrom]                BIGINT          NULL,
    [ObtainFromName]            VARCHAR (500)   NULL,
    [OwnerTypeId]               INT             NULL,
    [Owner]                     BIGINT          NULL,
    [OwnerName]                 VARCHAR (500)   NULL,
    [TraceableToTypeId]         INT             NULL,
    [TraceableTo]               BIGINT          NULL,
    [TraceableToName]           VARCHAR (500)   NULL,
    [Memo]                      VARCHAR (MAX)   NULL,
    [WorkOrderId]               BIGINT          NULL,
    [WorkOrderNumber]           VARCHAR (50)    NULL,
    [ManufacturerId]            BIGINT          NULL,
    [InspectedById]             BIGINT          NULL,
    [InspectedDate]             DATETIME2 (7)   NULL,
    [ReceiverNumber]            VARCHAR (500)   NULL,
    [ReceivedDate]              DATETIME2 (7)   NULL,
    [ManagementStructureId]     BIGINT          NULL,
    [SiteId]                    BIGINT          NULL,
    [WarehouseId]               BIGINT          NULL,
    [LocationId]                BIGINT          NULL,
    [ShelfId]                   BIGINT          NULL,
    [BinId]                     BIGINT          NULL,
    [MasterCompanyId]           BIGINT          NULL,
    [UpdatedBy]                 VARCHAR (100)   NULL,
    [WorkOrderMaterialsId]      BIGINT          NULL,
    [IsKitType]                 BIT             NULL,
    [Unitcost]                  DECIMAL (18, 2) NULL,
    [ProvisionId]               INT             NULL,
    [EvidenceId]                INT             NULL);

