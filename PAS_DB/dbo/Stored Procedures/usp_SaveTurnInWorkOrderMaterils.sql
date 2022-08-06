
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
** 1    07/30/2021  Hemant Saliya    Initilial Draft

exec dbo.usp_SaveTurnInWorkOrderMaterils @IsMaterialStocklineCreate=1,@IsCustomerStock=1,@IsCustomerstockType=0,@ItemMasterId=291,@UnitOfMeasureId=5,
@ConditionId=10,@Quantity=2,@IsSerialized=0,@SerialNumber=NULL,@CustomerId=80,@ObtainFromTypeId=1,@ObtainFrom=80,@ObtainFromName=N'anil gill ',
@OwnerTypeId=NULL,@Owner=NULL,@OwnerName=N'',@TraceableToTypeId=NULL,@TraceableTo=NULL,@TraceableToName=N'',@Memo=N' ',@WorkOrderId=N'320',
@WorkOrderNumber=N'WO-000161',@ManufacturerId=9,@InspectedById=NULL,@InspectedDate=NULL,@ReceiverNumber=N'RCTS#-000087',@ReceivedDate='2022-07-29 13:04:59.237',
@ManagementStructureId=1,@SiteId=2,@WarehouseId=NULL,@LocationId=NULL,@ShelfId=NULL,@BinId=NULL,@MasterCompanyId=1,@UpdatedBy=N'ADMIN ADMIN',@WorkOrderMaterialsId=395

