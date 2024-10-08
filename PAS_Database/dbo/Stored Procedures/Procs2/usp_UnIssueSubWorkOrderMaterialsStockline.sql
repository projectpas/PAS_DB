
/*************************************************************   
** Author:  <Hemant Saliya>  
** Create date: <02/07/2022>  
** Description: <Save Sub Work Order Materials Issue Stockline Details>  
  
EXEC [usp_UnIssueSubWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    02/07/2022  HEMANT SALIYA    Save Sub Work Order Materials Issued Stockline Details
** 2    07/18/2023  VISHAL SUTHAR    Added new stockline history
** 3    12/20/2023  HEMANT SALIYA    Added KIT in SWO Issue
** 4    10/08/2024  RAJESH GAMI 	 Implement the ReferenceNumber column data into SubWOMaterial | Kit Stockline table.

declare @p1 dbo.SubWOMaterialsStocklineType
insert into @p1 values(3801,187,161,79,161326,20751,7,1,10,2,N'NE',N'PART9',N'A COCKPIT OR FLIGHT DECK IS THE AREA, USUALLY NEAR THE FRONT OF AN AIRCRAFT OR SPACECRAFT, FROM WHICH A PILOT CONTROLS THE AIRCRAFT. THE COCKPIT OF AN AIRCRAFT CONTAINS FLIGHT INSTRUMENTS ON AN INSTRUMENT PANEL, AND THE CONTROLS THAT ENABLE THE PILOT TO FLY THE AIRCRAFT',1,0,0,0,0,1,N'CNTL-001540',N'ID_NUM-000010',N'STL000004',N'',N'ADMIN User',1,0,0,0,0,0)

exec dbo.usp_UnIssueSubWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_UnIssueSubWorkOrderMaterialsStockline]
	@tbl_MaterialsStocklineType SubWOMaterialsStocklineType READONLY
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					--CASE 1 UPDATE WORK ORDER MATERILS
					DECLARE @count INT;
					DECLARE @countKIT INT;
					DECLARE @slcount INT;
					DECLARE @TotalCounts INT;
					DECLARE @TotalCountsKIT INT;
					DECLARE @TotalCountsBoth INT;
					DECLARE @StocklineId BIGINT; 
					DECLARE @MasterCompanyId INT; 
					DECLARE @ModuleId INT;
					DECLARE @ReferenceId BIGINT;
					DECLARE @IsAddUpdate BIT; 
					DECLARE @ExecuteParentChild BIT; 
					DECLARE @UpdateQuantities BIT;
					DECLARE @IsOHUpdated BIT; 
					DECLARE @AddHistoryForNonSerialized BIT; 
					DECLARE @SubModuleId INT;
					DECLARE @SubReferenceId BIGINT;
					DECLARE @PartStatus INT;
					DECLARE @SubWorkOrderMaterialsId BIGINT;
					DECLARE @IsSerialised BIT;
					DECLARE @stockLineQty INT;
					DECLARE @stockLineQtyAvailable INT;
					DECLARE @UpdateBy varchar(200);
					DECLARE @IssueQty bigint = 0;
					DECLARE @WOTypeId INT= 0;
					DECLARE @laborType varchar(200)='WOP-PartsIssued';
                    DECLARE @issued bit=0;
                    DECLARE @Amount decimal(18,2);
                    DECLARE @ModuleName varchar(200)='WOP-PartsIssued';
					DECLARE @IsKit BIGINT = 0;
					DECLARE @DistributionMasterId BIGINT = 0;
					DECLARE @ReferencePartId BIGINT = 0;
					DECLARE @CustomerWOTypeId INT= 0;
					DECLARE @InternalWOTypeId INT= 0;

					DECLARE @HistorySubWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT,
								@historySubWorkOrderId BIGINT,@HistoryQtyReserved VARCHAR(MAX),@HistoryQuantityActReserved VARCHAR(MAX),@historyReservedById BIGINT,
								@historyEmployeeName VARCHAR(100),@historyMasterCompanyId BIGINT,@historytotalReserved VARCHAR(MAX),@TemplateBody NVARCHAR(MAX),
								@SubWorkOrderNum VARCHAR(MAX),@ConditionId BIGINT,@ConditionCode VARCHAR(MAX),@HistoryStockLineId BIGINT,@HistoryStockLineNum VARCHAR(MAX),
								@SubWorkOrderPartNoId BIGINT,@historyQuantity BIGINT,@historyQtyToBeReserved BIGINT, @KITID BIGINT,
								@ItemMasterId BIGINT,@Partnumber VARCHAR(200),@MPNPartnumber VARCHAR(200),@historyQuantityActIssued BIGINT
								,@OldValue VARCHAR(MAX)='' ,@NewValue VARCHAR(MAX) ='' 
					DECLARE @MaterialRefNo VARCHAR(100) = 'UnIssue', @SubWONumber VARCHAR(100);

					SELECT @SubWONumber=SubWorkOrderNo from dbo.SubWorkOrder WO WITH(NOLOCK) WHERE SubWorkOrderId = (SELECT TOP 1 SubWorkOrderId FROM @tbl_MaterialsStocklineType)
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
					SELECT @SubModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE [ModuleName] = 'SubWorkOrderMaterials'; -- For WORK ORDER Materials Module
					SELECT @DistributionMasterId =ID from DistributionMaster WITH(NOLOCK)  where UPPER(DistributionCode)= UPPER('WOMATERIALGRIDTAB')
					SELECT TOP 1 @CustomerWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Customer'
					SELECT TOP 1 @InternalWOTypeId =Id FROM dbo.WorkOrderType WITH (NOLOCK) WHERE [Description] = 'Internal'

					SET @PartStatus = 4; -- FOR Un-Issue
					SET @IsAddUpdate = 0;
					SET @ExecuteParentChild = 1;
					SET @UpdateQuantities = 1;
					SET @IsOHUpdated = 0;
					SET @AddHistoryForNonSerialized = 0;					
					SET @slcount = 1;
					SET @count = 1;
					SET @countKIT = 1;

					IF OBJECT_ID(N'tempdb..#tmpUnIssueWOMaterialsStockline') IS NOT NULL
					BEGIN
						DROP TABLE #tmpUnIssueWOMaterialsStockline
					END
			
					CREATE TABLE #tmpUnIssueWOMaterialsStockline
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[SubWorkOrderId] BIGINT NULL,
						[SubWOPartNoId] BIGINT NULL,
						[SubWorkOrderMaterialsId] BIGINT NULL,
						[StockLineId] BIGINT NULL,
						[ItemMasterId] BIGINT NULL,
						[ConditionId] BIGINT NULL,
						[ProvisionId] BIGINT NULL,
						[TaskId] BIGINT NULL,								 
						[Condition] VARCHAR(500) NULL,
						[PartNumber] VARCHAR(500) NULL,
						[PartDescription] VARCHAR(max) NULL,
						[Quantity] INT NULL,
						[QtyToBeReserved] INT NULL,
						[QuantityActUnIssued] INT NULL,
						[ControlNo] VARCHAR(500) NULL,
						[ControlId] VARCHAR(500) NULL,
						[StockLineNumber] VARCHAR(500) NULL,
						[SerialNumber] VARCHAR(500) NULL,
						[ReservedBy] VARCHAR(500) NULL,						 
						[IsStocklineAdded] BIT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(500) NULL,
						[UpdatedById] BIGINT NULL,
						[UnitCost] DECIMAL(18,2),
						[IsSerialized] BIT,
						[KitId] BIGINT NULL
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

					--SELECT * FROM @tbl_MaterialsStocklineType

					INSERT INTO #tmpUnIssueWOMaterialsStockline ([WorkOrderId],[SubWorkOrderId], [SubWOPartNoId], [SubWorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UpdatedById],  [UnitCost], [IsSerialized],[KitId])
					SELECT tblMS.[WorkOrderId],tblMS.[SubWorkOrderId],tblMS.[SubWOPartNoId], tblMS.[SubWorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], [ProvisionId], 
						[TaskId], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActUnIssued], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], [ReservedById], SL.UnitCost, SL.isSerialized, tblMS.[KitId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityIssued > 0 AND SL.QuantityIssued >= tblMS.QuantityActUnIssued

					SELECT @TotalCounts = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) = 0;
					SELECT @TotalCountsKIT = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline WHERE ISNULL(KitId, 0) > 0;
					SELECT @TotalCountsBoth = COUNT(ID) FROM #tmpUnIssueWOMaterialsStockline;

					INSERT INTO #tmpIgnoredStockline ([PartNumber], [Condition], [ControlNo], [ControlId], [StockLineNumber]) 
					SELECT tblMS.[PartNumber], tblMS.[Condition], tblMS.[ControlNo], tblMS.[ControlId], tblMS.[StockLineNumber] FROM @tbl_MaterialsStocklineType tblMS  
					WHERE tblMS.StockLineId NOT IN (SELECT StockLineId FROM #tmpUnIssueWOMaterialsStockline)

					--Select * from #tmpUnIssueWOMaterialsStockline
		
					--UPDATE SUB WORK ORDER MATERIALS KIT DETAILS
					WHILE @countKIT <= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterialsKit 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETUTCDATE(), 
								UpdatedDate = GETUTCDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterialsKit WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsKitId AND tmpWOM.ID = @countKIT 
						WHERE ISNULL(tmpWOM.KitId, 0) > 0
						SET @countKIT = @countKIT + 1;
					END;

					--UPDATE SUB WORK ORDER MATERIALS STOCKLINE DETAILS
					IF (@TotalCountsBoth > 0)
					BEGIN
						UPDATE dbo.SubWorkOrderMaterialStockLineKit 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETUTCDATE(),
							UpdatedBy = ReservedBy,ReferenceNumber = @MaterialRefNo + ' - '+@SubWONumber
						FROM dbo.SubWorkOrderMaterialStockLineKit WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
						WHERE ISNULL(tmpRSL.KitId, 0) > 0
					END

					--FOR UPDATED SUB WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLineKit 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo + ' - '+@SubWONumber 
					FROM dbo.SubWorkOrderMaterialStockLineKit WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) > 0
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0),						
						WorkOrderMaterialsKitId = tmpRSL.SubWorkOrderMaterialsId
					FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) > 0

					--UPDATE SUB WORK ORDER MATERIALS DETAILS
					WHILE @count<= @TotalCountsBoth
					BEGIN
						UPDATE SubWorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								QuantityReserved = ISNULL(WOM.QuantityReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) - ISNULL(tmpWOM.QuantityActUnIssued,0),
								TotalReserved = ISNULL(WOM.TotalReserved,0) + ISNULL(tmpWOM.QuantityActUnIssued,0),
								IssuedById = tmpWOM.UpdatedById, 
								IssuedDate = GETDATE(), 
								UpdatedDate = GETDATE(),
								PartStatusId = @PartStatus
						FROM dbo.SubWorkOrderMaterials WOM JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count AND ISNULL(tmpWOM.KitId, 0) = 0
						SET @count = @count + 1;
					END;
					
					--UPDATE SUB WORK ORDER MATERIALS STOCKLINE DETAILS
					IF(@TotalCountsBoth > 0 )
					BEGIN
						UPDATE dbo.SubWorkOrderMaterialStockLine 
						SET QtyIssued = ISNULL(QtyIssued, 0) - ISNULL(QuantityActUnIssued, 0),
							QtyReserved = ISNULL(QtyReserved, 0) + ISNULL(QuantityActUnIssued, 0),
							ExtendedCost = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							ExtendedPrice = ISNULL(WOMS.Quantity, 0) * WOMS.UnitCost,
							UpdatedDate = GETDATE(),
							UpdatedBy = ReservedBy,ReferenceNumber = @MaterialRefNo + ' - '+@SubWONumber
						FROM dbo.SubWorkOrderMaterialStockLine WOMS 
						JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId AND ISNULL(tmpRSL.KitId, 0) = 0
					END

					--FOR UPDATE SUB WORKORDER MATERIALS STOCKLINE QTY
					UPDATE dbo.SubWorkOrderMaterialStockLine 
					SET Quantity = ISNULL(QtyReserved, 0) + ISNULL(QtyIssued, 0),ReferenceNumber = @MaterialRefNo + ' - '+@SubWONumber 
					FROM dbo.SubWorkOrderMaterialStockLine WOMS JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON WOMS.StockLineId = tmpRSL.StockLineId AND WOMS.SubWorkOrderMaterialsId = tmpRSL.SubWorkOrderMaterialsId 
					WHERE (ISNULL(WOMS.QtyReserved, 0) + ISNULL(WOMS.QtyIssued, 0)) > ISNULL(WOMS.Quantity, 0) AND ISNULL(tmpRSL.KitId, 0) = 0 
					
					--FOR UPDATED STOCKLINE QTY
					UPDATE dbo.Stockline
					SET QuantityOnHand = ISNULL(SL.QuantityOnHand, 0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
						QuantityReserved = ISNULL(SL.QuantityReserved,0) + ISNULL(tmpRSL.QuantityActUnIssued,0),
                        QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpRSL.QuantityActUnIssued,0)
					FROM dbo.Stockline SL JOIN #tmpUnIssueWOMaterialsStockline tmpRSL ON SL.StockLineId = tmpRSL.StockLineId
					WHERE ISNULL(tmpRSL.KitId, 0) = 0
					
					DECLARE @countBoth INT = 1;

					--FOR UPDATE TOTAL SUB WORK ORDER COST
					WHILE @countBoth <= @TotalCountsBoth
					BEGIN
						SELECT	@SubWorkOrderMaterialsId = tmpWOM.SubWorkOrderMaterialsId
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @count

						EXEC [dbo].[USP_UpdateSubWOMaterialsCost]  @SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
						
						SET @countBoth = @countBoth + 1;
					END;

					--FOR STOCK LINE HISTORY	
					WHILE @slcount<= @TotalCounts
					BEGIN
						SELECT	@StocklineId = tmpWOM.StockLineId,
								@MasterCompanyId = tmpWOM.MasterCompanyId,
								@ReferenceId = tmpWOM.SubWorkOrderId,
								@SubReferenceId = tmpWOM.SubWorkOrderMaterialsId,
								@UpdateBy = UpdatedBy,
								@IssueQty = QuantityActUnIssued
						FROM #tmpUnIssueWOMaterialsStockline tmpWOM 
						WHERE tmpWOM.ID = @slcount

						SELECT @IsSerialised = isSerialized, @stockLineQtyAvailable = QuantityAvailable, @stockLineQty = Quantity FROM DBO.Stockline WITH (NOLOCK) Where StockLineId = @StocklineId

						DECLARE @ActionId INT;
						SET @ActionId = 5; -- UnIssue
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @ReferenceId, @SubModuleId = @SubModuleId, @SubRefferenceId = @SubReferenceId, @ActionId = @ActionId, @Qty = @IssueQty, @UpdatedBy = @UpdateBy;

						--Added for WO History 
						SELECT @historyModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrder';
						SELECT @historySubModuleId = moduleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleName = 'SubWorkOrderMPN';
						SELECT @TemplateBody = TemplateBody FROM HistoryTemplate WITH(NOLOCK) WHERE TemplateCode = 'UnIssuedParts';
						SELECT @HistorySubWorkOrderMaterialsId = SubWorkOrderMaterialsId,
							   @historyMasterCompanyId = MasterCompanyId,@ConditionId = ConditionId,@HistoryStockLineId = StockLineId,
							   @historyQuantity = Quantity,@historyQtyToBeReserved = QtyToBeReserved, @KITID = ISNULL(KitId,0),
							   @Partnumber = PartNumber,@historyQuantityActIssued = QuantityActUnIssued 
						FROM #tmpUnIssueWOMaterialsStockline WHERE ID = @slcount;

						SELECT @SubWorkOrderPartNoId = SubWOPartNoId, @historySubWorkOrderId = SubWorkOrderId FROM dbo.SubWorkOrderMaterials WITH(NOLOCK) WHERE SubWorkOrderMaterialsId = @HistorySubWorkOrderMaterialsId;
						SELECT @ItemMasterId = SWOP.ItemMasterId, @MPNPartnumber = IM.partnumber FROM dbo.SubWorkOrderPartNumber AS SWOP WITH(NOLOCK)
							JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = SWOP.ItemMasterId
						 WHERE SubWOPartNoId = @SubWorkOrderPartNoId;
						
						SELECT @SubWorkOrderNum = SubWorkOrderNo FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @historysUBWorkOrderId;
						SELECT @ConditionCode = Code FROM dbo.Condition WITH(NOLOCK) WHERE ConditionId = @ConditionId;
						SELECT @HistoryStockLineNum = StockLineNumber FROM dbo.Stockline WITH(NOLOCK) WHERE StockLineId = @HistoryStockLineId;

						SELECT @historyEmployeeName = (FirstName +' '+ LastName) FROM dbo.Employee WITH(NOLOCK) WHERE EmployeeId = @historyReservedById;
						SELECT @HistoryQtyReserved = CAST(QuantityReserved AS VARCHAR) FROM dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) JOIN #tmpUnIssueWOMaterialsStockline tmpWOM ON tmpWOM.SubWorkOrderMaterialsId = WOM.SubWorkOrderMaterialsId AND tmpWOM.ID = @count;

						SET @historytotalReserved = (CAST(@HistoryQtyReserved AS BIGINT) + CAST(@HistoryQuantityActReserved AS BIGINT));

						SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@Partnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@MPNPartnumber,''));
						SET @TemplateBody = REPLACE(@TemplateBody, '##Qty##', ISNULL(@historyQuantityActIssued,0));

						SET @OldValue= '';
						SET @NewValue= 'UN-ISSUED PARTS';

						IF @KITID = 0
						BEGIN
							EXEC [dbo].[USP_History] @historyModuleId,@historySubWorkOrderId,@historySubModuleId,@SubWorkOrderPartNoId,@OldValue,@NewValue,@TemplateBody,'UnIssuedParts',@historyMasterCompanyId,@UpdateBy,NULL,@UpdateBy,NULL;
						END

						-- Sub Work Order Accounting Batch Entry --
						IF(ISNULL(@WOTypeId,0) = @CustomerWOTypeId)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId = @DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForSubWorkOrder] @DistributionMasterId,@ReferenceId,@ReferencePartId,@SubReferenceId,0,@StocklineId,@IssueQty,'',@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
						END

						IF(ISNULL(@WOTypeId,0) = @InternalWOTypeId)
						BEGIN
							IF NOT EXISTS(SELECT 1 FROM dbo.DistributionSetup WITH(NOLOCK) WHERE DistributionMasterId =@DistributionMasterId AND MasterCompanyId=@MasterCompanyId AND ISNULL(GlAccountId,0) = 0)
							BEGIN
								EXEC [dbo].[USP_BatchTriggerBasedonDistributionForInternalSubWorkOrder] @DistributionMasterId,@ReferenceId,@ReferencePartId,@SubReferenceId,0,@StocklineId,@IssueQty,'',@issued,@Amount,@ModuleName,@MasterCompanyId,@UpdateBy
							END
						END

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

			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_UnIssueSubWorkOrderMaterialsStockline' 
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