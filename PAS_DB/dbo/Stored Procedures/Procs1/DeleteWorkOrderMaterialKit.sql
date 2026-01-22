
/*************************************************************   
** Author:  <Vishal Suthar>  
** Create date: <03/28/2023>  
** Description: <Delete Work Order Material KIT>  
  
EXEC [usp_ReserveWorkOrderMaterialsStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    03/28/2023  Vishal Suthar   Created
** 2    16/10/2024  RAJESH GAMI      Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials
** 3    29/10/2024  RAJESH GAMI      Un Mapped WO if there is no other material link with the same workorder in the Same PO (Updated)
exec dbo.[DeleteWorkOrderMaterialKit] 17
**************************************************************/ 
CREATE   PROCEDURE [dbo].[DeleteWorkOrderMaterialKit]
	@KitId BIGINT,
	@WOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					DECLARE @WorkOrderId BIGINT = 0;
					DECLARE @PoID BIGINT = 0, @LooPId INT = 1, @TotalCount INT = 0
					IF OBJECT_ID(N'tempdb..##TempTableWOM') IS NOT NULL
					BEGIN
						DROP TABLE #TempTableWOM
					END
					IF OBJECT_ID(N'tempdb..##TempPOtbl') IS NOT NULL
					BEGIN
						DROP TABLE #TempPOtbl
					END
					CREATE TABLE #TempPOtbl(Id [int] IDENTITY(1,1),POID BIGINT NULL)
					CREATE TABLE #TempTableWOM(WorkOrderMaterialsKitMappingId BIGINT)
					INSERT INTO #TempTableWOM (WorkOrderMaterialsKitMappingId)
					SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId


					IF OBJECT_ID(N'tempdb..##TempWOtblM') IS NOT NULL
					BEGIN
						DROP TABLE #TempWOtblM
					END

					CREATE TABLE #TempWOtblM(WorkOrderMaterialsKitId BIGINT)
					INSERT INTO #TempWOtblM (WorkOrderMaterialsKitId)
					SELECT DISTINCT WOM.WorkOrderMaterialsKitId
					FROM dbo.[WorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #TempTableWOM tmp ON WOM.WorkOrderMaterialsKitMappingId = tmp.WorkOrderMaterialsKitMappingId
					WHERE WOM.WorkOrderMaterialsKitMappingId = tmp.WorkOrderMaterialsKitMappingId

					SET @WorkOrderId = (SELECT TOP 1 WorkOrderId FROM dbo.[WorkOrderMaterialsKit] WOM WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = (SELECT top 1 WorkOrderMaterialsKitId FROM #TempWOtblM))
					INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.[WorkOrderMaterialsKit] WOM WITH(NOLOCK) WHERE WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsKitId FROM  #TempWOtblM) AND ISNULL(POId,0) > 0

					UPDATE P    
				    SET WorkOrderMaterialsId = NULL, 
					       IsKit = NULL, IsSubWO =NULL, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtblM tmp ON P.WorkOrderMaterialsId = tmp.WorkOrderMaterialsKitId
					  WHERE P.WorkOrderMaterialsId  = tmp.WorkOrderMaterialsKitId AND ISNULL(IsKit,0) = 1 AND ISNULL(IsSubWO,0) = 0

					/****** Unmapped the Workorder if there is no other material link with the same workorder in the PurchaseOrder Part ********/
					SET @TotalCount = (SELECT COUNT(1) FROM #TempPOtbl)
					IF(@TotalCount>0)
					BEGIN
						WHILE @LooPId <= @TotalCount
						BEGIN
								SELECT @PoID FROM #TempPOtbl WHERE Id = @LooPId
								IF((SELECT COUNT(1) FROM dbo.PurchaseOrderPart WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId AND PurchaseOrderId = @PoID) = 1)
								BEGIN
									UPDATE P    
										SET	   WorkOrderId = NULL, WorkOrderNo = NULL,
											   WorkOrderMaterialsId = NULL, 
											   IsKit = NULL, IsSubWO =NULL, 
											   UpdatedDate = GETUTCDATE()
										FROM DBO.PurchaseOrderPart P WHERE P.WorkOrderId = @WorkOrderId AND PurchaseOrderId = @PoID
										DELETE FROM dbo.PurchaseOrderPartReference WHERE ModuleId = 1 AND ReferenceId = @WorkOrderId AND PurchaseOrderId = @PoID
								END
								SET @LooPId +=1 
						END
					END
					

					DELETE FROM [dbo].[WorkOrderMaterialStockLineKit] WHERE WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsKitId FROM [DBO].[WorkOrderMaterialsKit] WHERE WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId));
					DELETE FROM [DBO].[WorkOrderMaterialsKit] WHERE WorkOrderMaterialsKitMappingId IN (SELECT WorkOrderMaterialsKitMappingId FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId);
					DELETE FROM [DBO].[WorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND WOPartNoId = @WOPartNoId;
				END

			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWorkOrderMaterialKit' 
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