**************************************************************/ 
CREATE PROCEDURE [dbo].[usp_SaveTurnInWorkOrderMaterils]
@IsMaterialStocklineCreate BIT = FLASE,
@IsCustomerStock BIT = TRUE,
@IsCustomerstockType BIT,
@ItemMasterId BIGINT,
@UnitOfMeasureId BIGINT,
@ConditionId BIGINT,
@Quantity INT,
@IsSerialized BIT,
@SerialNumber VARCHAR(50),
@CustomerId BIGINT,
@ObtainFromTypeId INT = NULL,
@ObtainFrom BIGINT = NULL,
@ObtainFromName VARCHAR(500),
@OwnerTypeId INT = NULL,
@Owner BIGINT = NULL,
@OwnerName VARCHAR(500),
@TraceableToTypeId INT = NULL,
@TraceableTo BIGINT = NULL,
@TraceableToName VARCHAR(500),
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
@WorkOrderMaterialsId BIGINT
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
	DECLARE @WorkOrderWorkflowId BIGINT;
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
		
		BEGIN TRY
			-- #STEP 1 CREATE STOCKLINE
			BEGIN TRANSACTION
				BEGIN
					DECLARE @QtyTendered INT = 0;
					DECLARE @QtyToTendered INT = 0;
					DECLARE @TotalStlQtyReq INT = 0;

					SET @count = @Quantity;
					SET @slcount = @Quantity;
					SET @IsAddUpdate = 1;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 0;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;

					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 22; -- For Stockline Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 33; -- For WORK ORDER Materials Module

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCodePrefixes_Parent
					END
				
					CREATE TABLE #tmpCodePrefixes_Parent
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 CodePrefixId BIGINT NULL,
						 CodeTypeId BIGINT NULL,
						 CurrentNummber BIGINT NULL,
						 CodePrefix VARCHAR(50) NULL,
						 CodeSufix VARCHAR(50) NULL,
						 StartsFrom BIGINT NULL,
					)

					/* PN Manufacturer Combination Stockline logic */
					CREATE TABLE #tmpPNManufacturer
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 ItemMasterId BIGINT NULL,
						 ManufacturerId BIGINT NULL,
						 StockLineNumber VARCHAR(100) NULL,
						 CurrentStlNo BIGINT NULL,
						 isSerialized BIT NULL
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

					SELECT @PartNumber = partnumber, @IsPMA = IsPMA, @IsDER = IsDER, @IsOemPNId = IsOemPNId, @IsOEM = IsOEM, @OEMPNNumber = OEMPN  FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;
					SELECT @WorkOrderNumber = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
					SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId

					INSERT INTO #tmpCodePrefixes_Parent (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					DECLARE @currentNo AS BIGINT;
					DECLARE @stockLineCurrentNo AS BIGINT;

					SELECT @currentNo = ISNULL(CurrentStlNo, 0) FROM #tmpPNManufacturer WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId

					IF (@currentNo <> 0)
					BEGIN
						SET @stockLineCurrentNo = @currentNo + 1
					END
					ELSE
					BEGIN
						SET @stockLineCurrentNo = 1
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30))
					BEGIN 
						SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@stockLineCurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 30)))

						UPDATE DBO.ItemMaster
						SET CurrentStlNo = @stockLineCurrentNo
						WHERE ItemMasterId = @ItemMasterId AND ManufacturerId = @ManufacturerId
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

						SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CNCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 9)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17))
					BEGIN 
						SET @IDCurrentNummber = 1;

						SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@IDCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes_Parent WHERE CodeTypeId = 17)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END

					INSERT INTO dbo.Stockline(StockLineNumber, ControlNumber, IDNumber, IsCustomerStock,IsCustomerstockType,ItemMasterId,PartNumber, PurchaseUnitOfMeasureId,ConditionId,Quantity, 
							QuantityAvailable, QuantityOnHand,QuantityTurnIn,IsSerialized,SerialNumber, CustomerId, ObtainFromType, ObtainFrom, ObtainFromName, OwnerType, [Owner], OwnerName, TraceableToType, 
							TraceableTo, TraceableToName, Memo, WorkOrderId, WorkOrderNumber, ManufacturerId, InspectionBy, InspectionDate, ReceiverNumber, IsParent, LotCost, ParentId,
							QuantityIssued, QuantityReserved,QuantityToReceive,RepairOrderExtendedCost, SubWOPartNoId,SubWorkOrderId, WorkOrderExtendedCost, WorkOrderPartNoId,
							ReceivedDate, ManagementStructureId, SiteId, WarehouseId, LocationId, ShelfId, BinId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,isActive, isDeleted, MasterCompanyId, IsTurnIn,
							[OEM],IsPMA, IsDER,IsOemPNId, OEMPNNumber
					) VALUES(@StockLineNumber, @ControlNumber, @IDNumber, @IsCustomerStock,@IsCustomerstockType,@ItemMasterId,@PartNumber,@UnitOfMeasureId,@ConditionId,@Quantity, @Quantity, @Quantity, @Quantity,
							@IsSerialized,@SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName, @TraceableToTypeId, 
							@TraceableTo, @TraceableToName, @Memo, @WorkOrderId, @WorkOrderNum, @ManufacturerId, @InspectedById, @InspectedDate, @ReceiverNumber, 1, 0,0,0,0,0,0,0,0,0,0,
							@ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @UpdatedBy, @UpdatedBy, GETDATE(),GETDATE(),1,0, @MasterCompanyId, 1,
							@IsOEM,@IsPMA, @IsDER,@IsOemPNId, @OEMPNNumber);
					
					SELECT @StockLineId = SCOPE_IDENTITY()

					UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNummber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId --(30,17,9)
					UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNummber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId

					EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId
					
					--FOR STOCK LINE HISTORY
					WHILE @count >= @slcount
					BEGIN
						SET @ReferenceId = 0;
						SET @SubReferenceId = @WorkOrderMaterialsId
						PRINT 'STEP - 1'
						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId
						
						IF (@IsSerialised = 0 AND (@stockLineQtyAvailable > 1 OR @stockLineQty > 1))
						BEGIN
							EXEC [dbo].[USP_CreateChildStockline]  
							@StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = @IsAddUpdate, @ExecuteParentChild = @ExecuteParentChild, 
							@UpdateQuantities = @UpdateQuantities, @IsOHUpdated = @IsOHUpdated, @AddHistoryForNonSerialized = @AddHistoryForNonSerialized, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						
						END
						ELSE
						BEGIN
							PRINT 'STEP - 3'
							EXEC [dbo].[USP_CreateChildStockline]  @StocklineId = @StocklineId, @MasterCompanyId = @MasterCompanyId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @IsAddUpdate = 0, @ExecuteParentChild = 0, @UpdateQuantities = 0, @IsOHUpdated = 0, @AddHistoryForNonSerialized = 1, @SubModuleId = @SubModuleId, @SubReferenceId = @SubReferenceId
						END
						PRINT 'STEP - 4'
						SET @slcount = @slcount + 1;
					END;

					--Add SL Managment Structure Details 
					EXEC USP_SaveSLMSDetails @MSModuleID, @StockLineId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy
					-- #STEP 2 ADD STOCKLINE TO WO MATERIAL LIST
					IF(@IsMaterialStocklineCreate = 1)
					BEGIN

						IF((SELECT COUNT(1) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND 
							WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)
						BEGIN
							UPDATE dbo.WorkOrderMaterials SET 
							Quantity =  CASE WHEN ISNULL(Quantity, 0) - (ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0)) >= @Quantity THEN Quantity ELSE
							(ISNULL(QuantityReserved, 0) + ISNULL(QuantityIssued, 0) + @Quantity) END
							--Quantity = Quantity + @Quantity 
							FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
							SELECT @NewWorkOrderMaterialsId = @WorkOrderMaterialsId;
						END
						ELSE
						BEGIN
							INSERT INTO dbo.WorkOrderMaterials (WorkOrderId, WorkFlowWorkOrderId, ItemMasterId, TaskId, ConditionCodeId, ItemClassificationId, Quantity, UnitOfMeasureId,
										UnitCost,ExtendedCost,Memo,IsDeferred, QuantityReserved, QuantityIssued, MaterialMandatoriesId,ProvisionId,CreatedDate, CreatedBy, UpdatedDate, 
										UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
							SELECT @WorkOrderId, WOWF.WorkFlowWorkOrderId, @ItemMasterId, WOM.TaskId, @ConditionId, WOM.ItemClassificationId, @Quantity, @UnitOfMeasureId, 0, 0, @Memo, 
										WOM.IsDeferred, 0, 0, WOM.MaterialMandatoriesId,WOM.ProvisionId,GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 
							FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
								JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
							WHERE WOM.WorkOrderMaterialsId = @WorkOrderMaterialsId;

							SELECT @NewWorkOrderMaterialsId = SCOPE_IDENTITY()
						END

						INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QuantityTurnIn, QtyReserved, QtyIssued, 
									UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
						SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, @Quantity, 0, 0, 0, 0, 0,
									GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 
						FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
						WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

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

						IF(@QtyTendered > @QtyToTendered)
						BEGIN
							UPDATE dbo.WorkOrderMaterials SET QtyToTurnIn = @QtyTendered FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
						END

						--UPDATE QTY REQ IN MATERIAL IF REQ QTY MISMATCH
						SELECT @TotalStlQtyReq = SUM(ISNULL(womsl.Quantity,0)) 
						FROM dbo.WorkOrderMaterialStockLine womsl WITH (NOLOCK)							
						WHERE womsl.WorkOrderMaterialsId = @WorkOrderMaterialsId AND womsl.isActive = 1 AND womsl.isDeleted = 0 

						IF(@TotalStlQtyReq > (SELECT ISNULL(Quantity, 0) FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId))
						BEGIN
							UPDATE dbo.WorkOrderMaterials SET Quantity = @TotalStlQtyReq FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
						END

						--UPDATE WO PART LEVEL TOTAL COST
						EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

						--UPDATE WO PART LEVEL TOTAL COST
						EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

						--UPDATE MATERIALS COST
						EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId;
						
					END

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes_Parent') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCodePrefixes_Parent 
					END

					IF OBJECT_ID(N'tempdb..#tmpPNManufacturer') IS NOT NULL
					BEGIN
						DROP TABLE #tmpPNManufacturer 
					END
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''',
													   @Parameter3 = ' + ISNULL(@UnitOfMeasureId,'') + ', 
													   @Parameter4 = ' + CAST(ISNULL(@IsCustomerStock,'') AS VARCHAR) + ', 
													   @Parameter5 = ' + CAST(ISNULL(@IsCustomerstockType,'') AS VARCHAR) + ', 
													   @Parameter6 = ' + ISNULL(@ConditionId,'') + ', 
													   @Parameter7 = ' + ISNULL(@Quantity,'') + ', 		
													   @Parameter8 = ' + CAST(ISNULL(@IsSerialized,'') AS VARCHAR) + ', 
													   @Parameter9 = ' + ISNULL(@SerialNumber,'') + ', 
													   @Parameter10 = ' + ISNULL(@CustomerId,'') + ', 
													   @Parameter11 = ' + ISNULL(@ObtainFromTypeId,'') + ', 
													   @Parameter12 = ' + ISNULL(@ObtainFrom,'') + ', 
													   @Parameter13 = ' + ISNULL(@ObtainFromName,'') + ', 
													   @Parameter14 = ' + ISNULL(@OwnerTypeId,'') + ', 
													   @Parameter15 = ' + ISNULL(@Owner,'') + ', 
													   @Parameter16 = ' + ISNULL(@OwnerName,'') + ', 
													   @Parameter17 = ' + ISNULL(@TraceableToTypeId,'') + ', 
													   @Parameter18 = ' + ISNULL(@TraceableTo,'') + ', 
													   @Parameter19 = ' + ISNULL(@TraceableToName,'') + ', 
													   @Parameter20 = ' + ISNULL(@Memo,'') + ', 
													   @Parameter21 = ' + ISNULL(@WorkOrderId,'') + ', 
													   @Parameter22 = ' + ISNULL(@WorkOrderNumber,'') + ', 
													   @Parameter23 = ' + ISNULL(@ManufacturerId,'') + ', 
													   @Parameter24 = ' + ISNULL(@InspectedById,'') + ', 
													   @Parameter25 = ' + CAST(ISNULL(@InspectedDate,'') AS VARCHAR) + ', 
													   @Parameter26 = ' + ISNULL(@ReceiverNumber,'') + ', 
													   @Parameter27 = ' + CAST(ISNULL(@ReceivedDate,'') AS VARCHAR) + ', 
													   @Parameter28 = ' + ISNULL(@ManagementStructureId,'') + ', 
													   @Parameter29 = ' + ISNULL(@SiteId,'') + ', 
													   @Parameter30 = ' + ISNULL(@WarehouseId,'') + ', 
													   @Parameter31 = ' + ISNULL(@LocationId,'') + ', 
													   @Parameter32 = ' + ISNULL(@ShelfId,'') + ',
													   @Parameter33 = ' + ISNULL(@MasterCompanyId,'') + ',
													   @Parameter34 = ' + ISNULL(@UpdatedBy,'') + ''
													   
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END