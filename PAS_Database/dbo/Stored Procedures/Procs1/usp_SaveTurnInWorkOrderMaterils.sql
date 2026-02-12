/*************************************************************     
** Author:  <Hemant Saliya>    
** Create date: <07/30/2021>    
** Description: <This Proc Is used to Same Turn In Materials Stockline>    
    
Exec [usp_SaveTurnInWorkOrderMaterils]   
**************************************************************   
** Change History   
**************************************************************     
** PR   Date        Author          Change Description    
** --   --------    -------         --------------------------------  
   1    07/30/2021  Hemant Saliya		Initilial Draft  
   2    05/11/2023  Vishal Suthar		Added portion to tender the stockline for KIT  
   3    05/23/2023  Subhash Saliya		Added portion to Unit Cost  
   4    06/05/2023  Moin Bloch			Updated TendorStocklineCost, multiply by Qty with unit cost from Add tendor stockline  Line No 262  
   5    07/30/2021  Hemant Saliya		Update Teardon text  
   6    06/09/2023  Moin Bloch			Updated unit cost of old stockline when tendor stockline Line No 268  
   7    06/14/2023  Devendra Shekh		changed function udfGenerateCodeNumber to [udfGenerateCodeNumberWithOutDash]
   8    10/16/2023  Devendra Shekh		Timelife issue resolved
   9    10/16/2023  Devendra Shekh		update for wopartnoId for insert stockline
   10	03/05/2024  Bhargav saliya		UTC Date Changes
   11	22/03/2024  Moin Bloch			Added New Field @EvidenceId
   12	02/04/2024  Moin Bloch			Updated Inventory History Notes Turn in to Tendered  
   13	04/04/2024  Moin Bloch			Updated CurrentSerialNumber Issue 
   14	30/07/2024  Devendra Shekh		Tender Stockline Issue Resolved
   15	27/09/2024  Devendra Shekh		Commented USP_CreateChildStockline
   16   04/14/2025  HEMANT SALIYA		Added Work Order Work Flow Id for UpdateWOMaterialsCost
   16   18/04/2025  ABHISHEK JIRAWLA	Added Integration Portal in Stockline
   17	08/10/2025  Moin Bloch			Added MPN Tendor 
   18	30/01/2026  Moin Bloch			Fix For Getting FK Conflict Error In Bin
   19   10/02/2026  Moin Bloch          No need to remove cost from stockline while tendor WO materials PN-15331 & Added Accounting Entry For Teardown Stockline
  
exec dbo.usp_SaveTurnInWorkOrderMaterils @IsMaterialStocklineCreate=1,@IsCustomerStock=1,@IsCustomerstockType=0,@ItemMasterId=291,@UnitOfMeasureId=5,  
@ConditionId=10,@Quantity=2,@IsSerialized=0,@SerialNumber=NULL,@CustomerId=80,@ObtainFromTypeId=1,@ObtainFrom=80,@ObtainFromName=N'anil gill ',  
@OwnerTypeId=NULL,@Owner=NULL,@OwnerName=N'',@TraceableToTypeId=NULL,@TraceableTo=NULL,@TraceableToName=N'',@Memo=N' ',@WorkOrderId=N'320',  
@WorkOrderNumber=N'WO-000161',@ManufacturerId=9,@InspectedById=NULL,@InspectedDate=NULL,@ReceiverNumber=N'RCTS#-000087',@ReceivedDate='2022-07-29 13:04:59.237',  
@ManagementStructureId=1,@SiteId=2,@WarehouseId=NULL,@LocationId=NULL,@ShelfId=NULL,@BinId=NULL,@MasterCompanyId=1,@UpdatedBy=N'ADMIN ADMIN',@WorkOrderMaterialsId=395  
**************************************************************/   
CREATE   PROCEDURE [dbo].[usp_SaveTurnInWorkOrderMaterils]  
@IsMaterialStocklineCreate BIT = 0,  
@IsCustomerStock BIT = 0,  
@IsCustomerstockType BIT,  
@ItemMasterId BIGINT,  
@UnitOfMeasureId BIGINT,  
@ConditionId BIGINT,  
@Quantity INT,  
@IsSerialized BIT,  
@SerialNumber VARCHAR(50),  
@CustomerId BIGINT = NULL,  
@ObtainFromTypeId INT = NULL,  
@ObtainFrom BIGINT = NULL,  
@ObtainFromName VARCHAR(500) = NULL,  
@OwnerTypeId INT = NULL,  
@Owner BIGINT = NULL,  
@OwnerName VARCHAR(500) = NULL,  
@TraceableToTypeId INT = NULL,  
@TraceableTo BIGINT = NULL,  
@TraceableToName VARCHAR(500) = NULL,  
@Memo VARCHAR(MAX),  
@WorkOrderId BIGINT,  
@WorkOrderNumber VARCHAR(50),  
@ManufacturerId BIGINT,  
@InspectedById BIGINT = NULL,  
@InspectedDate DATETIME2(7) = NULL,  
@ReceiverNumber VARCHAR(500),  
@ReceivedDate DATETIME2(7),  
@ManagementStructureId BIGINT,  
@SiteId BIGINT,  
@WarehouseId BIGINT = NULL,  
@LocationId BIGINT = NULL,  
@ShelfId BIGINT = NULL,  
@BinId BIGINT = NULL,  
@MasterCompanyId BIGINT,  
@UpdatedBy VARCHAR(100),  
@WorkOrderMaterialsId BIGINT=0,  
@IsKitType BIT = 0,  
@Unitcost DECIMAL(18,2) = 0,
@ProvisionId INT =0, 
@EvidenceId INT = NULL,  
@WorkOrderWorkflowId BIGINT  = NULL,  
@IsMPNTendor BIT = 0  
AS  
BEGIN  
   
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
 DECLARE @PartNumber VARCHAR(500);  
 DECLARE @WorkOrderNum VARCHAR(500);  
 DECLARE @SLCurrentNummber BIGINT;  
 DECLARE @StockLineNumber VARCHAR(50);  
 DECLARE @CNCurrentNummber BIGINT;   
 DECLARE @ControlNumber VARCHAR(50);  
 DECLARE @IDCurrentNummber BIGINT;   
 DECLARE @IDNumber VARCHAR(50);  
 DECLARE @NewWorkOrderMaterialsId BIGINT;  
 DECLARE @StockLineId BIGINT;  
 --DECLARE @WorkOrderWorkflowId BIGINT;  
 DECLARE @IsWorkOrderMaterialsExist BIT = 0;  
 DECLARE @MSModuleID INT = 2; -- Stockline Module ID  
 DECLARE @IsPMA BIT = 0;  
 DECLARE @IsDER BIT = 0;  
 DECLARE @IsOemPNId BIGINT;  
 DECLARE @IsOEM BIT = 0;  
 DECLARE @OEMPNNumber VARCHAR(500);  
 DECLARE @count INT;  
 DECLARE @slcount INT;  
 DECLARE @IsAddUpdate BIT;   
 DECLARE @ExecuteParentChild BIT;   
 DECLARE @UpdateQuantities BIT;  
 DECLARE @IsOHUpdated BIT;   
 DECLARE @AddHistoryForNonSerialized BIT;    
 DECLARE @ReferenceId BIGINT;   
 DECLARE @SubReferenceId BIGINT;  
 DECLARE @IsSerialised BIT;  
 DECLARE @ModuleId BIGINT;  
 DECLARE @SubModuleId BIGINT;  
 DECLARE @stockLineQty INT;  
 DECLARE @stockLineQtyAvailable INT;  
 DECLARE @GLAccountId INT;  
 DECLARE @IsTimeLife BIT;  
    
   -- #STEP 1 CREATE STOCKLINE  
   BEGIN TRY 
   BEGIN TRANSACTION  
    BEGIN  
     DECLARE @QtyTendered INT = 0;  
     DECLARE @QtyToTendered INT = 0;  
     DECLARE @TotalStlQtyReq INT = 0;  
     DECLARE @WorkOrderTypeId INT = 0;  
     DECLARE @TearDownWorkOrderTypeId INT = 0;  
     DECLARE @WorkOrderPartNoId BIGINT = 0;  
	 DECLARE @ItemClassificationId BIGINT = 0;  
	 DECLARE @WorkOrderFormTypeId BIT = 0; 
	 DECLARE @isExchange BIT = (CASE WHEN UPPER((SELECT [StatusCode] FROM [dbo].[Provision] WITH(NOLOCK) WHERE [ProvisionId] = @ProvisionId)) = 'EXCHANGE' THEN 1 ELSE 0 END); 

	 
	 SET @TraceableTo = CASE WHEN @TraceableTo = 0 THEN NULL ELSE @TraceableTo END	 
	 SET @InspectedById = CASE WHEN @InspectedById = 0 THEN NULL ELSE @InspectedById END	 
	 SET @WarehouseId = CASE WHEN @WarehouseId = 0 THEN NULL ELSE @WarehouseId END
	 SET @LocationId = CASE WHEN @LocationId = 0 THEN NULL ELSE @LocationId END
	 SET @ShelfId = CASE WHEN @ShelfId = 0 THEN NULL ELSE @ShelfId END
	 SET @BinId = CASE WHEN @BinId = 0 THEN NULL ELSE @BinId END	
	 
     SET @count = @Quantity;  
     SET @slcount = @Quantity;  
     SET @IsAddUpdate = 1;  
     SET @ExecuteParentChild = 1;  
     SET @UpdateQuantities = 0;  
     SET @IsOHUpdated = 0;  
     SET @AddHistoryForNonSerialized = 0;  
  
     SELECT @ModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'StockLine'; -- For Stockline Module   
     SELECT @SubModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMaterials'; -- For WORK ORDER Materials Module  
  
     --IF(@isExchange = 1)
	 --BEGIN
		--SET @IsMaterialStocklineCreate  = 1		
	 --END

     IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
     BEGIN  
      DROP TABLE #tmpCodePrefixes_Parent  
     END  
      
     CREATE TABLE #tmpCodePrefixes_Parent  
     (  
       [ID] BIGINT NOT NULL IDENTITY,   
       [CodePrefixId] BIGINT NULL,  
       [CodeTypeId] BIGINT NULL,  
       [CurrentNummber] BIGINT NULL,  
       [CodePrefix] VARCHAR(50) NULL,  
       [CodeSufix] VARCHAR(50) NULL,  
       [StartsFrom] BIGINT NULL,  
     )  
  
     /* PN Manufacturer Combination Stockline logic */  
     CREATE TABLE #tmpPNManufacturer  
     (  
       [ID] BIGINT NOT NULL IDENTITY,   
       [ItemMasterId] BIGINT NULL,  
       [ManufacturerId] BIGINT NULL,  
       [StockLineNumber] VARCHAR(100) NULL,  
       [CurrentStlNo] BIGINT NULL,  
       [isSerialized] BIT NULL  
     )  
  
     ;WITH CTE_Stockline (ItemMasterId, ManufacturerId, StockLineId) AS  
     (  
      SELECT ac.ItemMasterId, ac.ManufacturerId, MAX(ac.StockLineId) StockLineId  
      FROM (SELECT DISTINCT ItemMasterId FROM DBO.Stockline WITH (NOLOCK)) ac1 CROSS JOIN  
       (SELECT DISTINCT ManufacturerId FROM DBO.Stockline WITH (NOLOCK)) ac2 LEFT JOIN  
       DBO.Stockline ac WITH (NOLOCK)  
       ON ac.ItemMasterId = ac1.ItemMasterId AND ac.ManufacturerId = ac2.ManufacturerId  
      WHERE ac.MasterCompanyId = @MasterCompanyId  
      GROUP BY ac.ItemMasterId, ac.ManufacturerId  
      HAVING COUNT(ac.ItemMasterId) > 0  
     )  
  
     INSERT INTO #tmpPNManufacturer (ItemMasterId, ManufacturerId, StockLineNumber, CurrentStlNo, isSerialized)  
     SELECT CSTL.ItemMasterId, CSTL.ManufacturerId, StockLineNumber, ISNULL(IM.CurrentStlNo, 0) AS CurrentStlNo, IM.isSerialized  
     FROM CTE_Stockline CSTL INNER JOIN DBO.Stockline STL WITH (NOLOCK)   
     INNER JOIN DBO.ItemMaster IM ON STL.ItemMasterId = IM.ItemMasterId AND STL.ManufacturerId = IM.ManufacturerId  
     ON CSTL.StockLineId = STL.StockLineId  
     /* PN Manufacturer Combination Stockline logic */  
  
     SELECT @PartNumber = partnumber, @IsPMA = IsPMA, @IsDER = IsDER, @IsOemPNId = IsOemPNId, @IsOEM = IsOEM, @OEMPNNumber = OEMPN,@GLAccountId=GLAccountId, @IsTimeLife = isTimeLife, @ItemClassificationId = [ItemClassificationId]   FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;  
     
	 SELECT @WorkOrderNumber = [WorkOrderNum],@WorkOrderTypeId=[WorkOrderTypeId], @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId  

	 IF(ISNULL(@IsMPNTendor,0) = 0)
	 BEGIN
		 IF(ISNULL(@IsKitType, 0) = 0)
		 BEGIN
			SELECT @WorkOrderWorkflowId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId 
		 END
		 ELSE 
		 BEGIN
			SELECT @WorkOrderWorkflowId = [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE [WorkOrderMaterialsKitId] = @WorkOrderMaterialsId 
		 END
	 END
      
     SELECT @WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkOrderWorkflowId  

     SELECT @TearDownWorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description] ='Teardown'  
       
     INSERT INTO #tmpCodePrefixes_Parent (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom)   
     SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
     FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH(NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId  
     WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
  
     IF(@WorkOrderTypeId != @TearDownWorkOrderTypeId)  
     BEGIN  
      SET @Unitcost = 0;  
     END  
  
     DECLARE @currentNo AS BIGINT;  
     DECLARE @stockLineCurrentNo AS BIGINT;  
  
     SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId  
  
     IF (@currentNo <> 0)  
     BEGIN  
      SET @stockLineCurrentNo = @currentNo + 1  
     END  
     ELSE  
     BEGIN  
      SET @stockLineCurrentNo = 1  
     END  
  
     IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE [CodeTypeId] = 30))  
     BEGIN   
      SET @StockLineNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@stockLineCurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30)))  
      
	  UPDATE [dbo].[ItemMaster] SET [CurrentStlNo] = @stockLineCurrentNo WHERE [ItemMasterId] = @ItemMasterId AND [ManufacturerId] = @ManufacturerId  
     END  
     ELSE   
     BEGIN  
		ROLLBACK TRAN;  
     END  
  
     IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9))  
     BEGIN   
      SELECT   
       @CNCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1   
        ELSE CAST(StartsFrom AS BIGINT) + 1 END   
      FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9  
  
      SET @ControlNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@CNCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9)))  
     END  
     ELSE   
     BEGIN  
      ROLLBACK TRAN;  
     END  
  
     IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17))  
     BEGIN   
      SET @IDCurrentNummber = 1;  
  
      SET @IDNumber = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](@IDCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17)))  
     END  
     ELSE   
     BEGIN  
      ROLLBACK TRAN;  
     END  
  
	DECLARE @IntegrationPortal VARCHAR(50)
		SELECT
			@IntegrationPortal = STRING_AGG(CAST(mp.IntegrationPortalId AS VARCHAR), ',')
		FROM dbo.ItemMaster iM WITH(NOLOCK)
		LEFT JOIN dbo.ItemMasterIntegrationPortal mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
		LEFT JOIN dbo.IntegrationPortal ip WITH(NOLOCK) ON mp.IntegrationPortalId = ip.IntegrationPortalId
		WHERE iM.ItemMasterId = @ItemMasterId AND iM.MasterCompanyId = @MasterCompanyId AND mp.IntegrationPortalId IS NOT NULL
		GROUP BY iM.ItemMasterId

     INSERT INTO [dbo].[Stockline](StockLineNumber, ControlNumber, IDNumber, IsCustomerStock,IsCustomerstockType,ItemMasterId,PartNumber, PurchaseUnitOfMeasureId,ConditionId,Quantity,   
       QuantityAvailable, QuantityOnHand,QuantityTurnIn,IsSerialized,SerialNumber, CustomerId, ObtainFromType, ObtainFrom, ObtainFromName, OwnerType, [Owner], OwnerName, TraceableToType,   
       TraceableTo, TraceableToName, Memo, WorkOrderId, WorkOrderNumber, ManufacturerId, InspectionBy, InspectionDate, ReceiverNumber, IsParent, LotCost, ParentId,  
       QuantityIssued, QuantityReserved,QuantityToReceive,RepairOrderExtendedCost, SubWOPartNoId,SubWorkOrderId, WorkOrderExtendedCost, WorkOrderPartNoId,  
       ReceivedDate, ManagementStructureId, SiteId, WarehouseId, LocationId, ShelfId, BinId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,isActive, isDeleted, MasterCompanyId, IsTurnIn,  
       [OEM],IsPMA, IsDER,IsOemPNId, OEMPNNumber,GLAccountId,[IsStkTimeLife],[EvidenceId], [IntegrationPortal]
     ) VALUES(@StockLineNumber, @ControlNumber, @IDNumber, @IsCustomerStock,@IsCustomerstockType,@ItemMasterId,@PartNumber,@UnitOfMeasureId,@ConditionId,@Quantity, @Quantity, @Quantity, @Quantity,  
       @IsSerialized,@SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName, @TraceableToTypeId,   
       @TraceableTo, @TraceableToName, @Memo, @WorkOrderId, @WorkOrderNum, @ManufacturerId, @InspectedById, @InspectedDate, @ReceiverNumber, 1, 0,0,0,0,0,0,0,0,0,@WorkOrderPartNoId,  
       @ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @UpdatedBy, @UpdatedBy, GETUTCDATE(),GETUTCDATE(),1,0, @MasterCompanyId, 1,  
       @IsOEM,@IsPMA, @IsDER,@IsOemPNId, @OEMPNNumber,@GLAccountId, @IsTimeLife,@EvidenceId, @IntegrationPortal);  
       
     SELECT @StockLineId = SCOPE_IDENTITY()  
  
     UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @SLCurrentNummber WHERE [CodeTypeId] = 30 AND [MasterCompanyId] = @MasterCompanyId --(30,17,9)  
  
     UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = @CNCurrentNummber WHERE [CodeTypeId] = 9 AND [MasterCompanyId] = @MasterCompanyId  
  
     EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId  
       
     UPDATE [dbo].[Stockline] SET Memo = 'This Stockline is created using turn-in from ' + @WorkOrderNumber,Unitcost= @Unitcost WHERE [StockLineId] = @StockLineId  

	 IF(@isExchange = 1)
	 BEGIN
		UPDATE [dbo].[Stockline] SET [WorkOrderMaterialsId] = @WorkOrderMaterialsId WHERE [StockLineId] = @StockLineId
	 END

	 IF(@WorkOrderTypeId = @TearDownWorkOrderTypeId)  
     BEGIN  
		UPDATE [dbo].[WorkOrderPartNumber] SET [TendorStocklineCost] = ISNULL(TendorStocklineCost,0) + ISNULL((@Quantity * @Unitcost),0) WHERE ID = @WorkOrderPartNoId;            
  
		DECLARE @OLDStockLineId BIGINT = 0;        
		SET @OLDStockLineId = (SELECT [StockLineId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId);  
  
		UPDATE [dbo].[Stockline] SET [Memo] = 'This Stockline cost is updated using turn-in to work order number ' + @WorkOrderNumber + ' new stockline is ' + @StockLineNumber--,  
			--[UnitCost] -= @Unitcost, 
			--[PurchaseOrderUnitCost] -= @Unitcost  			
		WHERE [StockLineId] = @OLDStockLineId;  

		-- TENDERING STOCKLINE ACCOUNTING ENTRY

		DECLARE @DistributionMasterId BIGINT=NULL

		SELECT @DistributionMasterId = [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'TENDERINGSTOCKLINETWO'
	
		EXEC [dbo].[USP_TearDownWOBatchTriggerBasedonDistribution] @DistributionMasterId,@WorkOrderId,@WorkOrderPartNoId,@StocklineId,@MasterCompanyId,@UpdatedBy
     END  
  
  --   IF(@IsSerialized =1 AND @SerialNumber IS NOT NULL AND @SerialNumber != '')  
  --   BEGIN
		--DECLARE @CurrentSerialNumber INT = 0; 
		--SELECT @CurrentSerialNumber = ISNULL([CurrentSerialNumber],0) FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId;
		--IF(@CurrentSerialNumber = 0)
		--BEGIN
		--	SET @CurrentSerialNumber = 1;
		--END
		--UPDATE [dbo].[WorkOrderPartNumber] SET [CurrentSerialNumber] = ISNULL(@CurrentSerialNumber,0) + 1 WHERE ID = @WorkOrderPartNoId;       
  --   END  
     --FOR STOCK LINE HISTORY  
     --WHILE @count >= @slcount  
     --BEGIN  
     -- SET @ReferenceId = 0;  
     -- SET @SubReferenceId = @WorkOrderMaterialsId  
     -- PRINT 'STEP - 1'  
     -- SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM [dbo].[Stockline] WITH (NOLOCK) WHERE StockLineId = @StocklineId  
        
     -- IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))  
     -- BEGIN  
     --  EXEC [dbo].[USP_CreateChildStockline]    
     --  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild,   
     --  @UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId        
     -- END  
     -- ELSE  
     -- BEGIN  
     --  PRINT 'STEP - 3'  
     --  EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 0, @AddHistoryForNonSerialized = 1, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId  
     -- END  
     -- PRINT 'STEP - 4'  
     -- SET @slcount = @slcount + 1;  
     --END;  
	 
	 DECLARE @ActionId INT = 0;
     --SET @ActionId = 7; -- Tender
	 SELECT @ActionId = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type] = 'Tendered'
	 DECLARE @HistoryModuleId INT = 0;
	 SELECT @HistoryModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'WorkOrder';
	 EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @HistoryModuleId, @ReferenceId = @WorkOrderId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @Quantity, @UpdatedBy = @UpdatedBy;

     --Add SL Managment Structure Details   
     EXEC USP_SaveSLMSDetails @MSModuleID, @StockLineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy  
  
     -- #STEP 2 ADD STOCKLINE TO WO MATERIAL LIST  
     IF (@IsKitType = 0)  
     BEGIN  
      IF (@IsMaterialStocklineCreate = 1)  
      BEGIN  
        IF ((SELECT COUNT(1) FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId AND [ConditionCodeId] = @ConditionId AND [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0) > 0)  
		BEGIN  
			UPDATE [dbo].[WorkOrderMaterials] SET   
			Quantity =  CASE WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity THEN Quantity ELSE  
			(ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity) END  
			--Quantity = Quantity + @Quantity   
			FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
			SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;  
				IF(@isExchange = 1)
				BEGIN				
					UPDATE [dbo].[Stockline] SET WorkOrderMaterialsId = @WorkOrderMaterialsId WHERE [StockLineId] = @StockLineId
				END
		END  
		ELSE  
		BEGIN  
			 IF(ISNULL(@IsMPNTendor,0) = 0)
			 BEGIN			
				INSERT INTO [dbo].[WorkOrderMaterials] ([WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId],  
				   [UnitCost],[ExtendedCost],[Memo],[IsDeferred], [QuantityReserved], [QuantityIssued], [MaterialMandatoriesId],[ProvisionId],[CreatedDate], [CreatedBy], [UpdatedDate],   
				   [UpdatedBy], [MasterCompanyId], [IsActive], [IsDeleted])   
				SELECT @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo,   
				   WOM.IsDeferred, 0, 0, WOM.MaterialMandatoriesId,WOM.ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
				FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)   
				 JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId  
				WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId;  
  
				SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()  
				IF(@isExchange = 1)
				BEGIN				
					UPDATE [dbo].[Stockline] SET [WorkOrderMaterialsId] = @NewWorkOrderMaterialsId WHERE [StockLineId] = @StockLineId
				END
			END
			ELSE
			BEGIN
				DECLARE @TaskId BIGINT = 0
				IF(@WorkOrderFormTypeId = 0)
				BEGIN
					SELECT @TaskId = ISNULL([TaskId],0) FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId

					IF(@TaskId = 0)
					BEGIN
						INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
						 	             VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);
						SET @TaskId = SCOPE_IDENTITY()  
					END
				END
				ELSE 
				BEGIN
					SET @TaskId = (SELECT TOP 1 ISNULL([WorkOrderTaskId],0) FROM [dbo].[WorkOrderTask] WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkOrderWorkflowId AND [MasterCompanyId] = @MasterCompanyId);
					IF(@TaskId = 0)
					BEGIN
						SET @TaskId = (SELECT ISNULL([TaskId],0) FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId);						
						IF(@TaskId = 0)
						BEGIN
							INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
						 	             VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);
							
							SET @TaskId = SCOPE_IDENTITY();

							INSERT INTO [dbo].[WorkOrderTask]([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName],[IsFromWorkFlow])
							 VALUES (@WorkOrderId,@WorkOrderWorkflowId,@TaskId,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@WorkOrderPartNoId,1,NULL,NULL,NULL,NULL,'ALL TASK',NULL)
							
							SET @TaskId = SCOPE_IDENTITY();

						END
						ELSE
						BEGIN
							INSERT INTO [dbo].[WorkOrderTask]([WorkOrderId],[WorkFlowWorkOrderId],[TaskId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[WorkOrderPartNumberId],[SequenceNumber],[OpenDate],[OpenBy],[IsIncludeInPrint],[HasInstruction],[TaskName],[IsFromWorkFlow])
							 VALUES (@WorkOrderId,@WorkOrderWorkflowId,@TaskId,@MasterCompanyId,@UpdatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@WorkOrderPartNoId,1,NULL,NULL,NULL,NULL,'ALL TASK',NULL)
							
							SET @TaskId = SCOPE_IDENTITY();
						END
					END
				END
				
				INSERT INTO [dbo].[WorkOrderMaterials] ([WorkOrderId], [WorkFlowWorkOrderId], [ItemMasterId], [TaskId], [ConditionCodeId], [ItemClassificationId], [Quantity], [UnitOfMeasureId],  
				   [UnitCost],[ExtendedCost],[Memo],[IsDeferred], [QuantityReserved], [QuantityIssued], [MaterialMandatoriesId],[ProvisionId],[CreatedDate], [CreatedBy], [UpdatedDate],   
				   [UpdatedBy], [MasterCompanyId], [IsActive], [IsDeleted]) 
				   
				SELECT @WorkOrderId, @WorkOrderWorkflowId, @ItemMasterId, @TaskId, @ConditionId, @ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo,   
				   0, 0, 0, 1,@ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   				
				
				SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()  

			END

	    END  
			   		 	  	  	   	  
       INSERT INTO [dbo].[WorkOrderMaterialStockLine](WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,   
           UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
       SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, @Quantity, 0, 0, 0, 0, 0,  
          GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
       FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)   
       WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;  
  
       DECLARE @WOMStockLineId BIGINT = 0  
  
       SELECT @WOMStockLineId = SCOPE_IDENTITY()  
  
       IF(@WorkOrderTypeId = @TearDownWorkOrderTypeId)  
       BEGIN  
			UPDATE [dbo].[WorkOrderMaterialStockLine] SET [UnitCost] = @Unitcost,[ExtendedCost] = ISNULL((@Quantity * @Unitcost),0) WHERE [WOMStockLineId]=@WOMStockLineId;  
       END  
  
       --UPDATE QTY TO TURN IN IF MISMATCH  
       SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn,0))   
       FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)  
        JOIN dbo.Stockline sl WITH (NOLOCK) ON womsl.StockLIneId = sl.StockLIneId  
        JOIN dbo.WorkOrderMaterials WOM WITH(NOLOCK) ON womsl.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId  
       WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
        AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0  
  
       SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn,0))                
       FROM dbo.WorkOrderMaterials WITH(NOLOCK)      
       WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId  
  
       IF (@QtyTendered > @QtyToTendered)  
       BEGIN  
			UPDATE dbo.WorkOrderMaterials SET [QtyToTurnIn] = @QtyTendered FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId  
       END 
	   
	   IF(ISNULL(@IsMPNTendor,0) = 1)
	   BEGIN  
			UPDATE dbo.WorkOrderMaterials SET [QtyToTurnIn] = @Quantity FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @NewWorkOrderMaterialsId  
       END 
  
       --UPDATE QTY REQ IN MATERIAL IF REQ QTY MISMATCH  
       SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity,0))   
       FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)         
       WHERE womsl.WorkOrderMaterialsId = @WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0   
  
       IF(@TotalStlQtyReq > (SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId))  
       BEGIN  
			UPDATE dbo.WorkOrderMaterials SET Quantity = @TotalStlQtyReq FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialsId  
       END  
  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE MATERIALS COST  
       EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId, @WorkFlowWorkOrderId = @WorkOrderWorkflowId;
        
      END  
     END  
     ELSE  
     BEGIN  
	 
      SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
  
      IF (@IsMaterialStocklineCreate = 1)  
      BEGIN  
       IF ((SELECT COUNT(1) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND   
        WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)  
       BEGIN  
        UPDATE dbo.WorkOrderMaterialsKit SET   
        Quantity =  CASE WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity THEN Quantity ELSE  
        (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity) END  
        FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
        SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;  
       END  
       ELSE  
       BEGIN  
        DECLARE @WorkOrderMaterialsKitMappingId BIGINT = NULL;  
  
        SELECT TOP 1 @WorkOrderMaterialsKitMappingId = WorkOrderMaterialsKitMappingId FROM DBO.WorkOrderMaterialsKit (NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
  
        INSERT INTO dbo.WorkOrderMaterialsKit (WorkOrderMaterialsKitMappingId, WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,  
           UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate,   
           UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
        SELECT @WorkOrderMaterialsKitMappingId, @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo,   
           WOM.IsDeferred, 0, 0, WOM.MaterialMandatoriesId,WOM.ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
        FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)   
         JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId  
        WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
  
        SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()  
       END  
  
       INSERT INTO dbo.WorkOrderMaterialStockLineKit (WorkOrderMaterialsKitId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued,   
           UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted)   
       SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, @Quantity, 0, 0, 0, 0, 0,  
          GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0   
       FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)   
       WHERE WOM.WorkOrderMaterialsKitId = @NewWorkOrderMaterialsId;  
  
       --UPDATE QTY TO TURN IN IF MISMATCH  
       SELECT @QtyTendered = SUM(ISNULL(sl.QuantityTurnIn,0))   
       FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)  
        JOIN dbo.Stockline sl WITH (NOLOCK) ON womsl.StockLIneId = sl.StockLIneId  
        JOIN dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) ON womsl.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId  
       WHERE WOM.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND womsl.ConditionId = WOM.ConditionCodeId  
        AND womsl.isActive = 1 AND womsl.isDeleted = 0 AND ISNULL(sl.QuantityTurnIn, 0) > 0  
  
       SELECT @QtyToTendered = SUM(ISNULL(QtyToTurnIn,0)) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK)  
       WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
  
       IF (@QtyTendered > @QtyToTendered)  
       BEGIN  
        UPDATE dbo.WorkOrderMaterialsKit SET QtyToTurnIn = @QtyTendered FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
       END  
  
       --UPDATE QTY REQ IN MATERIAL IF REQ QTY MISMATCH  
       SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity,0))   
       FROM dbo.WorkOrderMaterialStockLineKit womsl WITH (NOLOCK)  
       WHERE womsl.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0   
  
       IF(@TotalStlQtyReq > (SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId))  
       BEGIN  
        UPDATE dbo.WorkOrderMaterialsKit SET Quantity = @TotalStlQtyReq FROM dbo.WorkOrderMaterialsKit WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId  
       END  
  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE WO PART LEVEL TOTAL COST  
       EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;  
  
       --UPDATE MATERIALS COST  
       EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId, @WorkFlowWorkOrderId = @WorkOrderWorkflowId;  
      END  
     END  
  
     IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL  
     BEGIN  
      DROP TABLE #tmpCodePrefixes_Parent   
     END  
  
     IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL  
     BEGIN  
      DROP TABLE #tmpPNManufacturer   
     END  

	 SELECT @StockLineId as StockLineId
    END  
   COMMIT  TRANSACTION 
    END TRY        
 BEGIN CATCH
  IF @@trancount > 0    
   PRINT 'ROLLBACK'  
    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'usp_SaveTurnInWorkOrderMaterils'     
			, @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))  
            , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                    @DatabaseName           = @DatabaseName    
                    , @AdhocComments          = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName        =  @ApplicationName    
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
            RETURN(1);    
 END CATCH    
END