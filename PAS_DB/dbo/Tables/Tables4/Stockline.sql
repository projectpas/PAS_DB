CREATE TABLE [dbo].[Stockline] (
    [StockLineId]                         BIGINT          IDENTITY (1, 1) NOT NULL,
    [PartNumber]                          VARCHAR (50)    NOT NULL,
    [StockLineNumber]                     VARCHAR (50)    NULL,
    [StocklineMatchKey]                   VARCHAR (100)   NULL,
    [ControlNumber]                       VARCHAR (50)    NULL,
    [ItemMasterId]                        BIGINT          NULL,
    [Quantity]                            INT             NULL,
    [ConditionId]                         BIGINT          NOT NULL,
    [SerialNumber]                        VARCHAR (30)    NULL,
    [ShelfLife]                           BIT             CONSTRAINT [DF_Stockline_ShelfLife] DEFAULT ((0)) NULL,
    [ShelfLifeExpirationDate]             DATETIME2 (7)   NULL,
    [WarehouseId]                         BIGINT          NULL,
    [LocationId]                          BIGINT          NULL,
    [ObtainFrom]                          BIGINT          NULL,
    [Owner]                               BIGINT          NULL,
    [TraceableTo]                         BIGINT          NULL,
    [ManufacturerId]                      BIGINT          NULL,
    [Manufacturer]                        VARCHAR (50)    NULL,
    [ManufacturerLotNumber]               VARCHAR (50)    NULL,
    [ManufacturingDate]                   DATETIME2 (7)   NULL,
    [ManufacturingBatchNumber]            VARCHAR (50)    NULL,
    [PartCertificationNumber]             VARCHAR (50)    NULL,
    [CertifiedBy]                         VARCHAR (100)   NULL,
    [CertifiedDate]                       DATETIME2 (7)   NULL,
    [TagDate]                             DATETIME2 (7)   NULL,
    [TagType]                             VARCHAR (500)   NULL,
    [CertifiedDueDate]                    DATETIME2 (7)   NULL,
    [CalibrationMemo]                     NVARCHAR (MAX)  NULL,
    [OrderDate]                           DATETIME2 (7)   NULL,
    [PurchaseOrderId]                     BIGINT          NULL,
    [PurchaseOrderUnitCost]               DECIMAL (18, 2) CONSTRAINT [DF_Stockline_PurchaseOrderUnitCost] DEFAULT ((0)) NULL,
    [InventoryUnitCost]                   DECIMAL (18, 2) CONSTRAINT [DF_Stockline_InventoryUnitCost] DEFAULT ((0)) NULL,
    [RepairOrderId]                       BIGINT          NULL,
    [RepairOrderUnitCost]                 DECIMAL (18, 2) CONSTRAINT [DF_Stockline_RepairOrderUnitCost] DEFAULT ((0)) NULL,
    [ReceivedDate]                        DATETIME2 (7)   NULL,
    [ReceiverNumber]                      VARCHAR (50)    NULL,
    [ReconciliationNumber]                VARCHAR (50)    NULL,
    [UnitSalesPrice]                      DECIMAL (18, 2) CONSTRAINT [DF_Stockline_UnitSalesPrice] DEFAULT ((0)) NULL,
    [CoreUnitCost]                        DECIMAL (18, 2) CONSTRAINT [DF_Stockline_CoreUnitCost] DEFAULT ((0)) NULL,
    [GLAccountId]                         BIGINT          NULL,
    [AssetId]                             BIGINT          NULL,
    [IsHazardousMaterial]                 BIT             CONSTRAINT [DF_Stockline_IsHazardousMaterial] DEFAULT ((0)) NULL,
    [IsPMA]                               BIT             CONSTRAINT [Stockline_DC_IsPMA] DEFAULT ((0)) NOT NULL,
    [IsDER]                               BIT             CONSTRAINT [Stockline_DC_IsDER] DEFAULT ((0)) NOT NULL,
    [OEM]                                 BIT             CONSTRAINT [Stockline_DC_OEM] DEFAULT ((0)) NOT NULL,
    [Memo]                                NVARCHAR (MAX)  NULL,
    [ManagementStructureId]               BIGINT          NOT NULL,
    [LegalEntityId]                       BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NULL,
    [UpdatedBy]                           VARCHAR (256)   NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_Stockline_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_Stockline_UpdatedDate] DEFAULT (getdate()) NULL,
    [isSerialized]                        BIT             CONSTRAINT [DF_Stockline_isSerialized] DEFAULT ((0)) NULL,
    [ShelfId]                             BIGINT          NULL,
    [BinId]                               BIGINT          NULL,
    [SiteId]                              BIGINT          NOT NULL,
    [ObtainFromType]                      INT             NULL,
    [OwnerType]                           INT             NULL,
    [TraceableToType]                     INT             NULL,
    [UnitCostAdjustmentReasonTypeId]      INT             NULL,
    [UnitSalePriceAdjustmentReasonTypeId] INT             NULL,
    [IdNumber]                            VARCHAR (100)   NULL,
    [QuantityToReceive]                   INT             NULL,
    [PurchaseOrderExtendedCost]           DECIMAL (18)    CONSTRAINT [DF__Stockline__Purch__53E4BFD3] DEFAULT ((0)) NOT NULL,
    [ManufacturingTrace]                  NVARCHAR (200)  NULL,
    [ExpirationDate]                      DATETIME2 (7)   NULL,
    [AircraftTailNumber]                  NVARCHAR (200)  NULL,
    [ShippingViaId]                       BIGINT          NULL,
    [EngineSerialNumber]                  NVARCHAR (200)  NULL,
    [QuantityRejected]                    INT             CONSTRAINT [DF__Stockline__Quant__14BE5EF7] DEFAULT ((0)) NOT NULL,
    [PurchaseOrderPartRecordId]           BIGINT          NULL,
    [ShippingAccount]                     NVARCHAR (200)  NULL,
    [ShippingReference]                   NVARCHAR (200)  NULL,
    [TimeLifeCyclesId]                    BIGINT          NULL,
    [TimeLifeDetailsNotProvided]          BIT             CONSTRAINT [DF__Stockline__TimeL__69BFBDB0] DEFAULT ((0)) NOT NULL,
    [WorkOrderId]                         BIGINT          NULL,
    [WorkOrderMaterialsId]                BIGINT          NULL,
    [QuantityReserved]                    INT             NULL,
    [QuantityTurnIn]                      INT             NULL,
    [QuantityIssued]                      INT             NULL,
    [QuantityOnHand]                      INT             CONSTRAINT [DF_Stockline_QuantityOnHand] DEFAULT ((0)) NOT NULL,
    [QuantityAvailable]                   INT             CONSTRAINT [DF_Stockline_QuantityAvailable] DEFAULT ((0)) NULL,
    [QuantityOnOrder]                     INT             NULL,
    [QtyReserved]                         INT             CONSTRAINT [DF_Stockline_QtyReserved] DEFAULT ((0)) NULL,
    [QtyIssued]                           INT             CONSTRAINT [DF_Stockline_QtyIssued] DEFAULT ((0)) NULL,
    [BlackListed]                         BIT             CONSTRAINT [DF__Stockline__Black__11007AA7] DEFAULT ((0)) NOT NULL,
    [BlackListedReason]                   VARCHAR (MAX)   NULL,
    [Incident]                            BIT             CONSTRAINT [DF__Stockline__Incid__11F49EE0] DEFAULT ((0)) NOT NULL,
    [IncidentReason]                      VARCHAR (MAX)   NULL,
    [Accident]                            BIT             CONSTRAINT [DF__Stockline__Accid__12E8C319] DEFAULT ((0)) NOT NULL,
    [AccidentReason]                      VARCHAR (MAX)   NULL,
    [RepairOrderPartRecordId]             BIGINT          NULL,
    [isActive]                            BIT             CONSTRAINT [DF__Stockline__isAct__13DCE752] DEFAULT ((1)) NOT NULL,
    [isDeleted]                           BIT             CONSTRAINT [DF__Stockline__isDel__14D10B8B] DEFAULT ((0)) NOT NULL,
    [WorkOrderExtendedCost]               DECIMAL (20, 2) NULL,
    [RepairOrderExtendedCost]             DECIMAL (18, 2) NULL,
    [IsCustomerStock]                     BIT             CONSTRAINT [SL_DC_IsCustomerStock] DEFAULT ((0)) NULL,
    [EntryDate]                           DATETIME        CONSTRAINT [DF_Stockline_EntryDate] DEFAULT (getdate()) NULL,
    [LotCost]                             DECIMAL (18, 2) CONSTRAINT [DF_Stockline_LotCost] DEFAULT ((0)) NULL,
    [NHAItemMasterId]                     BIGINT          NULL,
    [TLAItemMasterId]                     BIGINT          NULL,
    [ItemTypeId]                          INT             NULL,
    [AcquistionTypeId]                    BIGINT          NULL,
    [RequestorId]                         BIGINT          NULL,
    [LotNumber]                           VARCHAR (50)    NULL,
    [LotDescription]                      VARCHAR (250)   NULL,
    [TagNumber]                           VARCHAR (50)    NULL,
    [InspectionBy]                        BIGINT          NULL,
    [InspectionDate]                      DATETIME2 (7)   NULL,
    [VendorId]                            BIGINT          NULL,
    [IsParent]                            BIT             CONSTRAINT [DF_Stockline_IsParent] DEFAULT ((1)) NULL,
    [ParentId]                            BIGINT          NULL,
    [IsSameDetailsForAllParts]            BIT             CONSTRAINT [DF_Stockline_IsSameDetailsForAllParts] DEFAULT ((0)) NULL,
    [WorkOrderPartNoId]                   BIGINT          NULL,
    [SubWorkOrderId]                      BIGINT          NULL,
    [SubWOPartNoId]                       BIGINT          NULL,
    [IsOemPNId]                           BIGINT          NULL,
    [PurchaseUnitOfMeasureId]             BIGINT          NOT NULL,
    [ObtainFromName]                      VARCHAR (100)   NULL,
    [OwnerName]                           VARCHAR (100)   NULL,
    [TraceableToName]                     VARCHAR (250)   NULL,
    [Level1]                              VARCHAR (100)   NULL,
    [Level2]                              VARCHAR (100)   NULL,
    [Level3]                              VARCHAR (100)   NULL,
    [Level4]                              VARCHAR (100)   NULL,
    [Condition]                           VARCHAR (100)   NULL,
    [GlAccountName]                       VARCHAR (100)   NULL,
    [Site]                                VARCHAR (100)   NULL,
    [Warehouse]                           VARCHAR (100)   NULL,
    [Location]                            VARCHAR (100)   NULL,
    [Shelf]                               VARCHAR (100)   NULL,
    [Bin]                                 VARCHAR (100)   NULL,
    [UnitOfMeasure]                       VARCHAR (100)   NULL,
    [WorkOrderNumber]                     VARCHAR (500)   NULL,
    [itemGroup]                           VARCHAR (256)   NULL,
    [TLAPartNumber]                       VARCHAR (100)   NULL,
    [NHAPartNumber]                       VARCHAR (100)   NULL,
    [TLAPartDescription]                  NVARCHAR (MAX)  NULL,
    [NHAPartDescription]                  NVARCHAR (MAX)  NULL,
    [itemType]                            VARCHAR (100)   NULL,
    [CustomerId]                          BIGINT          NULL,
    [CustomerName]                        VARCHAR (200)   NULL,
    [isCustomerstockType]                 BIT             CONSTRAINT [Stockline_DC_isCustomerstockType] DEFAULT ((0)) NULL,
    [PNDescription]                       NVARCHAR (MAX)  NULL,
    [RevicedPNId]                         BIGINT          NULL,
    [RevicedPNNumber]                     NVARCHAR (50)   NULL,
    [OEMPNNumber]                         NVARCHAR (50)   NULL,
    [TaggedBy]                            BIGINT          NULL,
    [TaggedByName]                        NVARCHAR (200)  NULL,
    [UnitCost]                            DECIMAL (18, 2) CONSTRAINT [Stockline_DC_UnitCost] DEFAULT ((0)) NULL,
    [TaggedByType]                        INT             NULL,
    [TaggedByTypeName]                    VARCHAR (250)   NULL,
    [CertifiedById]                       BIGINT          NULL,
    [CertifiedTypeId]                     INT             NULL,
    [CertifiedType]                       VARCHAR (250)   NULL,
    [CertTypeId]                          VARCHAR (MAX)   NULL,
    [CertType]                            VARCHAR (MAX)   NULL,
    [TagTypeId]                           BIGINT          NULL,
    [IsFinishGood]                        BIT             CONSTRAINT [DF__tmp_ms_xx__IsFin__7B35F923] DEFAULT ((0)) NULL,
    [IsTurnIn]                            BIT             CONSTRAINT [Stockline_DC_IsTurnIn] DEFAULT ((0)) NULL,
    [IsCustomerRMA]                       BIT             NULL,
    [RMADeatilsId]                        BIGINT          NULL,
    [DaysReceived]                        INT             NULL,
    [ManufacturingDays]                   INT             NULL,
    [TagDays]                             INT             NULL,
    [OpenDays]                            INT             NULL,
    [ExchangeSalesOrderId]                BIGINT          NULL,
    [RRQty]                               INT             CONSTRAINT [DF__tmp_ms_xx__RRQty__7D1E4195] DEFAULT ((0)) NOT NULL,
    [SubWorkOrderNumber]                  VARCHAR (50)    NULL,
    [IsManualEntry]                       BIT             NULL,
    [WorkOrderMaterialsKitId]             BIGINT          NULL,
    [LotId]                               BIGINT          NULL,
    [IsLotAssigned]                       BIT             NULL,
    [LOTQty]                              INT             NULL,
    [LOTQtyReserve]                       INT             NULL,
    [OriginalCost]                        DECIMAL (18, 2) NULL,
    [POOriginalCost]                      DECIMAL (18, 2) NULL,
    [ROOriginalCost]                      DECIMAL (18, 2) NULL,
    [VendorRMAId]                         BIGINT          NULL,
    [VendorRMADetailId]                   BIGINT          NULL,
    [LotMainStocklineId]                  BIGINT          NULL,
    [IsFromInitialPO]                     BIT             NULL,
    [LotSourceId]                         INT             NULL,
    [Adjustment]                          DECIMAL (18, 2) CONSTRAINT [DF_Stockline_Adjustment] DEFAULT ((0)) NULL,
    [SalesOrderPartId]                    BIGINT          NULL,
    [FreightAdjustment]                   DECIMAL (18, 2) CONSTRAINT [DF_Stockline_FreightAdjustment] DEFAULT ((0)) NULL,
    [TaxAdjustment]                       DECIMAL (18, 2) CONSTRAINT [DF_Stockline_TaxAdjustment] DEFAULT ((0)) NULL,
    [IsStkTimeLife]                       BIT             NULL,
    [SalesPriceExpiryDate]                DATETIME2 (7)   NULL,
    [SubWorkOrderMaterialsId]             BIGINT          NULL,
    [SubWorkOrderMaterialsKitId]          BIGINT          NULL,
    [EvidenceId]                          INT             NULL,
    [IntegrationPortal]                   VARCHAR (50)    NULL,
    [IsGenerateReleaseForm]               BIT             CONSTRAINT [DF__tmp_ms_xx__IsGen__46CC5285] DEFAULT ((0)) NULL,
    [ExistingCustomerId]                  BIGINT          NULL,
    [RepairOrderNumber]                   VARCHAR (100)   NULL,
    [ExistingCustomer]                    VARCHAR (200)   NULL,
    [QuickBooksReferenceId]               VARCHAR (200)   NULL,
    [IsUpdated]                           BIT             NULL,
    [LastSyncDate]                        DATETIME2 (7)   NULL,
    [InventoryGLSettingId]                BIGINT          NULL,
    [InventoryGLAccName]                  VARCHAR (255)   NULL,
    [GoodsReceivedNotInvoicesGLAccId]     BIGINT          NULL,
    [GoodsReceivedNotInvoicesGLAccName]   VARCHAR (255)   NULL,
    [WorkInProgressGLAccId]               BIGINT          NULL,
    [WorkInProgressGLAccName]             VARCHAR (255)   NULL,
    [InventoryToBillGLAccId]              BIGINT          NULL,
    [InventoryToBillGLAccName]            VARCHAR (255)   NULL,
    [FinishedGoodsGLAccId]                BIGINT          NULL,
    [FinishedGoodsGLAccName]              VARCHAR (255)   NULL,
    [InventoryExchAgreementGLAccId]       BIGINT          NULL,
    [InventoryExchAgreementGLAccName]     VARCHAR (255)   NULL,
    [InventoryReserveGLAccId]             BIGINT          NULL,
    [InventoryReserveGLAccName]           VARCHAR (255)   NULL,
    [COGS_WorkOrderGLAccId]               BIGINT          NULL,
    [COGS_WorkOrderGLAccName]             VARCHAR (255)   NULL,
    [COGS_SalesOrderGLAccId]              BIGINT          NULL,
    [COGS_SalesOrderGLAccName]            VARCHAR (255)   NULL,
    [COGS_QtyVarianceGLAccId]             BIGINT          NULL,
    [COGS_QtyVarianceGLAccName]           VARCHAR (255)   NULL,
    [COGS_UnitCostVarianceGLAccId]        BIGINT          NULL,
    [COGS_UnitCostVarianceGLAccName]      VARCHAR (255)   NULL,
    [RevenueMroGLAccId]                   BIGINT          NULL,
    [RevenueMroGLAccName]                 VARCHAR (255)   NULL,
    [RevenueSoGLAccId]                    BIGINT          NULL,
    [RevenueSoGLAccName]                  VARCHAR (255)   NULL,
    [RevenueExchGLAccId]                  BIGINT          NULL,
    [RevenueExchGLAccName]                VARCHAR (255)   NULL,
    [COGS_ExchSalesOrderGLAccId]          BIGINT          NULL,
    [COGS_ExchSalesOrderGLAccName]        VARCHAR (255)   NULL,
    [QuantityAdjustment]                  INT             NULL,
    [IsPiecePart]                         BIT             CONSTRAINT [DF_Stockline_IsPiecePart] DEFAULT ((0)) NULL,
    [IsRepairManagement]                  BIT             CONSTRAINT [DF_Stockline_IsRepairManagement] DEFAULT ((0)) NULL,
    [IsDocument]                          BIT             NULL,
    [PurchaseOrderNumber]                 VARCHAR (50)    NULL,
    [IsBatchStock]                        BIT             DEFAULT ((0)) NULL,
    [BatchNumber]                         VARCHAR (50)    NULL,
    [IsReadyReleaseForm]                  BIT             CONSTRAINT [DF_Stockline_IsReadyReleaseForm] DEFAULT ((0)) NULL,
    [AircraftInstalledPartDetailsId]      BIGINT          NULL,
    [AircraftSN]                          VARCHAR (30)    NULL,
    [TotalTSN]                            DECIMAL (18, 2) NULL,
    [TotalCSN]                            DECIMAL (18, 2) NULL,
    [TotalTSNMM]                          DECIMAL (18, 6) NULL,
    [TotalCSNMM]                          DECIMAL (18, 6) NULL,
    [PoPartUnitCost]                      DECIMAL (18, 6) NULL,
    [TransferredFromLotId]                BIGINT          NULL,
    [TransferredFromLotNumber]            VARCHAR (200)   NULL,
    [Note]                                NVARCHAR (MAX)  NULL,
    [IsNonStock]                          BIT             NULL,
    [Currency]                            VARCHAR (100)   NULL,
    [CurrencyId]                          BIGINT          NULL,
    [ItemNonStockClassificationId]        BIGINT          NULL,
    [NonStockClassification]              VARCHAR (100)   NULL,
    [IsService]                           BIT             CONSTRAINT [DF_Stockline_IsService] DEFAULT ((0)) NULL,
    [COGSUnitCost]                        DECIMAL (18, 2) DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Stockline] PRIMARY KEY CLUSTERED ([StockLineId] ASC),
    CONSTRAINT [FK_StockLine_AcquistionType] FOREIGN KEY ([AcquistionTypeId]) REFERENCES [dbo].[AssetAcquisitionType] ([AssetAcquisitionTypeId]),
    CONSTRAINT [FK_StockLine_Bin] FOREIGN KEY ([BinId]) REFERENCES [dbo].[Bin] ([BinId]),
    CONSTRAINT [FK_StockLine_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_StockLine_Employee] FOREIGN KEY ([RequestorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_StockLine_InspectionEmployee] FOREIGN KEY ([InspectionBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_StockLine_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_StockLine_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_StockLine_Manfacturer] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_StockLine_Module] FOREIGN KEY ([ObtainFromType]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_StockLine_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId]),
    CONSTRAINT [FK_StockLine_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_StockLine_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_StockLine_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId]),
    CONSTRAINT [FK_StockLine_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);







