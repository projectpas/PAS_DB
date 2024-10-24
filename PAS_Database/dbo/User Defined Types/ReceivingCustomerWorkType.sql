﻿CREATE TYPE [dbo].[ReceivingCustomerWorkType] AS TABLE (
    [ReceivingCustomerWorkId]    BIGINT          NULL,
    [EmployeeId]                 BIGINT          NULL,
    [CustomerId]                 BIGINT          NULL,
    [ReceivingNumber]            VARCHAR (50)    NULL,
    [CustomerContactId]          BIGINT          NULL,
    [ItemMasterId]               BIGINT          NULL,
    [ManufacturerId]             BIGINT          NULL,
    [RevisePartId]               BIGINT          NULL,
    [IsSerialized]               BIT             NULL,
    [SerialNumber]               VARCHAR (100)   NULL,
    [Quantity]                   INT             NULL,
    [UnitCost]                   DECIMAL (18, 2) NULL,
    [ExtendedCost]               DECIMAL (18, 2) NULL,
    [ConditionId]                BIGINT          NULL,
    [SiteId]                     BIGINT          NULL,
    [WarehouseId]                BIGINT          NULL,
    [LocationId]                 BIGINT          NULL,
    [ShelfId]                    BIGINT          NULL,
    [BinId]                      BIGINT          NULL,
    [OwnerTypeId]                INT             NULL,
    [Owner]                      BIGINT          NULL,
    [IsCustomerStock]            BIT             NULL,
    [TraceableToTypeId]          INT             NULL,
    [TraceableTo]                BIGINT          NULL,
    [ObtainFromTypeId]           INT             NULL,
    [ObtainFrom]                 BIGINT          NULL,
    [IsMFGDate]                  BIT             NULL,
    [MFGDate]                    DATETIME2 (7)   NULL,
    [MFGTrace]                   VARCHAR (100)   NULL,
    [MFGLotNo]                   VARCHAR (100)   NULL,
    [MFGBatchNo]                 VARCHAR (100)   NULL,
    [IsExpDate]                  BIT             NULL,
    [ExpDate]                    DATETIME2 (7)   NULL,
    [IsTimeLife]                 BIT             NULL,
    [TagDate]                    DATETIME2 (7)   NULL,
    [TagType]                    VARCHAR (8000)  NULL,
    [TagTypeId]                  BIGINT          NULL,
    [TimeLifeDate]               DATETIME2 (7)   NULL,
    [TimeLifeOrigin]             VARCHAR (MAX)   NULL,
    [TimeLifeCyclesId]           BIGINT          NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [PartCertificationNumber]    VARCHAR (30)    NULL,
    [ManagementStructureId]      BIGINT          NULL,
    [GLAccountId]                BIGINT          NULL,
    [StockLineId]                BIGINT          NULL,
    [WorkOrderId]                BIGINT          NULL,
    [MasterCompanyId]            INT             NULL,
    [CreatedBy]                  VARCHAR (256)   NULL,
    [UpdatedBy]                  VARCHAR (256)   NULL,
    [CreatedDate]                DATETIME2 (7)   NULL,
    [UpdatedDate]                DATETIME2 (7)   NULL,
    [IsActive]                   BIT             NULL,
    [IsDeleted]                  BIT             NULL,
    [IsSkipSerialNo]             BIT             NULL,
    [IsSkipTimeLife]             BIT             NULL,
    [Reference]                  VARCHAR (256)   NULL,
    [CertifiedBy]                VARCHAR (256)   NULL,
    [ReceivedDate]               DATETIME2 (7)   NULL,
    [CustReqDate]                DATETIME2 (7)   NULL,
    [Level1]                     VARCHAR (200)   NULL,
    [Level2]                     VARCHAR (200)   NULL,
    [Level3]                     VARCHAR (200)   NULL,
    [Level4]                     VARCHAR (200)   NULL,
    [EmployeeName]               VARCHAR (256)   NULL,
    [CustomerName]               VARCHAR (256)   NULL,
    [WorkScopeId]                BIGINT          NULL,
    [CustomerCode]               VARCHAR (100)   NULL,
    [ManufacturerName]           VARCHAR (100)   NULL,
    [InspectedById]              BIGINT          NULL,
    [CertifiedDate]              DATETIME2 (7)   NULL,
    [ObtainFromName]             VARCHAR (256)   NULL,
    [OwnerName]                  VARCHAR (256)   NULL,
    [TraceableToName]            VARCHAR (256)   NULL,
    [PartNumber]                 VARCHAR (250)   NULL,
    [WorkScope]                  VARCHAR (250)   NULL,
    [Condition]                  VARCHAR (100)   NULL,
    [Site]                       VARCHAR (250)   NULL,
    [Warehouse]                  VARCHAR (250)   NULL,
    [Location]                   VARCHAR (250)   NULL,
    [Shelf]                      VARCHAR (250)   NULL,
    [Bin]                        VARCHAR (250)   NULL,
    [InspectedBy]                VARCHAR (100)   NULL,
    [InspectedDate]              DATETIME        NULL,
    [TaggedById]                 BIGINT          NULL,
    [TaggedByName]               VARCHAR (100)   NULL,
    [ACTailNum]                  NVARCHAR (500)  NULL,
    [TaggedByType]               INT             NULL,
    [TaggedByTypeName]           VARCHAR (250)   NULL,
    [CertifiedById]              BIGINT          NULL,
    [CertifiedTypeId]            INT             NULL,
    [CertifiedType]              VARCHAR (250)   NULL,
    [CertTypeId]                 VARCHAR (MAX)   NULL,
    [CertType]                   VARCHAR (MAX)   NULL,
    [RemovalReasonId]            BIGINT          NULL,
    [RemovalReasons]             VARCHAR (200)   NULL,
    [RemovalReasonsMemo]         NVARCHAR (MAX)  NULL,
    [ExchangeSalesOrderId]       BIGINT          NULL,
    [CustReqTagTypeId]           BIGINT          NULL,
    [CustReqTagType]             VARCHAR (100)   NULL,
    [CustReqCertTypeId]          VARCHAR (MAX)   NULL,
    [CustReqCertType]            VARCHAR (MAX)   NULL,
    [RepairOrderPartRecordId]    BIGINT          NULL,
    [IsExchangeBatchEntry]       BIT             NULL,
    [ShippingViaId]              BIGINT          NULL,
    [EngineSerialNumber]         VARCHAR (200)   NULL,
    [ShippingAccount]            VARCHAR (200)   NULL,
    [ShippingReference]          VARCHAR (200)   NULL,
    [TimeLifeDetailsNotProvided] BIT             NULL,
    [PurchaseUnitOfMeasureId]    BIGINT          NULL,
    [GlAccountName]              VARCHAR (200)   NULL,
    [CyclesRemaining]            VARCHAR (20)    NULL,
    [CyclesSinceNew]             VARCHAR (20)    NULL,
    [CyclesSinceOVH]             VARCHAR (20)    NULL,
    [CyclesSinceInspection]      VARCHAR (20)    NULL,
    [CyclesSinceRepair]          VARCHAR (20)    NULL,
    [TimeRemaining]              VARCHAR (20)    NULL,
    [TimeSinceNew]               VARCHAR (20)    NULL,
    [TimeSinceOVH]               VARCHAR (20)    NULL,
    [TimeSinceInspection]        VARCHAR (20)    NULL,
    [TimeSinceRepair]            VARCHAR (20)    NULL,
    [LastSinceNew]               VARCHAR (20)    NULL,
    [LastSinceOVH]               VARCHAR (20)    NULL,
    [LastSinceInspection]        VARCHAR (20)    NULL,
    [IsSkipShippingReference]    BIT             NULL);



