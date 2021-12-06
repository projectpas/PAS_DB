﻿
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

exec dbo.usp_SaveTurnInWorkOrderMaterils @IsMaterialStocklineCreate=1,@IsCustomerStock=1,@IsCustomerstockType=0,@ItemMasterId=240,@UnitOfMeasureId=36,
@ConditionId=1,@Quantity=1,@IsSerialized=1,@SerialNumber='09888909',@CustomerId=7,@ObtainFromTypeId=NULL,@ObtainFrom=NULL,@ObtainFromName=N'',@OwnerTypeId=NULL,
@Owner=NULL,@OwnerName=N'',@TraceableToTypeId=NULL,@TraceableTo=NULL,@TraceableToName=N'',@Memo=N'<p>Test</p>',@WorkOrderId=N'395',
@WorkOrderNumber=N'CWO135-2020',@ManufacturerId=4,@InspectedById=NULL,@InspectedDate=NULL,@ReceiverNumber=N'REC1212',@ReceivedDate='2021-08-04 18:30:00',
@ManagementStructureId=72,@SiteId=2,@WarehouseId=4,@LocationId=4,@ShelfId=4,@BinId=8,@MasterCompanyId=1,@UpdatedBy=N'Don Budhu',@WorkOrderMaterialsId=573

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
		
		BEGIN TRY
			-- #STEP 1 CREATE STOCKLINE
			BEGIN TRANSACTION
				BEGIN
					
					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCodePrefixes
					END
				
					CREATE TABLE #tmpCodePrefixes
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 CodePrefixId BIGINT NULL,
						 CodeTypeId BIGINT NULL,
						 CurrentNummber BIGINT NULL,
						 CodePrefix VARCHAR(50) NULL,
						 CodeSufix VARCHAR(50) NULL,
						 StartsFrom BIGINT NULL,
					)

					SELECT @PartNumber = partnumber FROM dbo.ItemMaster WITH(NOLOCK) WHERE ItemMasterId = @ItemMasterId;
					SELECT @WorkOrderNumber = WorkOrderNum FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
					SELECT @WorkOrderWorkflowId = WorkFlowWorkOrderId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId

					INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId IN (30,17,9) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 30))
					BEGIN 
						SELECT 
							@SLCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 
								ELSE CAST(StartsFrom AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = 30

						SET @StockLineNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@SLCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 30), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 30)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 9))
					BEGIN 
						SELECT 
							@CNCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 
								ELSE CAST(StartsFrom AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = 9

						SET @ControlNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CNCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 9), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 9)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END

					IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = 17))
					BEGIN 
						SELECT 
							@IDCurrentNummber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) + 1 
								ELSE CAST(StartsFrom AS BIGINT) + 1 END 
						FROM #tmpCodePrefixes WHERE CodeTypeId = 17

						SET @IDNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@IDCurrentNummber,(SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = 17), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = 17)))
					END
					ELSE 
					BEGIN
						ROLLBACK TRAN;
					END

					INSERT INTO dbo.Stockline(StockLineNumber, ControlNumber, IDNumber, IsCustomerStock,IsCustomerstockType,ItemMasterId,PartNumber, PurchaseUnitOfMeasureId,ConditionId,Quantity, 
							QuantityAvailable, QuantityOnHand,QuantityTurnIn,IsSerialized,SerialNumber, CustomerId, ObtainFromType, ObtainFrom, ObtainFromName, OwnerType, [Owner], OwnerName, TraceableToType, 
							TraceableTo, TraceableToName, Memo, WorkOrderId, WorkOrderNumber, ManufacturerId, InspectionBy, InspectionDate, ReceiverNumber, IsParent, LotCost, ParentId,
							QuantityIssued, QuantityReserved,QuantityToReceive,RepairOrderExtendedCost, SubWOPartNoId,SubWorkOrderId, WorkOrderExtendedCost, WorkOrderPartNoId,
							ReceivedDate, ManagementStructureId, SiteId, WarehouseId, LocationId, ShelfId, BinId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,isActive, isDeleted, MasterCompanyId
					) VALUES(@StockLineNumber, @ControlNumber, @IDNumber, @IsCustomerStock,@IsCustomerstockType,@ItemMasterId,@PartNumber,@UnitOfMeasureId,@ConditionId,@Quantity, @Quantity, @Quantity, @Quantity,
							@IsSerialized,@SerialNumber, @CustomerId, @ObtainFromTypeId, @ObtainFrom, @ObtainFromName, @OwnerTypeId, @Owner, @OwnerName, @TraceableToTypeId, 
							@TraceableTo, @TraceableToName, @Memo, @WorkOrderId, @WorkOrderNum, @ManufacturerId, @InspectedById, @InspectedDate, @ReceiverNumber, 1, 0,0,0,0,0,0,0,0,0,0,
							@ReceivedDate, @ManagementStructureId, @SiteId, @WarehouseId, @LocationId, @ShelfId, @BinId, @UpdatedBy, @UpdatedBy, GETDATE(),GETDATE(),1,0, @MasterCompanyId);
					
					SELECT @StockLineId = SCOPE_IDENTITY()

					UPDATE CodePrefixes SET CurrentNummber = @SLCurrentNummber WHERE CodeTypeId = 30 AND MasterCompanyId = @MasterCompanyId --(30,17,9)
					UPDATE CodePrefixes SET CurrentNummber = @CNCurrentNummber WHERE CodeTypeId = 9 AND MasterCompanyId = @MasterCompanyId
					--UPDATE CodePrefixes SET CurrentNummber = @IDNumber WHERE CodeTypeId = 17 AND MasterCompanyId = @MasterCompanyId

					EXEC [dbo].[UpdateStocklineColumnsWithId] @StockLineId = @StockLineId

					-- #STEP 2 ADD STOCKLINE TO WO MATERIAL LIST
					IF(@IsMaterialStocklineCreate = 1)
					BEGIN
						IF((SELECT COUNT(1) FROM dbo.WorkOrderMaterials WHERE ItemMasterId = @ItemMasterId AND ConditionCodeId = @ConditionId AND 
							WorkFlowWorkOrderId = @WorkOrderWorkflowId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0) > 0)
						BEGIN
							UPDATE dbo.WorkOrderMaterials SET Quantity = Quantity + @Quantity FROM dbo.WorkOrderMaterials WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId
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

						INSERT INTO dbo.WorkOrderMaterialStockLine (WorkOrderMaterialsId, StockLineId, ItemMasterId, ProvisionId, ConditionId, Quantity, QtyReserved, QtyIssued,
									UnitCost,ExtendedCost,UnitPrice,CreatedDate, CreatedBy, UpdatedDate,UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
						SELECT @NewWorkOrderMaterialsId, @StockLineId, @ItemMasterId, WOM.ProvisionId, @ConditionId, @Quantity, 0, 0, 0, 0, 0,
									GETDATE(), @UpdatedBy, GETDATE(), @UpdatedBy, @MasterCompanyId, 1, 0 
						FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) 
						WHERE WOM.WorkOrderMaterialsId = @NewWorkOrderMaterialsId;

						--UPDATE WO PART LEVEL TOTAL COST
						EXEC USP_UpdateWOTotalCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

						--UPDATE WO PART LEVEL TOTAL COST
						EXEC USP_UpdateWOCostDetails @WorkOrderId = @WorkOrderId, @WorkOrderWorkflowId = @WorkOrderWorkflowId, @UpdatedBy = @UpdatedBy ;

						--UPDATE MATERIALS COST
						EXEC USP_UpdateWOMaterialsCost @WorkOrderMaterialsId = @NewWorkOrderMaterialsId;
					END

					IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCodePrefixes 
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