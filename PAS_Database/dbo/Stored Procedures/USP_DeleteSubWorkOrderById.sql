/*************************************************************           
 ** File:   [USP_DeleteSubWorkOrderById]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used TO DELETE Sub WorkOrder BY ID
 ** Purpose:         
 ** Date:   12/26/2023      
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    12/26/2023   Devendra Shekh			Created
    2    01/05/2024   Devendra Shekh			Created
     
exec [USP_DeleteSubWorkOrderById] 

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_DeleteSubWorkOrderById]
@SubWorkOrderId BIGINT = NULL,
@UserName VARCHAR(100) = NULL
AS
BEGIN	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	BEGIN TRANSACTION
		
	IF(ISNULL(@SubWorkOrderId, 0) > 0)
	BEGIN
		
		DECLARE @LaborHeaderId BIGINT = 0,
		@SWOStockLineId BIGINT = 0,
		@SWOQty BIGINT = 0,
		@StockLineId BIGINT = 0,
		@WorkOrderMaterialId BIGINT = 0,
		@AttachMentModuleId BIGINT = 0,
		@AttachMentIdS VARCHAR(150) = '',
		@ModuleId BIGINT = 0,
		@TotalPart BIGINT = 0,
		@StartCount BIGINT = 1,
		@TempSubWOPartId BIGINT = 0;

		IF OBJECT_ID('tempdb..#tempSubWOPart') IS NOT NULL
			DROP TABLE #tempSubWOPart

		CREATE TABLE #tempSubWOPart
		(
			ID INT IDENTITY(1,1) NOT NULL,
			SubWorkOrderId BIGINT NULL,
			SubWOPartNoId BIGINT NULL,
		)

		INSERT INTO #tempSubWOPart(SubWorkOrderId, SubWOPartNoId)
		SELECT SubWorkOrderId, SubWOPartNoId FROM [dbo].[SubWorkOrderPartNumber] WHERE [SubWorkOrderId] = @SubWorkOrderId;

		SET @TotalPart = (SELECT COUNT(ID) FROM #tempSubWOPart);

		WHILE(@StartCount <= @TotalPart)
		BEGIN

			SET @TempSubWOPartId = (SELECT SubWOPartNoId FROM #tempSubWOPart WHERE [ID] = @StartCount);
			
			SET @AttachMentModuleId = (SELECT AttachmentModuleId FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE UPPER([Name]) = 'SUBWORKORDER')
			SET @ModuleId = (SELECT ModuleId FROM [DBO].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'SUBWORKORDER')

			SELECT @AttachMentIdS = STUFF ((SELECT ',' + CAST(P.AttachmentId AS VARCHAR) FROM dbo.[Attachment] AS P    
						WHERE P.ReferenceId = @SubWorkOrderId AND [ModuleId] = @AttachMentModuleId
						FOR XML PATH('') ) ,1,1,'') 

			SET @LaborHeaderId = (SELECT [SubWorkOrderLaborHeaderId] FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId);
			SELECT @SWOStockLineId = [StockLineId], @WorkOrderMaterialId = [WorkOrderMaterialsId] FROM [dbo].[SubWorkOrder] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId;
			SELECT @SWOQty = SUM(ISNULL(Quantity, 0)) FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			--DELETE FROM [dbo].[WorkOrderMaterialStockLine] WHERE [StockLineId] = @SWOStockLineId AND [WorkOrderMaterialsId] = @WorkOrderMaterialId
			

			DELETE FROM [dbo].[SubWorkOrderAssetAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderAsset] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderChargesAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderCharges] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderFreightAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderFreight] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			DELETE FROM [dbo].[SubWorkOrderLaborAudit] WHERE [SubWorkOrderLaborHeaderId] = @LaborHeaderId
			DELETE FROM [dbo].[SubWorkOrderLabor] WHERE [SubWorkOrderLaborHeaderId] = @LaborHeaderId
			DELETE FROM [dbo].[SubWorkOrderLaborHeaderAudit] WHERE [SubWorkOrderLaborHeaderId] = @LaborHeaderId
			DELETE FROM [dbo].[SubWorkOrderLaborHeader] WHERE [SubWorkOrderLaborHeaderId] = @LaborHeaderId

			DELETE FROM [dbo].[SubWorkOrderTeardownAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderTeardown] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderSettlementDetailsAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderSettlementDetails] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			--UPDATE [dbo].[WorkOrderMaterials]
			--SET Quantity = Quantity - ISNULL(@SWOQty, 0), [UpdatedDate] = GETUTCDATE()
			--WHERE [WorkOrderMaterialsId] = @WorkOrderMaterialId 
		
			UPDATE [dbo].[Stockline]
			SET QuantityAvailable = QuantityAvailable + ISNULL(@SWOQty, 0), [UpdatedDate] = GETUTCDATE()
			WHERE [StockLineId] = @SWOStockLineId;
		
			DELETE FROM [dbo].[SubWorkOrderMPNCostDetailAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId; 
			DELETE FROM [dbo].[SubWorkOrderMPNCostDetail] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			DELETE FROM [dbo].[SubWorkOrderCostDetailsAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderCostDetails] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			DELETE FROM [dbo].[SubWorkOrderPartNumberAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;
			DELETE FROM [dbo].[SubWorkOrderPartNumber] WHERE [SubWorkOrderId] = @SubWorkOrderId AND SubWOPartNoId = @TempSubWOPartId;

			SET @StartCount = @StartCount + 1
		END

			DELETE FROM [dbo].[SubWorkOrderMaterialMapping] WHERE [SubWorkOrderId] = @SubWorkOrderId AND [WorkOrderMaterialsId] = @WorkOrderMaterialId

			--DOCUMENTS DELETE
			DELETE FROM [dbo].[AttachmentDetailsAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[AttachmentDetails] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[CommonDocumentDetailsAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[CommonDocumentDetails] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[AttachmentAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[Attachment] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))

			--DELETE COMMUNICATION
			DELETE FROM [dbo].[MemoAudit] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
			DELETE FROM [dbo].[Memo] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId		

			SELECT @AttachMentIdS = STUFF ((SELECT ',' + CAST(P.AttachmentId AS VARCHAR) FROM dbo.[Email] AS P    
					WHERE P.ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
					FOR XML PATH('') ) ,1,1,'') 
			--EMAIL DOCUMENTS DELETE
			DELETE FROM [dbo].[AttachmentDetailsAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[AttachmentDetails] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[CommonDocumentDetailsAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[CommonDocumentDetails] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[AttachmentAudit] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))
			DELETE FROM [dbo].[Attachment] WHERE [AttachmentId] IN (SELECT value FROM STRING_SPLIT(@AttachMentIdS, ','))

			DELETE FROM [dbo].[EmailAudit] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
			DELETE FROM [dbo].[Email] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId

			DELETE FROM [dbo].[CommunicationTextAudit] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
			DELETE FROM [dbo].[CommunicationText] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
			DELETE FROM [dbo].[CommunicationPhoneAudit] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId
			DELETE FROM [dbo].[CommunicationPhone] WHERE ReferenceId = @SubWorkOrderId AND [ModuleId] = @ModuleId

			DELETE FROM [dbo].[SubWorkOrderAudit] WHERE [SubWorkOrderId] = @SubWorkOrderId   
			DELETE FROM [dbo].[SubWorkOrder] WHERE [SubWorkOrderId] = @SubWorkOrderId  

		
		--UPDATE [dbo].[SubWorkOrder]
		--SET [IsDeleted] = 1, [UpdatedBy] = @UserName, [UpdatedDate] = GETUTCDATE()
		--WHERE [SubWorkOrderId] = @SubWorkOrderId

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			 ROLLBACK TRAN;
	         DECLARE @ErrorLogID INT
			 
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_DeleteSubWorkOrderById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SubWorkOrderId, '') AS VARCHAR(100))
			   		                                           
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END