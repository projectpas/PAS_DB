
/*************************************************************           
 ** File:   [GetRecevingCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Create Sub Work Order For Tender Stockline 
 ** Purpose:         
 ** Date:   04-Jan-2024        
          
 ** PARAMETERS:           
    @WorkOrderId BIGINT,
    @WorkOrderPartNoId BIGINT,
    @CreatedBy VARCHAR(100) 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04-Jan-2024   Hemant Saliya Created
     
 EXECUTE [CreateSubWorkOrderForTenderStockline] 4007, 3494, 'ADMIN User'
**************************************************************/ 

CREATE   PROCEDURE [dbo].[CreateSubWorkOrderForTenderStockline]
-- Add the parameters for the stored procedure here	
@WorkOrderId BIGINT,
@WorkOrderPartNoId BIGINT,
@CreatedBy VARCHAR(100)

AS
BEGIN
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		DECLARE @count INT = 1;
		DECLARE @TotalCounts INT;
		DECLARE @MasterCompanyId INT;
		DECLARE @WorkOrderTypeId INT;
		DECLARE @WorkFlowWorkOrderId BIGINT;
		DECLARE @SubWorkOrderNo VARCHAR(20);
		DECLARE @WorkOrderMaterialsId BIGINT;
		DECLARE @StockLineId BIGINT;
		DECLARE @SubWorkOrderStatusId INT;
		DECLARE @currentNo AS BIGINT = 0;  
		DECLARE @SubWOcurrentNo AS BIGINT = 0;
		DECLARE @CodeTypeId INT = 69; -- For SUB WO CODE TYPE
		DECLARE @SubWOProvisionID INT;
		DECLARE @SubWorkOrderId BIGINT;
		DECLARE @SubWorkOrderPartNoId BIGINT;
		DECLARE @SubWorkOrderModuleId INT = 24; -- FOR SUB WO MODULE
		DECLARE @ModuleId BIGINT;
		DECLARE @SubModuleId INT ;
		DECLARE @ReferenceId BIGINT;
		DECLARE @SubReferenceId BIGINT;
		DECLARE @ActionId INT = 0 ;

		SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 16; -- For SUB WORK ORDER Module
		SELECT @ActionId = ActionId FROM [DBO].[StklineHistory_Action] WHERE [Type] = 'Create-Sub-WorkOrder' -- For SUB WORK ORDER Cretae History

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

		IF OBJECT_ID(N'tempdb..#tmpWorkOrderMaterials') IS NOT NULL  
        BEGIN  
         DROP TABLE #tmpWorkOrderMaterials
        END  
         
        CREATE TABLE #tmpWorkOrderMaterials
        (  
          ID BIGINT NOT NULL IDENTITY,   
		  WorkOrderId BIGINT NULL,  
		  WorkOrderPartNumberId BIGINT NULL,  
		  WorkFlowWorkOrderId BIGINT NULL,  
          WorkOrderMaterialsId BIGINT NULL,  
		  WorkOrderMaterialStocklineId BIGINT NULL,  
          ItemMasterId BIGINT NULL,  
		  StocklineId BIGINT NULL,           
		  TaskId BIGINT NULL,  
		  ConditionId BIGINT NULL,  
		  ItemClassificationId BIGINT NULL,  
		  UnitOfMeasureId BIGINT NULL, 
		  Quantity INT NULL,
		  QuantityIssued INT NULL,  
		  QuantityReserved INT NULL,  
		  ProvisionId BIGINT NULL,  
          MaterialMandatoriesId INT NULL,  
          TotalStocklineQtyReq INT NULL,  
          QtyToTurnIn INT NULL,  
        )  

		SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
		SELECT @SubWorkOrderStatusId = SettingStatusId FROM dbo.WorkOrderSettings  WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId

		SELECT @SubWOProvisionID = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'SUB WORK ORDER'

		SELECT * INTO #WorkOrderSettings FROM dbo.WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND IsActive = 1 and IsDeleted = 0
		PRINT '1'
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN			
					SELECT @MasterCompanyId = WOP.MasterCompanyId, @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) 
					JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId
					WHERE ID = @WorkOrderPartNoId

					--GET ALL WOM TENDER STOCKLINE TO TO CREATE SUB WO
					INSERT INTO #tmpWorkOrderMaterials(WorkOrderId, WorkOrderPartNumberId, WorkFlowWorkOrderId, WorkOrderMaterialsId, WorkOrderMaterialStocklineId, ItemMasterId , StocklineId ,TaskId ,
							ConditionId ,ItemClassificationId ,UnitOfMeasureId, Quantity ,QuantityIssued ,QuantityReserved,	ProvisionId ,MaterialMandatoriesId,TotalStocklineQtyReq,QtyToTurnIn )
					SELECT WOM.WorkOrderId, @WorkOrderPartNoId, WorkFlowWorkOrderId, WOMS.WorkOrderMaterialsId, WOMS.WOMStockLineId, WOMS.ItemMasterId , StocklineId ,TaskId ,ConditionId ,
							ItemClassificationId ,UnitOfMeasureId, WOMS.Quantity ,QuantityIssued ,QuantityReserved,	WOMS.ProvisionId ,MaterialMandatoriesId,TotalStocklineQtyReq,QtyToTurnIn 
					FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
					WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId AND ISNULL(QtyToTurnIn, 0) > 0 AND WOMS.ProvisionId = @SubWOProvisionID

					SELECT @TotalCounts = MAX(ID) FROM #tmpWorkOrderMaterials;
					PRINT '2'
					--SELECT * FROM #tmpWorkOrderMaterials;

					--LOOP CREATE NO OF SUB WO BASED ON MATERIALS
					WHILE @count<= @TotalCounts
					BEGIN

						--SET CODE PREFIXES FOR SUB WO
						DELETE FROM #tmpCodePrefixes

						INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom) 
						SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
						FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
						WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
						
						PRINT '3'
						SELECT @currentNo = ISNULL(MAX(CurrentNummber), 0) FROM #tmpCodePrefixes
		
						IF (@currentNo <> 0)  
						BEGIN  
						 SET @SubWOcurrentNo = @currentNo + 1  
						END  
						ELSE  
						BEGIN  
						 SET @SubWOcurrentNo = 1  
						END 
						IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))  
						BEGIN   
							SET @SubWorkOrderNo = (SELECT * FROM dbo.[udfGenerateCodeNumber](@SubWOcurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))  
						END
						ELSE   
						BEGIN  
							ROLLBACK TRAN;  
						END  

						PRINT '4'
						--CREATE SUB WORK ORDER
						INSERT INTO dbo.SubWorkOrder(WorkOrderId, SubWorkOrderNo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted, WorkOrderPartNumberId,OpenDate,WorkOrderMaterialsId,StockLineId,SubWorkOrderStatusId)
						SELECT WorkOrderId, @SubWorkOrderNo, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(),1,0, @WorkOrderPartNoId, GETUTCDATE(), WorkOrderMaterialsId, StockLineId, @SubWorkOrderStatusId
						FROM #tmpWorkOrderMaterials WHERE ID = @count

						SET @SubWorkOrderId = SCOPE_IDENTITY(); 

						INSERT INTO SubWorkOrderPartNumber(WorkOrderId,SubWorkOrderId,ItemMasterId,SubWorkOrderScopeId,EstimatedShipDate,CustomerRequestDate,PromisedDate,EstimatedCompletionDate,NTE,Quantity,StockLineId,
								CMMId,WorkflowId,SubWorkOrderStageId,SubWorkOrderStatusId,SubWorkOrderPriorityId,IsPMA,IsDER,TechStationId,TATDaysStandard,TechnicianId,ConditionId,TATDaysCurrent,MasterCompanyId,CreatedBy,UpdatedBy,
								CreatedDate,UpdatedDate,IsActive,IsDeleted,IsClosed,PDFPath,islocked,IsFinishGood,RevisedConditionId,CustomerReference,RevisedItemmasterid,IsTraveler,IsManualForm,IsTransferredToParentWO)
						SELECT tmpWOM.WorkOrderId,@SubWorkOrderId, tmpWOM.ItemMasterId, Assy.WorkscopeId, EstimatedShipDate, CustomerRequestDate, PromisedDate, EstimatedCompletionDate, NTE, tmpWOM.Quantity, tmpWOM.StockLineId,
								CMMId, WorkflowId, WOS.DefaultStageCodeId, WOS.DefaultStatusId, WOP.WorkOrderPriorityId, IsPMA, IsDER, TechStationId, TATDaysStandard, TechnicianId, tmpWOM.ConditionId, TATDaysCurrent, WOP.MasterCompanyId, WOP.CreatedBy, WOP.UpdatedBy,
								GETUTCDATE(),GETUTCDATE(),1,0,0,NULL,0,0,tmpWOM.ConditionId,CustomerReference,tmpWOM.ItemMasterId,ISNULL(WOS.IsTraveler, 0),ISNULL(WOS.IsManualForm, 0), NULL 
						FROM #tmpWorkOrderMaterials tmpWOM 
							JOIN dbo.WorkOrderPartNumber WOP ON tmpWOM.WorkOrderPartNumberId = WOP.ID
							JOIN dbo.Assemply Assy ON tmpWOM.ItemMasterId = Assy.MappingItemMasterId AND WOP.ItemMasterId = Assy.ItemMasterId
							JOIN #WorkOrderSettings WOS ON WOP.MasterCompanyId = WOS.MasterCompanyId AND WOS.WorkOrderTypeId = @WorkOrderTypeId
						WHERE tmpWOM.ID = @count

						SET @SubWorkOrderPartNoId = SCOPE_IDENTITY();

						PRINT '5'

						DECLARE @SubWOPartQty INT = 0;

						SELECT @StocklineId = StocklineId, @SubWOPartQty = ISNULL(tmpWOM.Quantity, 0), @WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId FROM #tmpWorkOrderMaterials tmpWOM WHERE tmpWOM.ID = @count
						--UPDATE STOCKLINE QTY AND OTHER DETAILS
						UPDATE dbo.Stockline SET QuantityAvailable = QuantityAvailable - @SubWOPartQty, SubWorkOrderNumber = @SubWorkOrderNo, SubWorkOrderId = @SubWorkOrderId, SubWOPartNoId = @SubWorkOrderPartNoId
						WHERE StockLineId = @StocklineId

						--INSERT DATA IN SUB WORKORDER SETTLEMENT DETAILS
						INSERT INTO dbo.SubWorkOrderSettlementDetails(WorkOrderId, SubWOPartNoId, SubWorkOrderId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted, WorkOrderSettlementId)
						SELECT @WorkOrderId, @SubWorkOrderPartNoId, @SubWorkOrderId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, WOS.WorkOrderSettlementId 
						FROM WorkOrderSettlement WOS WITH(NOLOCK) 
						WHERE WOS.WorkOrderSettlementId NOT IN (5,10,11) --FOR EXCLUDE ADD SETTLEMENT DETAILS FOR ACT VS QUOTE, SHIPPING AND BILLING
						PRINT '6'

						--INSERT DATA IN SUB WORKORDER MATERIAL MAPPING
						IF((SELECT COUNT(1) FROM dbo.SubWorkOrderMaterialMapping WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId AND SubWorkOrderId = @SubWorkOrderId) = 0 )
						BEGIN
							INSERT INTO dbo.SubWorkOrderMaterialMapping(SubWorkOrderId,WorkOrderMaterialsId, MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted)
							SELECT @SubWorkOrderId, @WorkOrderMaterialsId, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0
						END

						PRINT '6.1'
						--CREATE CREATE TRAVELER LABOUR TASK FOR SUB WORKORDER IF IS TRAVELER TRUE
						IF((SELECT COUNT(1) FROM dbo.SubWorkOrderPartNumber WHERE SubWOPartNoId = @SubWorkOrderPartNoId AND SubWorkOrderId = @SubWorkOrderId AND IsTraveler = 1) > 0 )
						BEGIN
							--SELECT  @WorkOrderId,  @SubWorkOrderId,  @SubWorkOrderPartNoId,  @WorkOrderPartNoId ,  @MasterCompanyId,  @CreatedBy
							EXEC [dbo].[USP_CreateTravelerLabourTask_SubWorkorder] @WorkOrderId = @WorkOrderId, @SubWorkOrderId = @SubWorkOrderId, @SubWOPartNoId = @SubWorkOrderPartNoId, @WorkOrderPartId = @WorkOrderPartNoId , @MasterCompanyId = @MasterCompanyId, @CreatedBy = @CreatedBy
						END
						PRINT '7'
						
						--SELECT  @StocklineId,  @ModuleId,  @SubWorkOrderId,  @SubModuleId,  @SubReferenceId,  @ActionId,  0,  @CreatedBy;
						EXEC [dbo].[USP_AddUpdateStocklineHistory] @StocklineId = @StocklineId, @ModuleId = @ModuleId, @ReferenceId = @SubWorkOrderId, @SubModuleId = NULL, @SubRefferenceId = NULL, @ActionId = @ActionId, @Qty = 0, @UpdatedBy = @CreatedBy;

						PRINT '8'
						--UPDATE CODE PREFIX FROM SUB WO  
						UPDATE CodePrefixes SET CurrentNummber = @SubWOcurrentNo
						FROM dbo.CodePrefixes CP WITH(NOLOCK) 
						JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
						WHERE CT.CodeTypeId = @CodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;

						SET @count = @count + 1;
						PRINT '9'
					END
				END
				PRINT '10'
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
				BEGIN  
					DROP TABLE #tmpCodePrefixes 
				END	
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
					PRINT 'ROLLBACK'
                     ROLLBACK TRAN;
					-- SELECT
					--ERROR_NUMBER() AS ErrorNumber,
					--ERROR_STATE() AS ErrorState,
					--ERROR_SEVERITY() AS ErrorSeverity,
					--ERROR_PROCEDURE() AS ErrorProcedure,
					--ERROR_LINE() AS ErrorLine,
					--ERROR_MESSAGE() AS ErrorMessage;
					 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'CreateSubWorkOrderForTenderStockline' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
				  , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  	
END