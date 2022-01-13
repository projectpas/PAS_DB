﻿CREATE TYPE [dbo].[VendorRFQRepairOrderPartType] AS TABLE (
    [VendorRFQROPartRecordId] BIGINT          NULL,
    [VendorRFQRepairOrderId]  BIGINT          NULL,
    [ItemMasterId]            BIGINT          NULL,
    [PartNumber]              VARCHAR (250)   NULL,
    [PartDescription]         VARCHAR (MAX)   NULL,
    [AltEquiPartNumberId]     BIGINT          NULL,
    [AltEquiPartNumber]       VARCHAR (250)   NULL,
    [AltEquiPartDescription]  VARCHAR (MAX)   NULL,
    [RevisedPartId]           BIGINT          NULL,
    [RevisedPartNumber]       VARCHAR (250)   NULL,
    [StockType]               VARCHAR (50)    NULL,
    [ManufacturerId]          BIGINT          NULL,
    [Manufacturer]            VARCHAR (250)   NULL,
    [PriorityId]              BIGINT          NULL,
    [Priority]                VARCHAR (50)    NULL,
    [NeedByDate]              DATETIME2 (7)   NULL,
    [PromisedDate]            DATETIME2 (7)   NULL,
    [ConditionId]             BIGINT          NULL,
    [Condition]               VARCHAR (256)   NULL,
    [WorkPerformedId]         BIGINT          NULL,
    [WorkPerformed]           VARCHAR (250)   NULL,
    [QuantityOrdered]         INT             NULL,
    [UnitCost]                DECIMAL (20, 2) NULL,
    [ExtendedCost]            DECIMAL (20, 2) NULL,
    [WorkOrderId]             BIGINT          NULL,
    [WorkOrderNo]             VARCHAR (250)   NULL,
    [SubWorkOrderId]          BIGINT          NULL,
    [SubWorkOrderNo]          VARCHAR (250)   NULL,
    [SalesOrderId]            BIGINT          NULL,
    [SalesOrderNo]            VARCHAR (250)   NULL,
    [ItemTypeId]              INT             NULL,
    [ItemType]                VARCHAR (100)   NULL,
    [UOMId]                   BIGINT          NULL,
    [UnitOfMeasure]           VARCHAR (250)   NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [Level1]                  VARCHAR (200)   NULL,
    [Level2]                  VARCHAR (200)   NULL,
    [Level3]                  VARCHAR (200)   NULL,
    [Level4]                  VARCHAR (200)   NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]         INT             NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   NULL,
    [UpdatedDate]             DATETIME2 (7)   NULL,
    [IsActive]                BIT             NULL,
    [IsDeleted]               BIT             NULL);

