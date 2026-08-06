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
** 4    29/10/2024  Devendra Shekh   Modified (Handling Kit Material Delete)
** 5    04/09/2025  Moin Bloch		 Updated Added History
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	8    24/July/2026			 RAJESH GAMI						[PN-17350] - Removed 3 leftover IsNonStock=0 exclusion filter(s) added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filters no longer needed).
EXEC [dbo].[DeleteWOMaterialsOnIssuedOrReserved] 61067,'ADMIN User'
**************************************************************/ 
CREATE OR ALTER PROCEDURE [dbo].[DeleteWOMaterialsOnIssuedOrReserved]
@WorkFlowWorkOrderId BIGINT,
@UpdatedBy VARCHAR(255) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN TRANSACTION
			DECLARE @WorkOrderModuleID INT = 0
			DECLARE @DeleteWOMaterial VARCHAR(50)='DeleteWorkOrderMaterials'
			DECLARE @TemplateBody VARCHAR(MAX)=''
			DECLARE @ItemMasterId BIGINT = 0
			DECLARE @PartNumber VARCHAR(50) = NULL
			DECLARE @WorkOrderNum VARCHAR(50) = NULL
			DECLARE @CreatedDate DATETIME2(7) = GETUTCDATE()
			DECLARE @MasterCompanyId INT = 1
				-- Modules
			SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';
			DECLARE @WorkOrderId BIGINT = (SELECT top 1 WorkOrderId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK)  WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
			DECLARE @WOPartNoId BIGINT = (SELECT top 1 WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK)  WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId)
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
			CREATE TABLE #TempWOtbl(WorkOrderMaterialsId BIGINT, IsKit BIT)

			INSERT INTO #TempWOtbl (WorkOrderMaterialsId, IsKit)

			SELECT DISTINCT WOM.WorkOrderMaterialsId, 0

			FROM [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK)		

			WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) = 0 
					AND WOM.ProvisionId NOT IN ( SELECT ProvisionId FROM [dbo].[Provision] WITH(NOLOCK) WHERE [Description] = 'SUB WORK ORDER');

			--Inserting KIT Data
			INSERT INTO #TempWOtbl (WorkOrderMaterialsId, IsKit)
			SELECT DISTINCT WOM.WorkOrderMaterialsKitId, 1
			FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)
			WHERE WOM.WorkFlowWorkOrderId = @WorkFlowWorkOrderId 
					AND (ISNULL(WOM.QuantityReserved, 0) + ISNULL(WOM.QuantityIssued, 0)) = 0 
					AND WOM.ProvisionId NOT IN ( SELECT ProvisionId FROM [dbo].[Provision] WITH(NOLOCK) WHERE [Description] = 'SUB WORK ORDER');
			
			INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK) WHERE WorkOrderMaterialsId IN (SELECT WorkOrderMaterialsId FROM  #TempWOtbl WHERE IsKit = 0) AND ISNULL(POId,0) > 0
			INSERT INTO #TempPOtbl(POID) SELECT POId FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK) WHERE WorkOrderMaterialsKitId IN (SELECT WorkOrderMaterialsId FROM  #TempWOtbl WHERE IsKit = 1) AND ISNULL(POId,0) > 0

			UPDATE dbo.Stockline SET WorkOrderMaterialsId = NULL FROM dbo.Stockline S JOIN #TempWOtbl tmpWOM ON S.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 0;
			DELETE WOMS FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #TempWOtbl tmpWOM ON WOMS.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 0;
			DELETE WOM FROM dbo.WorkOrderMaterials WOM JOIN #TempWOtbl tmpWOM ON WOM.WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 0;

			UPDATE dbo.Stockline SET WorkOrderMaterialsKitId = NULL FROM dbo.Stockline S JOIN #TempWOtbl tmpWOM ON S.WorkOrderMaterialsKitId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 1;
			DELETE WOMS FROM dbo.WorkOrderMaterialStockLineKit WOMS JOIN #TempWOtbl tmpWOM ON WOMS.WorkOrderMaterialsKitId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 1;
			DELETE WOM FROM dbo.WorkOrderMaterialsKit WOM JOIN #TempWOtbl tmpWOM ON WOM.WorkOrderMaterialsKitId = tmpWOM.WorkOrderMaterialsId AND tmpWOM.IsKit = 1;

			IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId)
			BEGIN
				DELETE FROM [dbo].[WorkOrderMaterialsKitMapping] WHERE [WOPartNoId] = @WOPartNoId;
			END

			UPDATE P    
				    SET WorkOrderMaterialsId = NULL, 
					       IsKit = NULL, IsSubWO =NULL, 
						   UpdatedDate = GETUTCDATE()
					FROM DBO.PurchaseOrderPart P
					  INNER JOIN #TempWOtbl tmp ON P.WorkOrderMaterialsId = tmp.WorkOrderMaterialsId
					  WHERE P.WorkOrderMaterialsId  = tmp.WorkOrderMaterialsId AND ISNULL(IsSubWO,0) = 0 --AND ISNULL(IsKit,0) = 0 
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
			
			SELECT @WorkOrderNum = [WorkOrderNum], @MasterCompanyId = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

			SELECT @ItemMasterId = [ItemMasterId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WOPartNoId;
	
			SELECT @PartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId ;
							
			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @DeleteWOMaterial;	

			SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', @WorkOrderNum)
			SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @PartNumber)
		
			EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WOPartNoId,'','',@TemplateBody,'DeleteWorkOrderMaterials',@MasterCompanyId,@UpdatedBy,@CreatedDate,@UpdatedBy,@CreatedDate
			
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
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS VARCHAR(100))  
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