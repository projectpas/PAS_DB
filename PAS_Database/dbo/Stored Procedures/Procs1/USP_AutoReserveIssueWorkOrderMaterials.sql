/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <01/23/2023>  
** Description: <Save Work Order Materials reserve & Issue Stockline Details>  
  
EXEC [USP_AutoReserveIssueWorkOrderMaterials] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    01/23/2023  HEMANT SALIYA    Save Work Order Materials reserve & Issue Stockline Details
** 2    04/27/2023  HEMANT SALIYA    Added Employeed Params
** 3    05/26/2023  HEMANT SALIYA    Added WO Type ID for Get Seeting based on WO Type
** 4    07/20/2023  VISHAL SUTHAR    Added new stockline history
** 5    07/26/2023	HEMANT SALIYA	 Allow User to reserver & Issue other Customer Stock as well
** 6    09/14/2023	DEVENDRA SHEKH	 Changed modulename 'WO' to 'WOP-PartsIssued'
** 7    06/27/2024  HEMANT SALIYA	 Update Stockline Qty Issue fox for MTI(Same Stk with multiple Lines)
** 8    08/05/2024  HEMANT SALIYA	 Fixed MTI stk Reserve Qty was not updating
** 9    09/12/2024  RAJESH GAMI		 Implemented Stockline History for the IssueReserve

