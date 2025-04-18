
/*************************************************************   
** Author:  <Devendra Shekh>  
** Create date: <12/12/2023>  
** Description: <Delete Sub Work Order Material KIT>  
  
EXEC [DeleteSubWorkOrderMaterialKit] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author				Change Description  
** --   --------		-------				--------------------------------
** 1    12/12/2023	 Devendra Shekh			Created
** 2    16/10/2024  RAJESH GAMI      Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials
** 3    29/10/2024  RAJESH GAMI      Un Mapped WO if there is no other material link with the same workorder in the Same PO (Updated)
** 4    14/04/2025  AMIT GHEDIYA     DELETE WOM KIT FOR NO STOCKLINE EXIST

exec dbo.[DeleteSubWorkOrderMaterialKit] 17
**************************************************************/ 
CREATE   PROCEDURE [dbo].[DeleteSubWorkOrderMaterialKit]
	@KitId BIGINT,
	@SubWOPartNoId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
				DECLARE @SubWorkOrderId BIGINT = 0;
				DECLARE @PoID BIGINT = 0, @LooPId INT = 1, @TotalCount INT = 0
				IF OBJECT_ID(N'tempdb..##TempTableWOM') IS NOT NULL
					BEGIN
						DROP TABLE #TempTableWOM
					END
					CREATE TABLE #TempTableWOM(SubWorkOrderMaterialsKitMappingId BIGINT)
					INSERT INTO #TempTableWOM (SubWorkOrderMaterialsKitMappingId)
					SELECT SubWorkOrderMaterialsKitMappingId FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId
					
					IF OBJECT_ID(N'tempdb..##TempWOtblM') IS NOT NULL
					BEGIN
						DROP TABLE #TempWOtblM
					END
					IF OBJECT_ID(N'tempdb..##TempPOtbl') IS NOT NULL
					BEGIN
						DROP TABLE #TempPOtbl
					END
					CREATE TABLE #TempPOtbl(Id [int] IDENTITY(1,1),POID BIGINT NULL)
					CREATE TABLE #TempWOtblM(SubWorkOrderMaterialsKitId BIGINT)
					INSERT INTO #TempWOtblM (SubWorkOrderMaterialsKitId)
					SELECT DISTINCT WOM.SubWorkOrderMaterialsKitId
					FROM dbo.[SubWorkOrderMaterialsKit] WOM WITH(NOLOCK) INNER JOIN #TempTableWOM tmp ON WOM.SubWorkOrderMaterialsKitMappingId = tmp.SubWorkOrderMaterialsKitMappingId
					WHERE WOM.SubWorkOrderMaterialsKitMappingId = tmp.SubWorkOrderMaterialsKitMappingId
					
					SET @SubWorkOrderId = (SELECT TOP 1 SubWorkOrderId FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK) WHERE SubWorkOrderMaterialsKitId = (SELECT top 1 SubWorkOrderMaterialsKitId FROM #TempWOtblM))
					INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK) WHERE SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsKitId FROM  #TempWOtblM) AND ISNULL(POId,0) > 0
					UPDATE P    
				    SET WorkOrderMaterialsId = 0, 
					       IsKit = 0, IsSubWO =0, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtblM tmp ON P.WorkOrderMaterialsId = tmp.SubWorkOrderMaterialsKitId
					  WHERE P.WorkOrderMaterialsId  = tmp.SubWorkOrderMaterialsKitId AND ISNULL(IsKit,0) = 1 AND ISNULL(IsSubWO,0) = 1

					/****** Unmapped the SubWorkorder if there is no other material link with the same sub workorder in the PurchaseOrder Part ********/
					SET @TotalCount = (SELECT COUNT(1) FROM #TempPOtbl)
					IF(@TotalCount>0)
					BEGIN
						WHILE @LooPId <= @TotalCount
						BEGIN
								SELECT @PoID FROM #TempPOtbl WHERE Id = @LooPId
								IF((SELECT COUNT(1) FROM dbo.PurchaseOrderPart WITH(NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId AND PurchaseOrderId = @PoID) = 1)
								BEGIN
									UPDATE P    
									SET	   SubWorkOrderId = NULL, SubWorkOrderNo = NULL,
										   WorkOrderMaterialsId = NULL, 
										   IsKit = NULL, IsSubWO =NULL, 
										   UpdatedDate = GETUTCDATE()
									FROM DBO.PurchaseOrderPart P WHERE P.SubWorkOrderId = @SubWorkOrderId AND PurchaseOrderId = @PoID
									DELETE FROM dbo.PurchaseOrderPartReference WHERE ModuleId = 5 AND ReferenceId = @SubWorkOrderId AND PurchaseOrderId = @PoID
								END
							SET @LooPId +=1 
						END
					END

					DELETE FROM [dbo].[SubWorkOrderMaterialStockLineKit] WHERE SubWorkOrderMaterialsKitId IN (SELECT SubWorkOrderMaterialsKitId FROM [DBO].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId));
					
					--DELETE WOM KIT FOR NO STOCKLINE EXIST
					IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[SubWorkOrderMaterialStockLineKit] WITH(NOLOCK) WHERE [SubWorkOrderMaterialsKitId] IN (SELECT SubWorkOrderMaterialsKitId FROM [DBO].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId)))
					BEGIN
						DELETE FROM [dbo].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId)
					END
					--DELETE FROM [DBO].[SubWorkOrderMaterialsKit] WHERE [SubWorkOrderMaterialsKitMappingId] IN (SELECT [SubWorkOrderMaterialsKitMappingId] FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId);
					
					DELETE FROM [DBO].[SubWorkOrderMaterialsKitMapping] WHERE KitId = @KitId AND SubWOPartNoId = @SubWOPartNoId;
				END

			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteSubWorkOrderMaterialKit' 
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