
/*************************************************************
** Author:       Hemant Saliya
** Create date:  07/30/2021
** Description:  Creates Turn-In/Tender Materials Stockline for Work Orders

** Change History
** PR   Date        Author              Change Description
** --   --------    -------             --------------------------------
   1    07/30/2021  Hemant Saliya        Initial Draft
   2    05/11/2023  Vishal Suthar        Added KIT stockline tender portion
   3    05/23/2023  Subhash Saliya       Added Unit Cost portion
   4    06/05/2023  Moin Bloch           Updated TendorStocklineCost (Qty * UnitCost)
   5    07/30/2021  Hemant Saliya        Updated Teardown text
   6    06/09/2023  Moin Bloch           Updated unit cost of old stockline on tender
   7    06/14/2023  Devendra Shekh       Changed to udfGenerateCodeNumberWithOutDash
   8    10/16/2023  Devendra Shekh       Timelife issue resolved
   9    10/16/2023  Devendra Shekh       Updated WOPartNoId for insert stockline
   10   03/05/2024  Bhargav Saliya       UTC Date Changes
   11   22/03/2024  Moin Bloch           Added @EvidenceId field
   12   02/04/2024  Moin Bloch           Updated Inventory History Notes: Turn in -> Tendered
   13   04/04/2024  Moin Bloch           Fixed CurrentSerialNumber issue
   14   30/07/2024  Devendra Shekh       Tender Stockline issue resolved
   15   27/09/2024  Devendra Shekh       Commented USP_CreateChildStockline
   16   04/14/2025  Hemant Saliya        Added WorkOrderWorkFlowId for UpdateWOMaterialsCost
   17   18/04/2025  Abhishek Jirawla     Added Integration Portal in Stockline
   18   08/10/2025  Moin Bloch           Added MPN Tender
   19   30/01/2026  Moin Bloch           Fix FK Conflict Error in Bin
   20   10/02/2026  Moin Bloch           No cost removal on tender; added Accounting Entry for Teardown (PN-15331)
   21   13/03/2026  Rajesh Gami          UOM Changes Added (PN-15714)
   22   26/03/2026  Moin Bloch           Renamed TearDown -> Internal Teardown (PN-15850)
   23   07/05/2026  Nakul Chandigra      Added AircraftTail and AircraftSN fields in Stockline (PN-16315)
   24   26/05/2026  Hemant Saliya        Lot Trans-In for tender stockline when MPN stockline is a Lot stockline
   25   26/05/2026  Hemant Saliya        Performance optimization and code cleanup
   26   26/05/2026  Nakul Chandigra      Sync the stored procedure from PROD to UAT.
   27   27/05/2026  Nakul Chandigra      Sync the stored procedure from PROD to UAT.

**************************************************************/
CREATE PROCEDURE [dbo].[usp_SaveTurnInWorkOrderMaterils]
    @IsMaterialStocklineCreate  BIT             = 0,
    @IsCustomerStock            BIT             = 0,
    @IsCustomerstockType        BIT,
    @ItemMasterId               BIGINT,
    @UnitOfMeasureId            BIGINT,
    @ConditionId                BIGINT,
    @Quantity                   DECIMAL(18,6),        
    @IsSerialized               BIT,
    @SerialNumber               VARCHAR(50),
    @CustomerId                 BIGINT          = NULL,
    @ObtainFromTypeId           INT             = NULL,
    @ObtainFrom                 BIGINT          = NULL,
    @ObtainFromName             VARCHAR(500)    = NULL,
    @OwnerTypeId                INT             = NULL,
    @Owner                      BIGINT          = NULL,
    @OwnerName                  VARCHAR(500)    = NULL,
    @TraceableToTypeId          INT             = NULL,
    @TraceableTo                BIGINT          = NULL,
    @TraceableToName            VARCHAR(500)    = NULL,
    @Memo                       VARCHAR(MAX),
    @WorkOrderId                BIGINT,
    @WorkOrderNumber            VARCHAR(50),
    @ManufacturerId             BIGINT,
    @InspectedById              BIGINT          = NULL,
    @InspectedDate              DATETIME2(7)    = NULL,
    @ReceiverNumber             VARCHAR(500),
    @ReceivedDate               DATETIME2(7),
    @ManagementStructureId      BIGINT,
    @SiteId                     BIGINT,
    @WarehouseId                BIGINT          = NULL,
    @LocationId                 BIGINT          = NULL,
    @ShelfId                    BIGINT          = NULL,
    @BinId                      BIGINT          = NULL,
    @MasterCompanyId            BIGINT,
    @UpdatedBy                  VARCHAR(100),
    @WorkOrderMaterialsId       BIGINT          = 0,
    @IsKitType                  BIT             = 0,
    @Unitcost                   DECIMAL(18,6)   = 0,   
    @ProvisionId                INT             = 0,
    @EvidenceId                 INT             = NULL,
    @WorkOrderWorkflowId        BIGINT          = NULL,
    @IsMPNTendor                BIT             = 0,
    @AircraftTail               VARCHAR(400)    = NULL,
    @AircraftSN                 VARCHAR(30)     = NULL