EXEC USP_AutoReserveIssueWorkOrderMaterials 4933,'ADMIN ADMIN'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_AutoReserveIssueWorkOrderMaterials]
@WorkFlowWorkOrderId BIGINT,
@UpdatedBy VARCHAR(200)
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN
					DECLARE @ProvisionId BIGINT;
					DECLARE @MasterCompanyId BIGINT;
					DECLARE @WorkOrderTypeId BIGINT;
					DECLARE @SubWOProvisionId BIGINT;
					DECLARE @Provision VARCHAR(50);
					DECLARE @ProvisionCode VARCHAR(50);
					DECLARE @CustomerID BIGINT;
					DECLARE @ARDesc VARCHAR(100);
					DECLARE @EmployeeID BIGINT;
					DECLARE @TotalCountsBoth INT;

					SELECT @ProvisionId = ProvisionId, @Provision = [Description], @ProvisionCode = StatusCode FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @SubWOProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @CustomerID = WO.CustomerId, @MasterCompanyId = WO.MasterCompanyId, @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WO WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) on WO.WorkOrderId = WOWF.WorkOrderId WHERE WOWF.WorkFlowWorkOrderId = @WorkFlowWorkOrderId;
					SELECT TOP 1 @ARDesc = [Description] FROM DBO.Condition WHERE Code = 'ASREMOVE' AND MasterCompanyId = @MasterCompanyId AND ISNULL(IsDeleted,0) = 0 AND ISNULL(IsActive,0) = 1
					select @EmployeeID = EmployeeId FROM dbo.Employee WITH(NOLOCK) WHERE CONCAT(FirstName,' ',LastName) IN (@UpdatedBy) AND MasterCompanyId= @MasterCompanyId

					--GET Stockline List For Auto Reserve
					IF((SELECT COUNT(1) FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND WorkOrderTypeId = @WorkOrderTypeId AND ISNULL(IsAutoIssue, 0) = 1) > 0)
					BEGIN
						SELECT DISTINCT  WOM.WorkOrderId,
							WOM.WorkFlowWorkOrderId,
							WOM.WorkOrderMaterialsId,						
							WOM.ItemMasterId,
							WOM.ConditionCodeId AS ConditionId,
							WOM.MasterCompanyId,
							WOM.Quantity,
							WOM.QuantityReserved,
							WOM.QuantityIssued,
							WOM.QtyOnOrder AS QuantityOnOrder,
							(ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) AS QtyToBeReserved,
							WOM.UnitCost,
							WOM.ExtendedCost,
							WOM.TaskId,
							WOM.ProvisionId,
							IM.PartNumber,
							IM.PartDescription, 
							SL.StocklineId,
							SL.Condition,
							SL.StockLineNumber,
							SL.ControlNumber,
							SL.IdNumber,
							SL.Manufacturer,
							SL.SerialNumber,
							SL.QuantityAvailable AS QuantityAvailable,
							SL.QuantityOnHand AS QuantityOnHand,
							ISNULL(SL.QuantityOnOrder, 0) AS StocklineQuantityOnOrder,
							ISNULL(SL.QuantityTurnIn, 0) AS StocklineQuantityTurnIn,
							SL.UnitOfMeasure,
							P.Description AS Provision,
							P.StatusCode AS ProvisionStatusCode,
							CASE 
							WHEN IM.IsPma = 1 and IM.IsDER = 1 THEN 'PMA&DER'
							WHEN IM.IsPma = 1 and IM.IsDER = 0 THEN 'PMA'
							WHEN IM.IsPma = 0 and IM.IsDER = 1 THEN 'DER'
							ELSE 'OEM'
							END AS StockType,
							CASE WHEN ISNULL(WOMS.Quantity, 0) > 0 THEN WOMS.Quantity ELSE (ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId) END
							AS MSQuantityRequsted,
							WOMS.QtyReserved AS MSQuantityReserved,
							WOMS.QtyIssued AS MSQuantityIssued,
							SL.UnitCost AS SLUnitCost,
							@EmployeeId AS ReservedById,
							WOMS.UpdatedBy AS ReservedBy,
							MSQunatityRemaining = ISNULL(WOMS.Quantity, 0) - (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)),
							CASE WHEN ISNULL(SP.Description, '') != '' THEN SP.Description ELSE @Provision END AS MatStlProvision,
							CASE WHEN ISNULL(SP.StatusCode, '') != '' THEN SP.StatusCode ELSE @ProvisionCode END AS MatStlProvisionCode,
							CASE WHEN WOMS.WOMStockLineId > 0 THEN 1 ELSE 0 END AS IsStocklineAdded	
						INTO #tmpReserveIssueWOMaterialsStockline
						FROM dbo.WorkOrderMaterials WOM WITH (NOLOCK)  
							JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
							JOIN dbo.Stockline SL WITH (NOLOCK) ON WOM.ItemMasterId = SL.ItemMasterId AND WOM.ConditionCodeId = SL.ConditionId AND SL.StockLineId NOT IN (SELECT WOMS.StockLineId FROM dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.ProvisionId != @ProvisionId)
							JOIN dbo.WorkOrderMaterialStockLine WOMS WITH (NOLOCK) ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND SL.StockLineId = WOMS.StockLineId AND WOMS.ProvisionId = @ProvisionId
							LEFT JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
							LEFT JOIN dbo.Provision SP WITH (NOLOCK) ON SP.ProvisionId = WOMS.ProvisionId 
							LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.FirstName + ' ' + EMP.LastName = WOMS.UpdatedBy 
							LEFT JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = WOM.UnitOfMeasureId
						WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(SL.QuantityAvailable,0) > 0 AND SL.IsParent = 1 AND WOM.IsDeleted = 0  
							AND ISNULL((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0))) - (SELECT ISNULL(SUM(WOMSL.Quantity), 0) - (ISNULL(SUM(WOMSL.QtyReserved), 0) + ISNULL(SUM(WOMSL.QtyIssued), 0))  FROM dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) WHERE WOM.WorkOrderMaterialsId = WOMSL.WorkOrderMaterialsId AND WOMSL.ProvisionId <> @ProvisionId), 0) > 0
							AND (WOM.ProvisionId = @ProvisionId OR WOM.ProvisionId = @SubWOProvisionId)
							AND (SELECT TOP 1 Description FROM DBO.Condition cnd WITH(NOLOCK) WHERE cnd.ConditionId = WOM.ConditionCodeId AND ISNULL(cnd.IsDeleted,0) = 0 AND ISNULL(cnd.IsActive,0) = 1) != @ARDesc
						
						--PRINT '--Auto Reserve & Issue Stockline'
						--Auto Reserve & Issue Stockline
						IF((SELECT COUNT(1) FROM #tmpReserveIssueWOMaterialsStockline) > 0)
						BEGIN
							--CASE 1 UPDATE WORK ORDER MATERILS
							DECLARE @count INT;
							DECLARE @slcount INT;
							DECLARE @TotalCounts INT;
							DECLARE @StocklineId BIGINT; 
							DECLARE @ModuleId INT;
							DECLARE @ReferenceId BIGINT;
							DECLARE @IsAddUpdate BIT; 
							DECLARE @ExecuteParentChild BIT; 
							DECLARE @UpdateQuantities BIT;
							DECLARE @IsOHUpdated BIT; 
							DECLARE @AddHistoryForNonSerialized BIT; 
							DECLARE @SubModuleId INT;
							DECLARE @SubReferenceId BIGINT;
							DECLARE @ReservePartStatus INT;
							DECLARE @WorkOrderMaterialsId BIGINT;
							DECLARE @IsSerialised BIT;
							DECLARE @stockLineQty INT;
							DECLARE @stockLineQtyAvailable INT;

							DECLARE @RC int;
							DECLARE @DistributionMasterId bigint;
							DECLARE @ReferencePartId bigint;
							DECLARE @ReferencePieceId bigint;
							DECLARE @InvoiceId bigint=0;
							DECLARE @IssueQty bigint=0;
							DECLARE @laborType varchar(200)='';
							DECLARE @issued bit=1;
							DECLARE @Amount decimal(18,2);
							DECLARE @ModuleName varchar(200)='WOP-PartsIssued';
							DECLARE @UpdateBy varchar(200);

							SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPLACE' AND IsActive = 1 AND IsDeleted = 0;
							SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module
							SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For WORK ORDER Materials Module
							SELECT @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')
						
							SET @ReservePartStatus = 3; -- FOR RESERTVE & ISSUE
							SET @IsAddUpdate = 0;
							SET @ExecuteParentChild = 1;
							SET @UpdateQuantities = 1;
							SET @IsOHUpdated = 0;
							SET @AddHistoryForNonSerialized = 0;					
							SET @slcount = 1;
							SET @count = 1;

							IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
							BEGIN
							DROP TABLE #tmpReserveWOMaterialsStockline
							END
			
							CREATE TABLE #tmpReserveWOMaterialsStockline
							(
								ID BIGINT NOT NULL IDENTITY, 
								[WorkOrderId] BIGINT NULL,
								[WorkFlowWorkOrderId] BIGINT NULL,
								[WorkOrderMaterialsId] BIGINT NULL,
								[StockLineId] BIGINT NULL,
								[ItemMasterId] BIGINT NULL,
								[ConditionId] BIGINT NULL,
								[ProvisionId] BIGINT NULL,
								[TaskId] BIGINT NULL,
								[ReservedById] BIGINT NULL,
								[Condition] VARCHAR(500) NULL,
								[PartNumber] VARCHAR(500) NULL,
								[PartDescription] VARCHAR(max) NULL,
								[Quantity] INT NULL,
								[QtyToBeReserved] INT NULL,
								[QuantityActReserved] INT NULL,
								[ControlNo] VARCHAR(500) NULL,
								[ControlId] VARCHAR(500) NULL,
								[StockLineNumber] VARCHAR(500) NULL,
								[SerialNumber] VARCHAR(500) NULL,
								[ReservedBy] VARCHAR(500) NULL,						 
								[IsStocklineAdded] BIT NULL,
								[MasterCompanyId] BIGINT NULL,
								[UpdatedBy] VARCHAR(500) NULL,
								[UnitCost] DECIMAL(18,2),
								[IsSerialized] BIT
							)

							IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
							BEGIN
							DROP TABLE #tmpIgnoredStockline
							END
			
							CREATE TABLE #tmpIgnoredStockline
							(
								ID BIGINT NOT NULL IDENTITY, 
								[Condition] VARCHAR(500) NULL,
								[PartNumber] VARCHAR(500) NULL,
								[ControlNo] VARCHAR(500) NULL,
								[ControlId] VARCHAR(500) NULL,
								[StockLineNumber] VARCHAR(500) NULL,
							)

							INSERT INTO #tmpReserveWOMaterialsStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
								[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
								[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized])
							SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
								[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QtyToBeReserved], tblMS.[ControlNumber], tblMS.[IdNumber],
								tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized
							FROM #tmpReserveIssueWOMaterialsStockline tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
							WHERE SL.QuantityAvailable > 0 AND SL.QuantityAvailable >= tblMS.QtyToBeReserved AND SL.QuantityOnHand > 0 AND SL.QuantityOnHand >= tblMS.QtyToBeReserved

							SELECT @TotalCounts = COUNT(ID) FROM #tmpReserveWOMaterialsStockline;
							SELECT @TotalCountsBoth = MAX(ID) FROM #tmpReserveWOMaterialsStockline;

							INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
							SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNumber], tblMS.[IdNumber], tblMS.[StockLineNumber] FROM #tmpReserveIssueWOMaterialsStockline tblMS  
							WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpReserveWOMaterialsStockline)
		
							--PRINT '--UPDATE WORK ORDER MATERIALS DETAILS'
							--UPDATE WORK ORDER MATERIALS DETAILS
							WHILE @count<= @TotalCounts
							BEGIN
								UPDATE WorkOrderMaterials 
									SET 
										QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
										TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityActReserved,0),
										IssuedById = tmpWOM.ReservedById, 
										IssuedDate = GETDATE(), 
										UpdatedDate = GETDATE(),
										PartStatusId = @ReservePartStatus
								FROM dbo.WorkOrderMaterials WOM JOIN #tmpReserveWOMaterialsStockline tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND tmpWOM.ID = @count
								SET @count = @count + 1;
							END;
					
							--SELECT * FROM #tmpReserveWOMaterialsStockline
							--UPDATE/INSERT WORK ORDER MATERIALS STOCKLINE DETAILS
							IF(@TotalCounts > 0 )
							BEGIN
								MERGE dbo.WorkOrderMaterialStockLine AS TARGET
								USING #tmpReserveWOMaterialsStockline AS SOURCE ON (TARGET.StocklineId = SOURCE.StocklineId AND SOURCE.WorkOrderMaterialsId = TARGET.WorkOrderMaterialsId) -- TARGET.ItemMasterId = SOURCE.ItemMasterId AND TARGET.ConditionId = SOURCE.ConditionId) 
								--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
								WHEN MATCHED 				
									THEN UPDATE 						
									SET TARGET.QtyIssued = ISNULL(TARGET.QtyIssued, 0) + ISNULL(SOURCE.QuantityActReserved, 0),
										TARGET.UnitCost = ISNULL(SOURCE.UnitCost, 0),
										TARGET.ExtendedCost = ISNULL(TARGET.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0),
										TARGET.ExtendedPrice = ISNULL(TARGET.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0),
										TARGET.UpdatedDate = GETDATE(),
										TARGET.UpdatedBy = SOURCE.ReservedBy
								WHEN NOT MATCHED BY TARGET 
									THEN INSERT (StocklineId, WorkOrderMaterialsId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted) 
									VALUES (SOURCE.StocklineId, SOURCE.WorkOrderMaterialsId, SOURCE.ItemMasterId, SOURCE.ConditionId, SOURCE.ProvisionId, SOURCE.QuantityActReserved, 0, SOURCE.QuantityActReserved, SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), SOURCE.UnitCost, (ISNULL(SOURCE.Quantity, 0) * ISNULL(SOURCE.UnitCost, 0)), GETDATE(), SOURCE.ReservedBy, GETDATE(), SOURCE.ReservedBy, SOURCE.MasterCompanyId, 1, 0);
							END

							--PRINT '--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY'
							--FOR UPDATED WORKORDER MATERIALS STOCKLINE QTY
							UPDATE dbo.WorkOrderMaterialStockLine 
							SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0) 
							FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpReserveWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId 
							WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) 

							--FOR UPDATED WORKORDER MATERIALS QTY
							UPDATE dbo.WorkOrderMaterials 
							SET Quantity = GropWOM.Quantity	
							FROM(
								SELECT SUM(ISNULL(WOMS.Quantity,0)) AS Quantity, WOM.WorkOrderMaterialsId   
								FROM dbo.WorkOrderMaterials WOM 
								JOIN dbo.WorkOrderMaterialStockLine WOMS ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId 
								WHERE WOMS.IsActive = 1 AND WOMS.IsDeleted = 0
								GROUP BY WOM.WorkOrderMaterialsId
							) GropWOM WHERE GropWOM.WorkOrderMaterialsId = dbo.WorkOrderMaterials.WorkOrderMaterialsId AND ISNULL(GropWOM.Quantity,0) > ISNULL(dbo.WorkOrderMaterials.Quantity,0)			

							DECLARE @countKitStockline INT = 1;

							--FOR FOR UPDATED STOCKLINE QTY
							WHILE @countKitStockline <= @TotalCountsBoth
							BEGIN
								DECLARE @tmpKitStockLineId BIGINT = 0;

								SELECT @tmpKitStockLineId = StockLineId FROM #tmpReserveWOMaterialsStockline WHERE ID = @countKitStockline

								--FOR UPDATED STOCKLINE QTY
								UPDATE dbo.Stockline
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
									QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) - ISNULL(tmpRSL.QuantityActReserved,0),
									QuantityIssued = ISNULL(SL.QuantityIssued,0) + ISNULL(tmpRSL.QuantityActReserved,0),
									WorkOrderMaterialsId = tmpRSL.WorkOrderMaterialsId
								FROM dbo.Stockline SL JOIN #tmpReserveWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
								WHERE tmpRSL.ID = @countKitStockline AND Sl.StockLineId = @tmpKitStockLineId

								SET @countKitStockline = @countKitStockline + 1;
							END;

							--FOR UPDATE TOTAL WORK ORDER COST
							WHILE @count<= @TotalCounts
							BEGIN
								SELECT	@WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
								FROM #tmpReserveWOMaterialsStockline tmpWOM 
								WHERE tmpWOM.ID = @count

								EXEC [dbo].[USP_UpdateWOMaterialsCost]  @WorkOrderMaterialsId = @WorkOrderMaterialsId
						
								SET @count = @count + 1;
							END;

							--PRINT '--FOR STOCK LINE HISTORY'
							--FOR STOCK LINE HISTORY
							WHILE @slcount<= @TotalCounts
							BEGIN
								SELECT	@StocklineId = tmpWOM.StockLineId,
										@MasterCompanyId = tmpWOM.MasterCompanyId,
										@ReferenceId = tmpWOM.WorkOrderId,
										@SubReferenceId = tmpWOM.WorkOrderMaterialsId,
										@ReferencePartId=tmpWOM.WorkFlowWorkOrderId,
										@UpdateBy=UpdatedBy,
										@IssueQty=QuantityActReserved,
										@Amount=UnitCost,
										@ReferencePieceId=tmpWOM.WorkOrderMaterialsId
								FROM #tmpReserveWOMaterialsStockline tmpWOM 
								WHERE tmpWOM.ID = @slcount

								SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

								DECLARE @ActionId INT;
								SET @ActionId = (SELECT TOP 1 ActionId FROM [dbo].[StklineHistory_Action] WHERE [Type] = 'IssueReserve'); -- Added new action for Issue & Reserve

								EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

								-- batch trigger issue qty
								EXEC [dbo].[USP_BatchTriggerBasedonDistribution] 
								@DistributionMasterId,@ReferenceId,@ReferencePartId,@ReferencePieceId,@InvoiceId,@StocklineId,@IssueQty,@laborType,@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy

								SET @slcount = @slcount + 1;
							END;

							SELECT * FROM #tmpIgnoredStockline

							IF OBJECT_ID(N'tempdb..#tmpIgnoredStockline') IS NOT NULL
							BEGIN
								DROP TABLE #tmpIgnoredStockline
							END

							IF OBJECT_ID(N'tempdb..#tmpReserveWOMaterialsStockline') IS NOT NULL
							BEGIN
								DROP TABLE #tmpReserveWOMaterialsStockline
							END
						END
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
              , @AdhocComments     VARCHAR(150)    = 'USP_AutoReserveIssueWorkOrderMaterials' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END