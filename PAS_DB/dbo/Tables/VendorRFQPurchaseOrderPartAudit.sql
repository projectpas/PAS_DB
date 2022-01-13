﻿CREATE TABLE [dbo].[VendorRFQPurchaseOrderPartAudit] (
    [VendorRFQPOPartRecordAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQPOPartRecordId]      BIGINT          NOT NULL,
    [VendorRFQPurchaseOrderId]     BIGINT          NOT NULL,
    [ItemMasterId]                 BIGINT          NOT NULL,
    [PartNumber]                   VARCHAR (250)   NULL,
    [PartDescription]              VARCHAR (MAX)   NULL,
    [StockType]                    VARCHAR (50)    NULL,
    [ManufacturerId]               BIGINT          NOT NULL,
    [Manufacturer]                 VARCHAR (250)   NULL,
    [PriorityId]                   BIGINT          CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_PriorityId] DEFAULT ((0)) NOT NULL,
    [Priority]                     VARCHAR (50)    NULL,
    [NeedByDate]                   DATETIME2 (7)   NOT NULL,
    [PromisedDate]                 DATETIME2 (7)   NULL,
    [ConditionId]                  BIGINT          NULL,
    [Condition]                    VARCHAR (256)   NULL,
    [QuantityOrdered]              INT             CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_QuantityOrdered] DEFAULT ((0)) NOT NULL,
    [UnitCost]                     DECIMAL (18, 2) CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_UnitCost] DEFAULT ((0)) NOT NULL,
    [ExtendedCost]                 DECIMAL (18, 2) CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_ExtendedCost] DEFAULT ((0)) NOT NULL,
    [WorkOrderId]                  BIGINT          NULL,
    [WorkOrderNo]                  VARCHAR (250)   NULL,
    [SubWorkOrderId]               BIGINT          NULL,
    [SubWorkOrderNo]               VARCHAR (250)   NULL,
    [SalesOrderId]                 BIGINT          NULL,
    [SalesOrderNo]                 VARCHAR (250)   NULL,
    [ManagementStructureId]        BIGINT          NOT NULL,
    [Level1]                       VARCHAR (200)   NULL,
    [Level2]                       VARCHAR (200)   NULL,
    [Level3]                       VARCHAR (200)   NULL,
    [Level4]                       VARCHAR (200)   NULL,
    [Memo]                         NVARCHAR (MAX)  NULL,
    [MasterCompanyId]              INT             NULL,
    [CreatedBy]                    VARCHAR (256)   NOT NULL,
    [UpdatedBy]                    VARCHAR (256)   NOT NULL,
    [CreatedDate]                  DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_VendorRFQPurchaseOrderPartAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PurchaseOrderId]              BIGINT          NULL,
    [PurchaseOrderNumber]          VARCHAR (50)    NULL,
    [UOMId]                        BIGINT          NULL,
    [UnitOfMeasure]                VARCHAR (50)    NULL,
    CONSTRAINT [PK_VendorRFQPurchaseOrderPartAudit] PRIMARY KEY CLUSTERED ([VendorRFQPOPartRecordAuditId] ASC)
);