AS
BEGIN

    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- =============================================
    -- VARIABLE DECLARATIONS
    -- =============================================
    DECLARE
        @PartNumber                 VARCHAR(500),
        @WorkOrderNum               VARCHAR(500),
        @SLCurrentNummber           BIGINT,
        @StockLineNumber            VARCHAR(50),
        @CNCurrentNummber           BIGINT,
        @ControlNumber              VARCHAR(50),
        @IDCurrentNummber           BIGINT,
        @IDNumber                   VARCHAR(50),
        @NewWorkOrderMaterialsId    BIGINT,
        @StockLineId                BIGINT,
        @MSModuleID                 INT             = 2,    -- Stockline Module ID
        @IsPMA                      BIT             = 0,
        @IsDER                      BIT             = 0,
        @IsOemPNId                  BIGINT,
        @IsOEM                      BIT             = 0,
        @OEMPNNumber                VARCHAR(500),
        @IsAddUpdate                BIT,
        @ExecuteParentChild         BIT,
        @UpdateQuantities           BIT,
        @IsOHUpdated                BIT,
        @AddHistoryForNonSerialized BIT,
        @SubReferenceId             BIGINT,
        @ModuleId                   BIGINT,
        @SubModuleId                BIGINT,
        @GLAccountId                INT,
        @IsTimeLife                 BIT,
        -- UOM variables resolved from ItemMaster (PN-15714)
        @StockUOMId                 BIGINT,
        @PurchaseUOMId              BIGINT,
        @ConsumeUOMId               BIGINT,
        -- Qty tracking: DECIMAL(18,6) to match @Quantity precision
        @QtyTendered                DECIMAL(18,6)   = 0,
        @QtyToTendered              DECIMAL(18,6)   = 0,
        @TotalStlQtyReq             DECIMAL(18,6)   = 0,
        @WorkOrderTypeId            INT             = 0,
        @TearDownWorkOrderTypeId    INT             = 0,
        @WorkOrderPartNoId          BIGINT          = 0,
        @ItemClassificationId       BIGINT          = 0,
        @WorkOrderFormTypeId        BIT             = 0,
        -- Lot support
        @MPNStockLineId             BIGINT          = 0,
        @SourceLotId                BIGINT          = 0,
        @LotCreatedDate             DATETIME,
        @IntegrationPortal          VARCHAR(50),
        @OLDStockLineId             BIGINT          = 0,
        @DistributionMasterId       BIGINT          = NULL,
        @ActionId                   INT             = 0,
        @HistoryModuleId            INT             = 0,
        @currentNo                  BIGINT,
        @stockLineCurrentNo         BIGINT,
        @isExchange                 BIT;

    -- Initialise StockUOMId from input (may be overridden by ItemMaster values below)
    SET @StockUOMId = @UnitOfMeasureId;

    BEGIN TRY
    BEGIN TRANSACTION;

        -- =============================================
        -- STEP 0: NORMALIZE NULLABLE INPUTS
        -- =============================================
        SET @TraceableTo    = NULLIF(@TraceableTo,   0);
        SET @InspectedById  = NULLIF(@InspectedById, 0);
        SET @WarehouseId    = NULLIF(@WarehouseId,   0);
        SET @LocationId     = NULLIF(@LocationId,    0);
        SET @ShelfId        = NULLIF(@ShelfId,       0);
        SET @BinId          = NULLIF(@BinId,         0);

        SET @IsAddUpdate                = 1;
        SET @ExecuteParentChild         = 1;
        SET @UpdateQuantities           = 0;
        SET @IsOHUpdated                = 0;
        SET @AddHistoryForNonSerialized = 0;

        -- =============================================
        -- STEP 1: LOAD LOOKUP DATA
        -- =============================================
        SELECT @isExchange = CASE WHEN UPPER([StatusCode]) = 'EXCHANGE' THEN 1 ELSE 0 END
        FROM [dbo].[Provision] WITH(NOLOCK)
        WHERE [ProvisionId] = @ProvisionId;

        SELECT @ModuleId    = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'StockLine';
        SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMaterials';

        SELECT
            @PurchaseUOMId          = PurchaseUnitOfMeasureId,
            @ConsumeUOMId           = ConsumeUnitOfMeasureId,
            @PartNumber             = PartNumber,
            @IsPMA                  = IsPMA,
            @IsDER                  = IsDER,
            @IsOemPNId              = IsOemPNId,
            @IsOEM                  = IsOEM,
            @OEMPNNumber            = OEMPN,
            @GLAccountId            = GLAccountId,
            @IsTimeLife             = isTimeLife,
            @ItemClassificationId   = ItemClassificationId
        FROM dbo.ItemMaster WITH(NOLOCK)
        WHERE ItemMasterId = @ItemMasterId;

        SELECT
            @WorkOrderNum           = WorkOrderNum,
            @WorkOrderTypeId        = WorkOrderTypeId,
            @WorkOrderFormTypeId    = ISNULL(WorkOrderFormTypeId, 0)
        FROM [dbo].[WorkOrder] WITH(NOLOCK)
        WHERE WorkOrderId = @WorkOrderId;

        SELECT @TearDownWorkOrderTypeId = [Id]
        FROM [dbo].[WorkOrderType] WITH(NOLOCK)
        WHERE [Description] = 'Internal Teardown';

        -- Zero out unit cost for non-teardown WOs
        IF @WorkOrderTypeId != @TearDownWorkOrderTypeId
            SET @Unitcost = 0;

        -- =============================================
        -- STEP 2: RESOLVE WORKFLOW & PART NUMBER IDs
        -- =============================================
        IF ISNULL(@IsMPNTendor, 0) = 0
        BEGIN
            IF ISNULL(@IsKitType, 0) = 0
                SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId
                FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK)
                WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;
            ELSE
                SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId
                FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK)
                WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;
        END

        SELECT @WorkOrderPartNoId = WorkOrderPartNoId
        FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK)
        WHERE WorkFlowWorkOrderId = @WorkOrderWorkflowId;

        SELECT @MPNStockLineId = StocklineId
        FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
        WHERE ID = @WorkOrderPartNoId;

        -- =============================================
        -- STEP 3: CHECK IF MPN STOCKLINE IS A LOT STOCKLINE 
        -- =============================================
        SELECT @SourceLotId = ISNULL(LotId, 0)
        FROM DBO.Stockline WITH(NOLOCK)
        WHERE StockLineId = @MPNStockLineId
          AND ISNULL(LotId, 0) > 0;

        -- =============================================
        -- STEP 4: LOAD INTEGRATION PORTAL
        -- =============================================
        SELECT @IntegrationPortal = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
        FROM dbo.ItemMaster im WITH(NOLOCK)
        LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON im.ItemMasterId = mp.ItemMasterId
        LEFT JOIN dbo.IntegrationPortal ip            WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
        WHERE im.ItemMasterId = @ItemMasterId
          AND im.MasterCompanyId = @MasterCompanyId
          AND mp.IntegrationPortalId IS NOT NULL
        GROUP BY im.ItemMasterId;

        -- =============================================
        -- STEP 5: GENERATE STOCKLINE / CONTROL / ID NUMBERS
        -- =============================================
        IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL
            DROP TABLE #tmpCodePrefixes_Parent;

        CREATE TABLE #tmpCodePrefixes_Parent
        (
            [ID]             BIGINT      NOT NULL IDENTITY,
            [CodePrefixId]   BIGINT      NULL,
            [CodeTypeId]     BIGINT      NULL,
            [CurrentNummber] BIGINT      NULL,
            [CodePrefix]     VARCHAR(50) NULL,
            [CodeSufix]      VARCHAR(50) NULL,
            [StartsFrom]     BIGINT      NULL
        );

        INSERT INTO #tmpCodePrefixes_Parent (CodePrefixId, CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom)
        SELECT CP.CodePrefixId, CP.CodeTypeId, CP.CurrentNummber, CP.CodePrefix, CP.CodeSufix, CP.StartsFrom
        FROM dbo.CodePrefixes CP WITH(NOLOCK)
        JOIN dbo.CodeTypes CT    WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
        WHERE CT.CodeTypeId IN (30, 17, 9)
          AND CP.MasterCompanyId = @MasterCompanyId
          AND CP.IsActive  = 1
          AND CP.IsDeleted = 0;

          -- Validate all three code types exist before proceeding
        IF NOT EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30)
            OR NOT EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9)
            OR NOT EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17)
        BEGIN
            ROLLBACK TRAN;
            RETURN;
        END

        -- PN/Manufacturer Combination: get current stockline sequence number
        IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
            DROP TABLE #tmpPNManufacturer;

        CREATE TABLE #tmpPNManufacturer
        (
            [ID]              BIGINT       NOT NULL IDENTITY,
            [ItemMasterId]    BIGINT       NULL,
            [ManufacturerId]  BIGINT       NULL,
            [StockLineNumber] VARCHAR(100) NULL,
            [CurrentStlNo]    BIGINT       NULL,
            [isSerialized]    BIT          NULL
        );

        ;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS
        (
            SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) AS StockLineId
            FROM (SELECT DISTINCT ItemMasterId    FROM DBO.Stockline WITH(NOLOCK)) ac1
            CROSS JOIN (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH(NOLOCK)) ac2
            LEFT JOIN DBO.Stockline ac WITH(NOLOCK)
                ON ac.ItemMasterId    = ac1.ItemMasterId
               AND ac.ManufacturerId = ac2.ManufacturerId
            WHERE ac.MasterCompanyId = @MasterCompanyId
            GROUP BY ac.ItemMasterId, ac.ManufacturerId
            HAVING COUNT(ac.ItemMasterId) > 0
        )
        INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)
        SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, STL.StockLineNumber,
               ISNULL(IM.CurrentStlNo, 0), IM.isSerialized
        FROM CTE_Stockline CSTL
        INNER JOIN DBO.Stockline STL  WITH(NOLOCK) ON CSTL.StockLineId = STL.StockLineId
        INNER JOIN DBO.ItemMaster IM  WITH(NOLOCK) ON STL.ItemMasterId = IM.ItemMasterId
                                                  AND STL.ManufacturerId = IM.ManufacturerId;

        SELECT @currentNo = ISNULL(CurrentStlNo, 0)
        FROM #tmpPNManufacturer
        WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

        SET @stockLineCurrentNo = CASE WHEN ISNULL(@currentNo, 0) > 0 THEN @currentNo + 1 ELSE 1 END;

        -- Stockline Number (CodeTypeId = 30)
        SET @StockLineNumber = (
            SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
                @stockLineCurrentNo,
                (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30),
                (SELECT CodeSufix  FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30))
        );

        UPDATE [dbo].[ItemMaster]
        SET [CurrentStlNo] = @stockLineCurrentNo
        WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId;

        -- Control Number (CodeTypeId = 9)
        SELECT @CNCurrentNummber = CASE WHEN CurrentNummber > 0
                                        THEN CAST(CurrentNummber AS BIGINT) + 1
                                        ELSE CAST(StartsFrom   AS BIGINT) + 1 END
        FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9;

        SET @ControlNumber = (
            SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
                @CNCurrentNummber,
                (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9),
                (SELECT CodeSufix  FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9))
        );

        -- ID Number (CodeTypeId = 17)
        SET @IDCurrentNummber = 1;
        SET @IDNumber = (
            SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
                @IDCurrentNummber,
                (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17),
                (SELECT CodeSufix  FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17))
        );

        -- =============================================
        -- STEP 6: INSERT NEW TURN-IN STOCKLINE
        -- =============================================
        INSERT INTO [dbo].[Stockline] (
            StockLineNumber, ControlNumber, IDNumber,
            IsCustomerStock, IsCustomerstockType, ItemMasterId, PartNumber,
            PurchaseUnitOfMeasureId, ConditionId, Quantity,
            QuantityAvailable, QuantityOnHand, QuantityTurnIn,
            IsSerialized, SerialNumber, CustomerId,
            ObtainFromType, ObtainFrom, ObtainFromName,
            OwnerType, [Owner], OwnerName,
            TraceableToType, TraceableTo, TraceableToName,
            Memo, WorkOrderId, WorkOrderNumber, ManufacturerId,
            InspectionBy, InspectionDate, ReceiverNumber,
            IsParent, LotCost, ParentId,
            QuantityIssued, QuantityReserved, QuantityToReceive,
            RepairOrderExtendedCost, SubWOPartNoId, SubWorkOrderId,
            WorkOrderExtendedCost, WorkOrderPartNoId,
            ReceivedDate, ManagementStructureId, SiteId,
            WarehouseId, LocationId, ShelfId, BinId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
            isActive, isDeleted, MasterCompanyId, IsTurnIn,
            [OEM], IsPMA, IsDER, IsOemPNId, OEMPNNumber,
            GLAccountId, [IsStkTimeLife], [EvidenceId],
            [IntegrationPortal],
            StockUnitOfMeasureId, ConsumeUnitOfMeasureId,
            AircraftTailNumber, AircraftSN,
            [LotId], [IsLotAssigned], LOTQty
        )
        VALUES (
            @StockLineNumber, @ControlNumber, @IDNumber,
            @IsCustomerStock, @IsCustomerstockType, @ItemMasterId, @PartNumber,
            @PurchaseUOMId, @ConditionId, @Quantity,
            @Quantity, @Quantity, @Quantity,
            @IsSerialized, @SerialNumber, @CustomerId,
            @ObtainFromTypeId, @ObtainFrom, @ObtainFromName,
            @OwnerTypeId, @Owner, @OwnerName,
            @TraceableToTypeId, @TraceableTo, @TraceableToName,
            @Memo, @WorkOrderId, @WorkOrderNum, @ManufacturerId,
            @InspectedById, @InspectedDate, @ReceiverNumber,
            1, 0, 0,
            0, 0, 0,
            0, 0, 0,
            0, @WorkOrderPartNoId,
            @ReceivedDate, @ManagementStructureId, @SiteId,
            @WarehouseId, @LocationId, @ShelfId, @BinId,
            @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
            1, 0, @MasterCompanyId, 1,
            @IsOEM, @IsPMA, @IsDER, @IsOemPNId, @OEMPNNumber,
            @GLAccountId, @IsTimeLife, @EvidenceId,
            @IntegrationPortal,
            @StockUOMId, @ConsumeUOMId,
            @AircraftTail, @AircraftSN,
            @SourceLotId,
            CASE WHEN ISNULL(@SourceLotId, 0) > 0 THEN 1 ELSE 0 END,
            @Quantity
        );

        SELECT @StockLineId = SCOPE_IDENTITY();

        -- Update code prefix counters
        UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @SLCurrentNummber
        WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId;

        UPDATE [dbo].[CodePrefixes] SET CurrentNummber = @CNCurrentNummber
        WHERE CodeTypeId = 9  AND MasterCompanyId = @MasterCompanyId;

        -- Post-insert enrichment
        EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId;

        UPDATE [dbo].[Stockline]
        SET Memo     = 'This Stockline is created using turn-in from ' + @WorkOrderNumber,
            UnitCost = @Unitcost
        WHERE StockLineId = @StockLineId;

        IF @isExchange = 1
            UPDATE [dbo].[Stockline]
            SET WorkOrderMaterialsId = @WorkOrderMaterialsId
            WHERE StockLineId = @StockLineId;

        -- =============================================
        -- STEP 7: TEARDOWN-SPECIFIC PROCESSING
        -- =============================================
        IF @WorkOrderTypeId = @TearDownWorkOrderTypeId
        BEGIN
            UPDATE [dbo].[WorkOrderPartNumber]
            SET TendorStocklineCost = ISNULL(TendorStocklineCost, 0) + ISNULL(@Quantity * @Unitcost, 0)
            WHERE ID = @WorkOrderPartNoId;

            SET @OLDStockLineId = (
                SELECT StockLineId FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
                WHERE ID = @WorkOrderPartNoId
            );

            UPDATE [dbo].[Stockline]
            SET Memo = 'This Stockline cost is updated using turn-in to work order number '
                     + @WorkOrderNumber + ' new stockline is ' + @StockLineNumber
            WHERE StockLineId = @OLDStockLineId;

            -- Teardown accounting entry
            SELECT @DistributionMasterId = [ID]
            FROM [dbo].[DistributionMaster] WITH(NOLOCK)
            WHERE DistributionCode = 'TENDERINGSTOCKLINETWO';

            EXEC [dbo].[USP_TearDownWOBatchTriggerBasedonDistribution]
                @DistributionMasterId, @WorkOrderId, @WorkOrderPartNoId,
                @StockLineId, @MasterCompanyId, @UpdatedBy;
        END

        -- =============================================
        -- STEP 8: STOCKLINE HISTORY
        -- =============================================
        SELECT @ActionId        = ActionId  FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'Tendered';
        SELECT @HistoryModuleId = ModuleId  FROM dbo.Module                    WITH(NOLOCK) WHERE ModuleName = 'WorkOrder';

        EXEC [dbo].[USP_AddUpdateStocklineHistory]
            @StocklineId     = @StockLineId,
            @ModuleId        = @HistoryModuleId,
            @ReferenceId     = @WorkOrderId,
            @SubModuleId     = @SubModuleId,
            @SubRefferenceId = @SubReferenceId,
            @ActionId        = @ActionId,
            @Qty             = @Quantity,
            @UpdatedBy       = @UpdatedBy;

        -- =============================================
        -- STEP 9: LOT TRANS-IN  (if MPN stockline is a Lot stockline)
        -- =============================================
        IF @SourceLotId > 0
        BEGIN
            DECLARE @LotDetails dbo.LotTransInOutDetailsType;

            INSERT INTO @LotDetails (
                LotTransInOutId, StockLineId, LotId,
                QtyToTransIn, QtyToTransOut, LotTransInOutDetails,
                UnitCost, ExtCost, IsTransOut,
                TransInMemo, TransOutMemo
            )
            SELECT
                0,
                @StockLineId,
                @SourceLotId,
                sl.QuantityOnHand,
                0,
                0,
                ISNULL(sl.UnitCost, 0),
                ISNULL(sl.UnitCost, 0) * ISNULL(sl.QuantityOnHand, 0),
                0,
                'Trans In From Tender Stockline - ' + @WorkOrderNumber,
                ''
            FROM DBO.Stockline sl WITH(NOLOCK)
            WHERE sl.StockLineId = @StockLineId;

            SET @LotCreatedDate = GETUTCDATE();

            IF OBJECT_ID('tempdb..#LotResult') IS NOT NULL DROP TABLE #LotResult;
			CREATE TABLE #LotResult (
				-- Add columns matching what the SP returns, e.g.:
				LotTransInOutId BIGINT
				-- add other columns as needed
			);

            INSERT INTO #LotResult
            EXEC dbo.USP_Lot_AddUpdateLotTransInOutDetails
                @tbl_LotTransInOutDetailsType = @LotDetails,
                @LotTransInOutId              = 0,
                @MasterCompanyId              = @MasterCompanyId,
                @IsTransInOut                 = 0,
                @IsInOut                      = 1,
                @CreatedBy                    = @UpdatedBy,
                @UpdatedBy                    = @UpdatedBy,
                @CreatedDate                  = @LotCreatedDate,
                @UpdatedDate                  = @LotCreatedDate,
                @IsFromPreCostStk             = 1;

            DROP TABLE #LotResult;  -- discard immediately
        END

        -- =============================================
        -- STEP 10: MANAGEMENT STRUCTURE
        -- =============================================
        EXEC USP_SaveSLMSDetails @MSModuleID, @StockLineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy;

        -- =============================================
        -- STEP 11: LINK STOCKLINE TO WO MATERIALS
        -- =============================================
        IF @IsKitType = 0
        BEGIN
            -- Standard (non-Kit) WO Materials
            IF @IsMaterialStocklineCreate = 1
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK)
                    WHERE ItemMasterId          = @ItemMasterId
                      AND ConditionCodeId       = @ConditionId
                      AND WorkFlowWorkOrderId   = @WorkOrderWorkflowId
                      AND MasterCompanyId       = @MasterCompanyId
                      AND IsActive = 1 AND IsDeleted = 0
                )
                BEGIN
                 -- Adjust quantity if required
                    UPDATE [dbo].[WorkOrderMaterials]
                    SET Quantity = CASE
                        WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity
                        THEN Quantity
                        ELSE ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity
                    END
                    WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

                    SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;

                    IF @isExchange = 1
                        UPDATE [dbo].[Stockline]
                        SET WorkOrderMaterialsId = @WorkOrderMaterialsId
                        WHERE StockLineId = @StockLineId;
                END
                ELSE
                BEGIN
                    IF ISNULL(@IsMPNTendor, 0) = 0
                    BEGIN
                        -- Standard insert from existing WOM record
                        INSERT INTO [dbo].[WorkOrderMaterials] (
                            WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId,
                            ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
                            UnitCost, ExtendedCost, Memo, IsDeferred,
                            QuantityReserved, QuantityIssued, MaterialMandatoriesId, ProvisionId,
                            CreatedDate, CreatedBy, UpdatedDate, UpdatedBy,
                            MasterCompanyId, IsActive, IsDeleted
                        )
                        SELECT
                            @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId,
                            @ConditionId, WOM.ItemClassificationId, @Quantity, @StockUOMId,
                            0, 0, @Memo, WOM.IsDeferred,
                            0, 0, WOM.MaterialMandatoriesId, WOM.ProvisionId,
                            GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy,
                            @MasterCompanyId, 1, 0
                        FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)
                        JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH(NOLOCK)
                            ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
                        WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId;

                        SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY();

                        IF @isExchange = 1
                            UPDATE [dbo].[Stockline]
                            SET WorkOrderMaterialsId = @NewWorkOrderMaterialsId
                            WHERE StockLineId = @StockLineId;
                    END
                    ELSE
                    BEGIN
                        -- MPN Tender: resolve or create Task
                        DECLARE @TaskId BIGINT = 0;

                        IF @WorkOrderFormTypeId = 0
                        BEGIN
                            SELECT @TaskId = ISNULL(TaskId, 0)
                            FROM [dbo].[Task]
                            WHERE [Description] = 'ALL TASK' AND MasterCompanyId = @MasterCompanyId;

                            IF @TaskId = 0
                            BEGIN
                                INSERT INTO [dbo].[Task] (
                                    [Description], Memo, MasterCompanyId, CreatedBy, UpdatedBy,
                                    CreatedDate, UpdatedDate, IsActive, IsDeleted, Sequence,
                                    IsTravelerTask, Descrepancy, Resolution, StandardHours,
                                    StandardMinute, IsPrintInWO, IsPrintInWOQ, IsPrintInspector,
                                    IsPrintTechnician, IsPrintAdmin
                                )
                                VALUES (
                                    'ALL TASK', '', @MasterCompanyId, 'AUTO SCRIPT', 'AUTO SCRIPT',
                                    GETUTCDATE(), GETUTCDATE(), 1, 0,
                                    (SELECT MAX(Sequence) + 1 FROM [dbo].[Task] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId),
                                    1, NULL, NULL, 0, 0, 0, 0, 1, 0, 1
                                );
                                SET @TaskId = SCOPE_IDENTITY();
                            END
                        END
                        ELSE
                        BEGIN
                            SELECT TOP 1 @TaskId = ISNULL(WorkOrderTaskId, 0)
                            FROM [dbo].[WorkOrderTask]
                            WHERE WorkOrderId           = @WorkOrderId
                              AND WorkFlowWorkOrderId   = @WorkOrderWorkflowId
                              AND MasterCompanyId       = @MasterCompanyId;

                            IF @TaskId = 0
                            BEGIN
                                SELECT @TaskId = ISNULL(TaskId, 0)
                                FROM [dbo].[Task]
                                WHERE [Description] = 'ALL TASK' AND MasterCompanyId = @MasterCompanyId;

                                IF @TaskId = 0
                                BEGIN
                                    INSERT INTO [dbo].[Task] (
                                        [Description], Memo, MasterCompanyId, CreatedBy, UpdatedBy,
                                        CreatedDate, UpdatedDate, IsActive, IsDeleted, Sequence,
                                        IsTravelerTask, Descrepancy, Resolution, StandardHours,
                                        StandardMinute, IsPrintInWO, IsPrintInWOQ, IsPrintInspector,
                                        IsPrintTechnician, IsPrintAdmin
                                    )
                                    VALUES (
                                        'ALL TASK', '', @MasterCompanyId, 'AUTO SCRIPT', 'AUTO SCRIPT',
                                        GETUTCDATE(), GETUTCDATE(), 1, 0,
                                        (SELECT MAX(Sequence) + 1 FROM [dbo].[Task] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId),
                                        1, NULL, NULL, 0, 0, 0, 0, 1, 0, 1
                                    );
                                    SET @TaskId = SCOPE_IDENTITY();
                                END

                                INSERT INTO [dbo].[WorkOrderTask] (
                                    WorkOrderId, WorkFlowWorkOrderId, TaskId, MasterCompanyId,
                                    CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
                                    IsActive, IsDeleted, WorkOrderPartNumberId, SequenceNumber,
                                    OpenDate, OpenBy, IsIncludeInPrint, HasInstruction,
                                    TaskName, IsFromWorkFlow
                                )
                                VALUES (
                                    @WorkOrderId, @WorkOrderWorkflowId, @TaskId, @MasterCompanyId,
                                    @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
                                    1, 0, @WorkOrderPartNoId, 1,
                                    NULL, NULL, NULL, NULL, 'ALL TASK', NULL
                                );
                                SET @TaskId = SCOPE_IDENTITY();
                            END
                        END

                        INSERT INTO [dbo].[WorkOrderMaterials] (
                            WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId,
                            ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
                            UnitCost, ExtendedCost, Memo, IsDeferred,
                            QuantityReserved, QuantityIssued, MaterialMandatoriesId, ProvisionId,
                            CreatedDate, CreatedBy, UpdatedDate, UpdatedBy,
                            MasterCompanyId, IsActive, IsDeleted
                        )
                        VALUES (
                            @WorkOrderId, @WorkOrderWorkflowId, @ItemMasterId, @TaskId,
                            @ConditionId, @ItemClassificationId, @Quantity, @StockUOMId,
                            0, 0, @Memo, 0,
                            0, 0, 1, @ProvisionId,
                            GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy,
                            @MasterCompanyId, 1, 0
                        );

                        SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY();
                    END
                END

                -- Link new stockline to WO Material
                INSERT INTO [dbo].[WorkOrderMaterialStockLine] (
                    WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId,
                    ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,
                    UnitCost, ExtendedCost, UnitPrice,
                    CreatedDate, CreatedBy, UpdatedDate, UpdatedBy,
                    MasterCompanyId, IsActive, IsDeleted
                )
                SELECT
                    @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId,
                    @ConditionId, @Quantity, @Quantity, 0, 0,
                    0, 0, 0,
                    GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy,
                    @MasterCompanyId, 1, 0
                FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)
                WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

                DECLARE @WOMStockLineId BIGINT = SCOPE_IDENTITY();

                IF @WorkOrderTypeId = @TearDownWorkOrderTypeId
                    UPDATE [dbo].[WorkOrderMaterialStockLine]
                    SET UnitCost     = @Unitcost,
                        ExtendedCost = ISNULL(@Quantity * @Unitcost, 0)
                    WHERE WOMStockLineId = @WOMStockLineId;

                -- Sync QtyToTurnIn if it falls behind actuals
                SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn, 0))
                FROM dbo.WorkOrderMaterialStockLine womsl WITH(NOLOCK)
                JOIN dbo.Stockline sl                WITH(NOLOCK) ON womsl.StockLineId       = sl.StockLineId
                JOIN dbo.WorkOrderMaterials WOM      WITH(NOLOCK) ON womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
                WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId
                  AND womsl.ConditionId = WOM.ConditionCodeId
                  AND womsl.IsActive = 1 AND womsl.IsDeleted = 0
                  AND ISNULL(sl.QuantityTurnIn, 0) > 0;

                SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn, 0))
                FROM dbo.WorkOrderMaterials WITH(NOLOCK)
                WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

                IF @QtyTendered > @QtyToTendered
                    UPDATE dbo.WorkOrderMaterials
                    SET QtyToTurnIn = @QtyTendered
                    WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

                IF ISNULL(@IsMPNTendor, 0) = 1
                    UPDATE dbo.WorkOrderMaterials
                    SET QtyToTurnIn = @Quantity
                    WHERE WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

                -- Sync total quantity if stl qty exceeds WOM qty
                SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity, 0))
                FROM dbo.WorkOrderMaterialStockLine womsl WITH(NOLOCK)
                WHERE womsl.WorkOrderMaterialsId = @WorkOrderMaterialsId
                  AND womsl.IsActive = 1 AND womsl.IsDeleted = 0;

                IF @TotalStlQtyReq > (
                    SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterials WITH(NOLOCK)
                    WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
                )
                    UPDATE dbo.WorkOrderMaterials
                    SET Quantity = @TotalStlQtyReq
                    WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;

                -- Recalculate WO costs
                EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;
                EXEC USP_UpdateWOCostDetails      @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;
                EXEC USP_UpdateWOMaterialsCost    @WorkOrderMaterialsId = @NewWorkOrderMaterialsId, @WorkFlowWorkOrderId = @WorkOrderWorkflowId;
            END
        END
        ELSE
        BEGIN
            -- =============================================
            -- KIT WO Materials path
            -- =============================================
            SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId
            FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK)
            WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

            IF @IsMaterialStocklineCreate = 1
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK)
                    WHERE ItemMasterId        = @ItemMasterId
                      AND ConditionCodeId     = @ConditionId
                      AND WorkFlowWorkOrderId = @WorkOrderWorkflowId
                      AND MasterCompanyId     = @MasterCompanyId
                      AND IsActive = 1 AND IsDeleted = 0
                )
                BEGIN
                    UPDATE dbo.WorkOrderMaterialsKit
                    SET Quantity = CASE
                        WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity
                        THEN Quantity
                        ELSE ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity
                    END
                    WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                    SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;
                END
                ELSE
                BEGIN
                    DECLARE @WorkOrderMaterialsKitMappingId BIGINT = NULL;

                    SELECT TOP 1 @WorkOrderMaterialsKitMappingId = WorkOrderMaterialsKitMappingId
                    FROM DBO.WorkOrderMaterialsKit WITH(NOLOCK)
                    WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                    INSERT INTO dbo.WorkOrderMaterialsKit (
                        WorkOrderMaterialsKitMappingId, WorkOrderId, WorkFlowWorkOrderId,
                        ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId,
                        Quantity, UnitOfMeasureId, UnitCost, ExtendedCost, Memo,
                        IsDeferred, QuantityReserved, QuantityIssued,
                        MaterialMandatoriesId, ProvisionId,
                        CreatedDate, CreatedBy, UpdatedDate, UpdatedBy,
                        MasterCompanyId, IsActive, IsDeleted
                    )
                    SELECT
                        @WorkOrderMaterialsKitMappingId, @WorkOrderId, WOWF.WorkFlowWorkOrderId,
                        @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId,
                        @Quantity, @StockUOMId, 0, 0, @Memo,
                        WOM.IsDeferred, 0, 0,
                        WOM.MaterialMandatoriesId, WOM.ProvisionId,
                        GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy,
                        @MasterCompanyId, 1, 0
                    FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)
                    JOIN dbo.WorkOrderWorkFlow WOWF  WITH(NOLOCK)
                        ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
                    WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                    SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY();
                END

                INSERT INTO dbo.WorkOrderMaterialStockLineKit (
                    WorkOrderMaterialsKitId, StockLineId, ItemMasterId, ProvisionId,
                    ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,
                    UnitCost, ExtendedCost, UnitPrice,
                    CreatedDate, CreatedBy, UpdatedDate, UpdatedBy,
                    MasterCompanyId, IsActive, IsDeleted
                )
                SELECT
                    @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId,
                    @ConditionId, @Quantity, @Quantity, 0, 0,
                    0, 0, 0,
                    GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy,
                    @MasterCompanyId, 1, 0
                FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)
                WHERE WOM.WorkOrderMaterialsKitId = @NewWorkOrderMaterialsId;

                -- Sync QtyToTurnIn
                SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn, 0))
                FROM dbo.WorkOrderMaterialStockLineKit womsl WITH(NOLOCK)
                JOIN dbo.Stockline sl                  WITH(NOLOCK) ON womsl.StockLineId          = sl.StockLineId
                JOIN dbo.WorkOrderMaterialsKit WOM     WITH(NOLOCK) ON womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId
                WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId
                  AND womsl.ConditionId = WOM.ConditionCodeId
                  AND womsl.IsActive = 1 AND womsl.IsDeleted = 0
                  AND ISNULL(sl.QuantityTurnIn, 0) > 0;

                SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn, 0))
                FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK)
                WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                IF @QtyTendered > @QtyToTendered
                    UPDATE dbo.WorkOrderMaterialsKit
                    SET QtyToTurnIn = @QtyTendered
                    WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                -- Sync total quantity
                SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity, 0))
                FROM dbo.WorkOrderMaterialStockLineKit womsl WITH(NOLOCK)
                WHERE womsl.WorkOrderMaterialsKitId = @WorkOrderMaterialsId
                  AND womsl.IsActive = 1 AND womsl.IsDeleted = 0;

                IF @TotalStlQtyReq > (
                    SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK)
                    WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId
                )
                    UPDATE dbo.WorkOrderMaterialsKit
                    SET Quantity = @TotalStlQtyReq
                    WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;

                -- Recalculate WO costs
                EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;
                EXEC USP_UpdateWOCostDetails      @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy;
                EXEC USP_UpdateWOMaterialsCost    @WorkOrderMaterialsId = @NewWorkOrderMaterialsId, @WorkFlowWorkOrderId = @WorkOrderWorkflowId;
            END
        END

        -- =============================================
        -- CLEANUP TEMP TABLES
        -- =============================================
        IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL DROP TABLE #tmpCodePrefixes_Parent;
        IF OBJECT_ID(N'tempdb..#tmpPNManufacturer')      IS NOT NULL DROP TABLE #tmpPNManufacturer;

        SELECT @StockLineId AS StockLineId;

    COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;

        DECLARE
            @ErrorLogID          INT,
            @DatabaseName        VARCHAR(100)  = DB_NAME(),
            @AdhocComments       VARCHAR(150)  = 'usp_SaveTurnInWorkOrderMaterils',
            @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)),
            @ApplicationName     VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH

END