GO

GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_Stockline]
    ON [dbo].[Stockline]
    AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH d AS
    (
        SELECT
            d.[StockLineId],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN N'Non-Stock' END AS [Type],
            d.[PartNumber],
            d.[PNDescription],
            d.[Manufacturer],
            d.[Condition],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN d.[IsSerialized] END AS [IsSerialized],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1
                THEN CASE WHEN ISNULL(d.[IsService], 0) = 1 THEN N'Service' ELSE N'Non-Service' END
            END AS [Service],
            d.[StockLineNumber],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[NonStockClassification], '') END AS [NonStockClassification],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), d.[ExpirationDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), d.[ExpirationDate], 126)
            END AS [ExpirationDate],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(daat.[Name], '') END AS [AcquisitionType],
            d.[UnitOfMeasure],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), d.[OrderDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), d.[OrderDate], 126)
            END AS [OrderDate],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), d.[EntryDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), d.[EntryDate], 126)
            END AS [EntryDate],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[PurchaseOrderNumber], '')
                ELSE d.[PurchaseOrderNumber]
            END AS [PurchaseOrderNumber],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(dv.[VendorName], '') END AS [Vendor],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1
                THEN LTRIM(RTRIM(CONCAT(ISNULL(de.[FirstName], ''), ' ', ISNULL(de.[LastName], ''))))
            END AS [Requestor],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[ReceiverNumber], '')
                ELSE d.[ReceiverNumber]
            END AS [ReceiverNumber],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), d.[ReceivedDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), d.[ReceivedDate], 126)
            END AS [ReceivedDate],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN d.[IsHazardousMaterial] END AS [IsHazardousMaterial],
            d.[QuantityOnHand],
            d.[QuantityReserved],
            d.[QuantityIssued],
            d.[QuantityAvailable],
            d.[QuantityAdjustment],
            d.[UnitCost],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[Currency], '') END AS [Currency],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[GlAccountName], '') END AS [GlAccountName],
            d.[Site],
            d.[Warehouse],
            d.[Location],
            d.[Shelf],
            d.[Bin],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(dms.[LastMSLevel], '') END AS [ManagementStructure],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(digs.[StockInventoryName], '') END AS [InventoryGLSettingName],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[InventoryGLAccName], '') END AS [InventoryGLAccName],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[GoodsReceivedNotInvoicesGLAccName], '') END AS [GoodsReceivedNotInvoicesGLAccName],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[RevenueSoGLAccName], '') END AS [RevenueSoGLAccName],
            CASE WHEN ISNULL(d.[IsNonStock], 0) = 1 THEN ISNULL(d.[Memo], '') ELSE d.[Memo] END AS [Memo],
            d.[RevicedPNNumber],
            d.[IsCustomerStock],
            d.[IsRepairManagement],
            d.[IsStkTimeLife],
            d.[IsDocument],
            d.[ControlNumber],
            d.[RepairOrderNumber],
            d.[TraceableTo],
            d.[ObtainFrom],
            d.[TagType],
            d.[TaggedBy],
            d.[TagDate],
            d.[PartCertificationNumber],
            d.[CertifiedBy],
            d.[CertifiedDate],
            d.[UpdatedBy],
            d.[UpdatedDate],
            d.[WorkOrderNumber],
            d.[LotNumber],
            d.[CustomerName],
            d.[BatchNumber],
            d.[SerialNumber],
            d.[itemGroup],
            d.[PurchaseOrderUnitCost],
            d.[RepairOrderUnitCost],
            d.[Adjustment],
            d.[CreatedBy],
            d.[CreatedDate],
            d.[IsActive],
            d.[IsDeleted],
            d.[Note]
        FROM deleted d
        LEFT JOIN [dbo].[AssetAcquisitionType] daat WITH(NOLOCK) ON daat.[AssetAcquisitionTypeId] = d.[AcquistionTypeId]
        LEFT JOIN [dbo].[Vendor] dv WITH(NOLOCK) ON dv.[VendorId] = d.[VendorId]
        LEFT JOIN [dbo].[Employee] de WITH(NOLOCK) ON de.[EmployeeId] = d.[RequestorId]
        LEFT JOIN [dbo].[InventoryGLSetting] digs WITH(NOLOCK) ON digs.[InventoryGLSettingId] = d.[InventoryGLSettingId]
        OUTER APPLY
        (
            SELECT TOP (1) msd.[LastMSLevel]
            FROM [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.[ReferenceID] = d.[StockLineId]
              AND msd.[ModuleID] = 2
              AND ISNULL(msd.[IsDeleted], 0) = 0
            ORDER BY msd.[MSDetailsId] DESC
        ) dms
    ),
    i AS
    (
        SELECT
            i.[StockLineId],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN N'Non-Stock' END AS [Type],
            i.[PartNumber],
            i.[PNDescription],
            i.[Manufacturer],
            i.[Condition],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN i.[IsSerialized] END AS [IsSerialized],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1
                THEN CASE WHEN ISNULL(i.[IsService], 0) = 1 THEN N'Service' ELSE N'Non-Service' END
            END AS [Service],
            i.[StockLineNumber],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[NonStockClassification], '') END AS [NonStockClassification],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), i.[ExpirationDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), i.[ExpirationDate], 126)
            END AS [ExpirationDate],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(iaat.[Name], '') END AS [AcquisitionType],
            i.[UnitOfMeasure],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), i.[OrderDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), i.[OrderDate], 126)
            END AS [OrderDate],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), i.[EntryDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), i.[EntryDate], 126)
            END AS [EntryDate],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[PurchaseOrderNumber], '')
                ELSE i.[PurchaseOrderNumber]
            END AS [PurchaseOrderNumber],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(iv.[VendorName], '') END AS [Vendor],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1
                THEN LTRIM(RTRIM(CONCAT(ISNULL(ie.[FirstName], ''), ' ', ISNULL(ie.[LastName], ''))))
            END AS [Requestor],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[ReceiverNumber], '')
                ELSE i.[ReceiverNumber]
            END AS [ReceiverNumber],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(CONVERT(NVARCHAR(33), i.[ReceivedDate], 126), '')
                ELSE CONVERT(NVARCHAR(33), i.[ReceivedDate], 126)
            END AS [ReceivedDate],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN i.[IsHazardousMaterial] END AS [IsHazardousMaterial],
            i.[QuantityOnHand],
            i.[QuantityReserved],
            i.[QuantityIssued],
            i.[QuantityAvailable],
            i.[QuantityAdjustment],
            i.[UnitCost],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[Currency], '') END AS [Currency],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[GlAccountName], '') END AS [GlAccountName],
            i.[Site],
            i.[Warehouse],
            i.[Location],
            i.[Shelf],
            i.[Bin],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(ims.[LastMSLevel], '') END AS [ManagementStructure],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(iigs.[StockInventoryName], '') END AS [InventoryGLSettingName],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[InventoryGLAccName], '') END AS [InventoryGLAccName],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[GoodsReceivedNotInvoicesGLAccName], '') END AS [GoodsReceivedNotInvoicesGLAccName],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[RevenueSoGLAccName], '') END AS [RevenueSoGLAccName],
            CASE WHEN ISNULL(i.[IsNonStock], 0) = 1 THEN ISNULL(i.[Memo], '') ELSE i.[Memo] END AS [Memo],
            i.[RevicedPNNumber],
            i.[IsCustomerStock],
            i.[IsRepairManagement],
            i.[IsStkTimeLife],
            i.[IsDocument],
            i.[ControlNumber],
            i.[RepairOrderNumber],
            i.[TraceableTo],
            i.[ObtainFrom],
            i.[TagType],
            i.[TaggedBy],
            i.[TagDate],
            i.[PartCertificationNumber],
            i.[CertifiedBy],
            i.[CertifiedDate],
            i.[UpdatedBy],
            i.[UpdatedDate],
            i.[WorkOrderNumber],
            i.[LotNumber],
            i.[CustomerName],
            i.[BatchNumber],
            i.[SerialNumber],
            i.[itemGroup],
            i.[PurchaseOrderUnitCost],
            i.[RepairOrderUnitCost],
            i.[Adjustment],
            i.[CreatedBy],
            i.[CreatedDate],
            i.[IsActive],
            i.[IsDeleted],
            i.[Note]
        FROM inserted i
        LEFT JOIN [dbo].[AssetAcquisitionType] iaat WITH(NOLOCK) ON iaat.[AssetAcquisitionTypeId] = i.[AcquistionTypeId]
        LEFT JOIN [dbo].[Vendor] iv WITH(NOLOCK) ON iv.[VendorId] = i.[VendorId]
        LEFT JOIN [dbo].[Employee] ie WITH(NOLOCK) ON ie.[EmployeeId] = i.[RequestorId]
        LEFT JOIN [dbo].[InventoryGLSetting] iigs WITH(NOLOCK) ON iigs.[InventoryGLSettingId] = i.[InventoryGLSettingId]
        OUTER APPLY
        (
            SELECT TOP (1) msd.[LastMSLevel]
            FROM [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK)
            WHERE msd.[ReferenceID] = i.[StockLineId]
              AND msd.[ModuleID] = 2
              AND ISNULL(msd.[IsDeleted], 0) = 0
            ORDER BY msd.[MSDetailsId] DESC
        ) ims
    ),
    paired AS
    (
        SELECT
            COALESCE(i.[StockLineId], d.[StockLineId]) AS [StockLineId],
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS [old_row_json],
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS [new_row_json],
            CASE
                WHEN i.[StockLineId] IS NOT NULL AND d.[StockLineId] IS NOT NULL THEN 'U'
                WHEN i.[StockLineId] IS NOT NULL AND d.[StockLineId] IS NULL THEN 'I'
                WHEN i.[StockLineId] IS NULL AND d.[StockLineId] IS NOT NULL THEN 'D'
            END AS [Action],
            (SELECT COALESCE(i.[StockLineId], d.[StockLineId]) AS [StockLineId]
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS [PKJson]
        FROM d
        FULL OUTER JOIN i ON i.[StockLineId] = d.[StockLineId]
    ),
    oldv AS
    (
        SELECT
            p.[PKJson],
            p.[StockLineId],
            v.[key] AS [ColumnName],
            v.[value] AS [OldValue]
        FROM paired p
        CROSS APPLY OPENJSON(p.[old_row_json]) v
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [dbo].[IgnoreColumn] ign
            WHERE ign.[SchemaName] = N'dbo'
              AND ign.[TableName] = N'Stockline'
              AND ign.[ColumnName] = N'StockLineId'
        )
    ),
    newv AS
    (
        SELECT
            p.[PKJson],
            p.[StockLineId],
            v.[key] AS [ColumnName],
            v.[value] AS [NewValue]
        FROM paired p
        CROSS APPLY OPENJSON(p.[new_row_json]) v
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM [dbo].[IgnoreColumn] ign
            WHERE ign.[SchemaName] = N'dbo'
              AND ign.[TableName] = N'Stockline'
              AND ign.[ColumnName] = N'StockLineId'
        )
    ),
    merged AS
    (
        SELECT
            COALESCE(n.[PKJson], o.[PKJson]) AS [PKJson],
            COALESCE(n.[ColumnName], o.[ColumnName]) AS [ColumnName],
            o.[OldValue],
            n.[NewValue],
            p.[Action]
        FROM paired p
        LEFT JOIN oldv o ON o.[StockLineId] = p.[StockLineId]
        LEFT JOIN newv n ON n.[StockLineId] = p.[StockLineId]
            AND n.[ColumnName] = o.[ColumnName]

        UNION ALL

        SELECT
            n.[PKJson],
            n.[ColumnName],
            NULL AS [OldValue],
            n.[NewValue],
            p.[Action]
        FROM paired p
        LEFT JOIN newv n ON n.[StockLineId] = p.[StockLineId]
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM oldv o2
            WHERE o2.[StockLineId] = p.[StockLineId]
              AND o2.[ColumnName] = n.[ColumnName]
        )
    )
    INSERT INTO [dbo].[AuditLog]
    (
        [SchemaName], [TableName], [PKJson], [ColumnName], [Action], [OldValue], [NewValue]
    )
    SELECT
        N'dbo',
        N'Stockline',
        m.[PKJson],
        m.[ColumnName],
        m.[Action],
        m.[OldValue],
        m.[NewValue]
    FROM merged m
    WHERE m.[ColumnName] <> 'StockLineId'
      AND
      (
          (m.[Action] = 'U' AND
          (
              (m.[OldValue] IS NULL AND m.[NewValue] IS NOT NULL)
              OR (m.[OldValue] IS NOT NULL AND m.[NewValue] IS NULL)
              OR (m.[OldValue] <> m.[NewValue])
          ))
          OR (m.[Action] = 'I' AND m.[NewValue] IS NOT NULL)
          OR (m.[Action] = 'D' AND m.[OldValue] IS NOT NULL)
      );
