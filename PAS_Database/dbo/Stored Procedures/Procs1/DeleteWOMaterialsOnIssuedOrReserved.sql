/*************************************************************   
-- =============================================
-- Author:		<Ayesha Sultana>
-- Create date: <26-7-2023>
-- Description:	<Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision>
-- =============================================
**************************************************************

** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    26/7/2023   Ayesha Sultana   Delete WO Materials & its Stockline if not issued/ reserved & no WO Provision
** 2    16/10/2024  RAJESH GAMI      Un Mapped PO by WO-SubWO Materials Id | KIT, While Delete the Materials
** 3    29/10/2024  RAJESH GAMI      Un Mapped WO if there is no other material link with the same workorder in the Same PO (Updated)
**************************************************************/ 

CREATE   PROCEDURE [dbo].[DeleteWOMaterialsOnIssuedOrReserved]
	@WorkFlowWorkOrderId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
			DECLARE @WorkOrderId BIGINT = (SELECT top 1 WorkOrderId FROM DBO.WorkOrderWorkFlow WITH(NOLOCK)  WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
			DECLARE @PoID BIGINT = 0, @LooPId INT = 1, @TotalCount INT = 0
			IF OBJECT_ID(N'tempdb..##TempWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempWOtbl
				END
			IF OBJECT_ID(N'tempdb..##TempPOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempPOtbl
				END
			CREATE TABLE #TempPOtbl(Id [int] IDENTITY(1,1),POID BIGINT NULL)
			CREATE TABLE #TempWOtbl(WorkOrderMaterialsId BIGINT)

			INSERT INTO #TempWOtbl (WorkOrderMaterialsId)

			SELECT DISTINCT WOM.WorkOrderMaterialsId

			FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)

			WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) = 0 
					AND WOM.ProvisionId NOT IN ( SELECT ProvisionId FROM Provision WHERE Description = 'SUB WORK ORDER') ;
			
			INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM  #TempWOtbl) AND ISNULL(POId,0) > 0

			UPDATE dbo.Stockline SET WorkOrderMaterialsId = NULL FROM dbo.Stockline S JOIN #TempWOtbl tmpWOM ON S.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
			DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #TempWOtbl tmpWOM ON WOMS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
			DELETE WOM FROM dbo.WorkOrderMaterials WOM JOIN #TempWOtbl tmpWOM ON WOM.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId;

			UPDATE P    
				    SET WorkOrderMaterialsId = NULL, 
					       IsKit = NULL, IsSubWO =NULL, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtbl tmp ON P.WorkOrderMaterialsId = tmp.WorkOrderMaterialsId
					  WHERE P.WorkOrderMaterialsId  = tmp.WorkOrderMaterialsId AND ISNULL(IsKit,0) = 0 AND ISNULL(IsSubWO,0) = 0
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
			
		

			IF OBJECT_ID(N'tempdb..#TempWOtbl') IS NOT NULL
				BEGIN
					DROP TABLE #TempWOtbl 
				END

			COMMIT  TRANSACTION
		END TRY
		
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'DeleteWOMaterialsOnIssuedOrReserved' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkFlowWorkOrderId, '') + ''
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