END;

GO
CREATE NONCLUSTERED INDEX [IX_Stockline_TaggedByName]
    ON [dbo].[Stockline]([TaggedByName] ASC)
    INCLUDE([TaggedByType], [TaggedByTypeName], [MasterCompanyId]) WHERE ([TaggedByName] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_ROPartRec_Perf]
    ON [dbo].[Stockline]([RepairOrderPartRecordId] ASC)
    INCLUDE([IsNonStock], [PartNumber], [PNDescription], [CreatedBy], [CreatedDate], [RepairOrderUnitCost]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_ROPartRec_Created_Perf]
    ON [dbo].[Stockline]([RepairOrderPartRecordId] ASC, [IsNonStock] ASC, [CreatedDate] ASC)
    INCLUDE([PartNumber], [PNDescription], [CreatedBy], [RepairOrderUnitCost], [StockLineId]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_POPartRec_Perf]
    ON [dbo].[Stockline]([PurchaseOrderPartRecordId] ASC)
    INCLUDE([IsNonStock], [PartNumber], [PNDescription], [CreatedBy], [CreatedDate]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_POPartRec_Created_Perf]
    ON [dbo].[Stockline]([PurchaseOrderPartRecordId] ASC, [IsNonStock] ASC, [CreatedDate] ASC)
    INCLUDE([PartNumber], [PNDescription], [CreatedBy], [StockLineId]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_Created_ROPartRec_Perf]
    ON [dbo].[Stockline]([CreatedDate] ASC, [RepairOrderPartRecordId] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_Created_POPartRec_Perf]
    ON [dbo].[Stockline]([CreatedDate] ASC, [PurchaseOrderPartRecordId] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_StockReport]
    ON [dbo].[Stockline]([MasterCompanyId] ASC, [IsParent] ASC, [isDeleted] ASC, [CreatedDate] ASC)
    INCLUDE([StockLineId], [ItemMasterId], [GLAccountId], [IsNonStock], [IsCustomerStock], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [QuantityOnHand], [QuantityReserved], [QuantityAvailable], [Quantity]);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_Report]
    ON [dbo].[Stockline]([MasterCompanyId] ASC, [IsParent] ASC, [isDeleted] ASC, [CreatedDate] ASC)
    INCLUDE([StockLineId], [ItemMasterId], [SiteId], [WarehouseId], [LocationId], [ShelfId], [BinId], [QuantityOnHand], [QuantityAvailable], [QuantityReserved], [PurchaseOrderId], [RepairOrderId], [VendorId], [CustomerId], [GLAccountId], [IsCustomerStock], [IsNonStock]);


GO
CREATE NONCLUSTERED INDEX [IX_Stockline_GL_Probe]
    ON [dbo].[Stockline]([GLAccountId] ASC, [MasterCompanyId] ASC, [IsParent] ASC, [isDeleted] ASC)
    INCLUDE([IsNonStock], [CreatedDate]);

