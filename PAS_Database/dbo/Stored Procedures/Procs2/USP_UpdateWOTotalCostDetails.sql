/*************************************************************           
 ** File:   [USP_UpdateWOTotalCostDetails]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Recalculate WO Total Cost    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    02/22/2021   Hemant Saliya		Created
	2    01/31/2024	  Devendra Shekh	added isperforma Flage for WOInvoice
     
 EXECUTE USP_UpdateWOTotalCostDetails 331, 358, 'admin', 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateWOTotalCostDetails]    
(    
@WorkOrderId  BIGINT  = NULL,
@WorkOrderWorkflowId  BIGINT  = NULL,
@UpdatedBy  VARCHAR(100) = NULL,
@MasterCompanyId  BIGINT  = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @PartCost DECIMAL(18,2);
				DECLARE @WOWorkScopeId BIGINT;
				DECLARE @WOPartNoId BIGINT;
				DECLARE @RepairWorkScopeId BIGINT;
				DECLARE @WOQLaborCost DECIMAL(18,2);
				DECLARE @Revenue DECIMAL(18,2);
				DECLARE @KitCost DECIMAL(18,2);

				IF OBJECT_ID(N'tempdb..#WOCostDetails') IS NOT NULL
				BEGIN
				DROP TABLE #WOCostDetails 
				END
				
				CREATE TABLE #WOCostDetails 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderId BIGINT NULL,
					 WorkOrderPartNumberId BIGINT NULL,
					 WorkFlowWorkOrderId BIGINT NULL,
					 WorkOrderQuoteId BIGINT NULL,
					 BurdenRateAmount DECIMAL(18,2) NULL,
					 DirectLaborOHCost DECIMAL(18,2) NULL,
					 TotalCostPerHour DECIMAL(18,2) NULL,
					 TotalLaborCost DECIMAL(18,2) NULL,
					 --LaborCost DECIMAL(18,2) NULL,
					 --LaborOverheadCost DECIMAL(18,2) NULL,
					 MaterialCost DECIMAL(18,2) NULL,
					 ChargesCost DECIMAL(18,2) NULL,
					 FreightCost DECIMAL(18,2) NULL,
					 ExclusionCost DECIMAL(18,2) NULL,
					 Revenue DECIMAL(18,2) NULL,
					 ActRevenue DECIMAL(18,2) NULL,
					 Margin DECIMAL(18,2) NULL,
					 ActMargin DECIMAL(18,2) NULL,
					 MarginPer DECIMAL(18,2) NULL,
					 ActMarginPer DECIMAL(18,2) NULL,
					 PartsRevePer DECIMAL(18,2) NULL,
					 LaborRevePer DECIMAL(18,2) NULL,
					 OverHeadPer DECIMAL(18,2) NULL,
					 TotalCost DECIMAL(18,2) NULL,
					 DirectCost DECIMAL(18,2) NULL,
					 DirectCostPer DECIMAL(18,2) NULL,
				)

				IF OBJECT_ID(N'tempdb..#WOMaterials') IS NOT NULL
				BEGIN
				DROP TABLE #WOMaterials
				END
				
				CREATE TABLE #WOMaterials 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderId BIGINT NULL,
					 WorkOrderMaterialsId BIGINT NULL,
					 WorkFlowWorkOrderId BIGINT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 QtyIssued DECIMAL(18,2) NULL,
					 QtyReserved DECIMAL(18,2) NULL,
					 MaterialCost DECIMAL(18,2) NULL
				)

				IF OBJECT_ID(N'tempdb..#WOQuoteDetails') IS NOT NULL
				BEGIN
				DROP TABLE #WOQuoteDetails 
				END
				
				CREATE TABLE #WOQuoteDetails 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderId BIGINT NULL,
					 WorkFlowWorkOrderId BIGINT NULL,
					 WorkOrderQuoteId BIGINT NULL,
					 WorkOrderQuoteDetailsId BIGINT NULL,
					 LaborFlatBillingAmount DECIMAL(18,2) NULL,
					 MaterialFlatBillingAmount DECIMAL(18,2) NULL,
					 ChargesFlatBillingAmount DECIMAL(18,2) NULL,
					 FreightFlatBillingAmount DECIMAL(18,2) NULL
				)

				IF OBJECT_ID(N'tempdb..#WOQuoteLaborHeader') IS NOT NULL
				BEGIN
				DROP TABLE #WOQuoteLaborHeader 
				END
				
				CREATE TABLE #WOQuoteLaborHeader 
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderQuoteLaborHeaderId BIGINT NULL,					
					 MarkupFixedPrice VARCHAR(20) NULL					 
				)

				SELECT @WOWorkScopeId = WOP.WorkOrderScopeId, @WOPartNoId = WOP.ID FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId
				WHERE WOWF.WorkFlowWorkOrderId = @WorkOrderWorkflowId

				SELECT @RepairWorkScopeId = WorkScopeId FROM dbo.WorkScope WITH(NOLOCK) WHERE UPPER(WorkScopeCodeNew) = 'REPAIR' AND MasterCompanyId = @MasterCompanyId

				INSERT INTO #WOMaterials(WorkOrderId, WorkFlowWorkOrderId, WorkOrderMaterialsId, UnitCost, QtyIssued, QtyReserved, MaterialCost)
				SELECT  
					WOM.WorkOrderId, WOM.WorkFlowWorkOrderId,WOM.WorkOrderMaterialsId,
					ISNULL(WOMSL.UnitCost, 0) AS UnitCost,
					ISNULL(WOMSL.QtyIssued, 0) AS QtyIssued,
					ISNULL(WOMSL.QtyReserved, 0) AS QtyReserved,
					ISNULL(WOMSL.UnitCost, 0) * ISNULL(WOMSL.QtyIssued, 0) AS MaterialCost
				FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
					JOIN dbo.WorkOrderMaterialStockLine WOMSL WITH(NOLOCK) ON WOMSL.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
				WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOMSL.QtyIssued > 0 AND WOM.IsDeleted = 0 AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0
				UNION ALL
				SELECT  
					WOM.WorkOrderId, WOM.WorkFlowWorkOrderId,WOM.WorkOrderMaterialsKitId AS WorkOrderMaterialsId,
					ISNULL(WOMSL.UnitCost, 0) AS UnitCost,
					ISNULL(WOMSL.QtyIssued, 0) AS QtyIssued,
					ISNULL(WOMSL.QtyReserved, 0) AS QtyReserved,
					ISNULL(WOMSL.UnitCost, 0) * ISNULL(WOMSL.QtyIssued, 0) AS MaterialCost
				FROM dbo.WorkOrderMaterialsKit WOM WITH(NOLOCK)
					JOIN dbo.WorkOrderMaterialStockLineKit WOMSL WITH(NOLOCK) ON WOMSL.WorkOrderMaterialsKitId = WOM.WorkOrderMaterialsKitId
				WHERE WOM.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOMSL.QtyIssued > 0 AND WOM.IsDeleted = 0 AND WOMSL.IsActive = 1 AND WOMSL.IsDeleted = 0

				IF((SELECT COUNT(1) FROM #WOMaterials) > 0)
				BEGIN
					INSERT INTO #WOCostDetails(WorkOrderId, WorkFlowWorkOrderId, MaterialCost)
					SELECT WorkOrderId, WorkFlowWorkOrderId, SUM(ISNULL(WOM.UnitCost, 0) * ISNULL(WOM.QtyIssued, 0)) FROM #WOMaterials WOM WITH(NOLOCK) 
					WHERE WOM.QtyIssued > 0
					GROUP BY WorkOrderId, WorkFlowWorkOrderId
				END
				ELSE
				BEGIN
					INSERT INTO #WOCostDetails(WorkOrderId, WorkFlowWorkOrderId, MaterialCost)
					SELECT @WorkOrderId, @WorkOrderWorkflowId, 0.00
				END

				UPDATE #WOCostDetails SET WorkOrderPartNumberId = @WOPartNoId; 

				UPDATE #WOCostDetails SET ChargesCost = 
				(SELECT SUM(ISNULL(WOC.UnitCost, 0) * ISNULL(WOC.Quantity, 0)) FROM dbo.WorkOrderCharges WOC WITH(NOLOCK)
				WHERE WOC.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOC.IsDeleted = 0 AND WOC.IsActive = 1 )

				UPDATE #WOCostDetails SET FreightCost =
				(SELECT SUM(ISNULL(WOF.Amount, 0)) FROM dbo.WorkOrderFreight WOF WITH(NOLOCK)
				WHERE WOF.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOF.IsDeleted = 0 AND WOF.IsActive = 1)

				UPDATE #WOCostDetails SET ExclusionCost =
				(SELECT SUM(ISNULL(WOE.UnitCost, 0) * ISNULL(WOE.Quantity, 0)) FROM dbo.WorkOrderExclusions WOE WITH(NOLOCK)
				WHERE WOE.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOE.IsDeleted = 0 AND WOE.IsActive = 1) 

				;WITH CTE AS(
						SELECT	SUM(ISNULL((CAST(ISNULL(AdjustedHours,0) AS INT) + (ISNULL(AdjustedHours,0) - CAST(ISNULL(AdjustedHours,0) AS INT))/.6)* ISNULL(WOL.BurdenRateAmount, 0) ,0)) BurdenRateAmount,
								SUM(ISNULL(WOL.TotalCostPerHour, 0)) AS TotalCostPerHour,
								SUM(ISNULL(WOL.TotalCost, 0)) AS TotalLaborCost,
								SUM(ISNULL(WOL.DirectLaborOHCost, 0)) AS DirectLaborOHCost
						FROM #WOCostDetails WOC 
							JOIN dbo.WorkOrderLaborHeader WOLH WITH(NOLOCK) ON WOLH.WorkFlowWorkOrderId = WOC.WorkFlowWorkOrderId
							JOIN dbo.WorkOrderLabor WOL WITH(NOLOCK) ON WOLH.WorkOrderLaborHeaderId = WOL.WorkOrderLaborHeaderId
						WHERE WOLH.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOL.BillableId = 1 AND WOLH.IsDeleted = 0 AND WOL.IsActive = 1 AND WOL.IsDeleted = 0
				)UPDATE #WOCostDetails 
				SET BurdenRateAmount = CTE.BurdenRateAmount, TotalCostPerHour = CTE.TotalCostPerHour, DirectLaborOHCost = CTE.DirectLaborOHCost, TotalLaborCost = CTE.TotalLaborCost FROM CTE 

				INSERT INTO #WOQuoteDetails (WorkOrderId,WorkFlowWorkOrderId,WorkOrderQuoteId, WorkOrderQuoteDetailsId, LaborFlatBillingAmount, MaterialFlatBillingAmount, ChargesFlatBillingAmount, FreightFlatBillingAmount ) 
				SELECT WorkOrderId,WOWF.WorkFlowWorkOrderId,WorkOrderQuoteId, WorkOrderQuoteDetailsId, LaborFlatBillingAmount, MaterialFlatBillingAmount, ChargesFlatBillingAmount, FreightFlatBillingAmount 
				FROM dbo.WorkOrderQuoteDetails WOQD WITH(NOLOCK) 
					JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOQD.WorkflowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOQD.WOPartNoId = WOWF.WorkOrderPartNoId
				WHERE WOQD.WorkflowWorkOrderId = @WorkOrderWorkflowId AND WOQD.IsVersionIncrease = 0 AND WOWF.WorkOrderPartNoId = WOQD.WOPartNoId

				IF((SELECT COUNT(1) FROM #WOQuoteDetails) > 0 AND @WOWorkScopeId = @WOWorkScopeId)
				BEGIN
					INSERT INTO #WOQuoteLaborHeader(WorkOrderQuoteLaborHeaderId, MarkupFixedPrice)
					SELECT TOP 1 WorkOrderQuoteLaborHeaderId, MarkupFixedPrice FROM dbo.WorkOrderQuoteLaborHeader WQLH WITH(NOLOCK) 
						JOIN #WOQuoteDetails WOQD ON WOQD.WorkOrderQuoteDetailsId = WQLH.WorkOrderQuoteDetailsId
					WHERE WQLH.IsDeleted = 0

					SELECT @WOQLaborCost = LaborFlatBillingAmount FROM #WOQuoteDetails

					IF((SELECT COUNT(1) FROM #WOQuoteLaborHeader) > 0 AND (SELECT MarkupFixedPrice FROM #WOQuoteLaborHeader) <> '3')
					BEGIN
						SELECT 
						@WOQLaborCost = SUM(ISNULL(WOQL.BillingAmount, 0))
						FROM dbo.WorkOrderQuoteLabor WOQL
							JOIN dbo.WorkOrderQuoteLaborHeader WOQLH WITH(NOLOCK) ON WOQLH.WorkOrderQuoteLaborHeaderId = WOQL.WorkOrderQuoteLaborHeaderId
							JOIN #WOQuoteDetails WOQD ON WOQD.WorkOrderQuoteDetailsId = WOQLH.WorkOrderQuoteDetailsId
						WHERE WOQL.BillableId = 1 AND WOQLH.IsDeleted = 0 AND WOQL.IsActive = 1 AND WOQL.IsDeleted = 0
					END

					IF((SELECT COUNT(1) FROM #WOQuoteLaborHeader) > 0 AND (SELECT MarkupFixedPrice FROM #WOQuoteLaborHeader) <> '3')
					BEGIN
						SELECT 
						@WOQLaborCost = SUM(ISNULL(WOQL.BillingAmount, 0))
						FROM dbo.WorkOrderQuoteLabor WOQL
							JOIN dbo.WorkOrderQuoteLaborHeader WOQLH WITH(NOLOCK) ON WOQLH.WorkOrderQuoteLaborHeaderId = WOQL.WorkOrderQuoteLaborHeaderId
							JOIN #WOQuoteDetails WOQD ON WOQD.WorkOrderQuoteDetailsId = WOQLH.WorkOrderQuoteDetailsId
						WHERE WOQL.BillableId = 1 AND WOQLH.IsDeleted = 0 AND WOQL.IsActive = 1 AND WOQL.IsDeleted = 0
					END

					IF((SELECT COUNT(1) FROM WorkOrderQuoteMaterialKitMapping WOQM  WITH(NOLOCK) where WOQM.WorkflowWorkOrderId =@WorkOrderWorkflowId and WOQM.IsDeleted=0 ) > 0)
					BEGIN
						SELECT 
						@KitCost = SUM(ISNULL(WOQM.BillingAmount, 0))
						FROM dbo.WorkOrderQuoteMaterialKitMapping WOQM
						WHERE WOQM.WorkflowWorkOrderId =@WorkOrderWorkflowId and WOQM.IsDeleted=0 AND WOQM.IsActive = 1 
					END

					UPDATE #WOCostDetails
					SET Revenue = @WOQLaborCost + ISNULL(WOQD.MaterialFlatBillingAmount,0) + ISNULL(@KitCost,0) + ISNULL(WOQD.ChargesFlatBillingAmount,0),
						WorkOrderQuoteId = WOQD.WorkOrderQuoteId
					FROM #WOQuoteDetails WOQD
				END
				ELSE
				BEGIN
					UPDATE #WOCostDetails
					SET Revenue = ISNULL(TotalLaborCost,0) + ISNULL(MaterialCost,0) + ISNULL(ChargesCost,0)
					FROM #WOCostDetails
				END

				UPDATE #WOCostDetails
					SET PartsRevePer = dbo.udfCalcPercentage(ISNULL(MaterialCost,0), ISNULL(Revenue,0)),
						LaborRevePer = dbo.udfCalcPercentage(ISNULL(TotalLaborCost,0), ISNULL(Revenue,0)),
						OverHeadPer = dbo.udfCalcPercentage(ISNULL(BurdenRateAmount,0), ISNULL(Revenue,0))
				FROM #WOCostDetails

				UPDATE #WOCostDetails
					SET TotalCost = ISNULL(TotalLaborCost,0) + ISNULL(MaterialCost,0) + ISNULL(ChargesCost,0) + ISNULL(FreightCost,0) + ISNULL(ExclusionCost,0),
						DirectCost = ISNULL(TotalLaborCost,0) + ISNULL(MaterialCost,0) + ISNULL(ChargesCost,0)
				FROM #WOCostDetails

				UPDATE #WOCostDetails
					SET Margin = ISNULL(Revenue,0) - ISNULL(DirectCost,0),
						DirectCostPer = dbo.udfCalcPercentage(ISNULL(DirectCost,0), ISNULL(Revenue,0))
				FROM #WOCostDetails

				UPDATE #WOCostDetails
					SET MarginPer = dbo.udfCalcPercentage(ISNULL(Margin,0), ISNULL(Revenue,0))
				FROM #WOCostDetails
				
				--CASE WHEN INVOICE IS GENERATED THEN TAKE IT FROM INVOICE
				IF((SELECT COUNT(1) FROM dbo.WorkOrderBillingInvoicing WOB WITH(NOLOCK) 
					WHERE WOB.WorkOrderId = @WorkOrderId AND WOB.WorkFlowWorkOrderId = @WorkOrderWorkflowId AND WOB.IsVersionIncrease = 0 AND ISNULL(WOB.IsPerformaInvoice, 0) = 0) > 0)
				BEGIN
					UPDATE #WOCostDetails
					SET Revenue = ISNULL(WOB.GrandTotal,0),
						ActRevenue = ISNULL(WOB.GrandTotal,0),
						ActMargin = ISNULL(WOB.GrandTotal,0) - ISNULL(WOCD.DirectCost,0),
						ActMarginPer = dbo.udfCalcPercentage(ISNULL(WOCD.DirectCost,0), ISNULL(WOB.GrandTotal,0)),
						PartsRevePer = dbo.udfCalcPercentage(ISNULL(WOCD.MaterialCost,0), ISNULL(WOB.GrandTotal,0)),
						LaborRevePer = dbo.udfCalcPercentage(ISNULL(WOCD.TotalLaborCost,0), ISNULL(WOB.GrandTotal,0)),
						OverHeadPer = dbo.udfCalcPercentage(ISNULL(WOCD.BurdenRateAmount,0), ISNULL(WOB.GrandTotal,0)),
						Margin =  ISNULL(WOB.GrandTotal,0) - ISNULL(WOCD.DirectCost,0),
						MarginPer = dbo.udfCalcPercentage(ISNULL(WOB.GrandTotal,0) - ISNULL(WOCD.DirectCost,0), ISNULL(WOB.GrandTotal,0)),
						DirectCostPer = dbo.udfCalcPercentage(ISNULL(WOCD.DirectCost,0), ISNULL(WOB.GrandTotal,0))
					FROM #WOCostDetails WOCD 
						JOIN dbo.WorkOrderBillingInvoicing WOB WITH(NOLOCK) ON WOCD.WorkOrderId = WOB.WorkOrderId AND WOCD.WorkFlowWorkOrderId = wob.WorkFlowWorkOrderId
					WHERE WOB.IsVersionIncrease = 0 AND ISNULL(WOB.IsPerformaInvoice, 0) = 0
				END

				IF((SELECT COUNT(1) FROM dbo.WorkOrderMPNCostDetails WOC WITH(NOLOCK) 
					WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WOPartNoId = @WOPartNoId) > 0)
				BEGIN
					UPDATE WorkOrderMPNCostDetails
						SET ActualMargin = ISNULL(WOCD.ActMargin,0),
							ActualMarginPercentage = ISNULL(WOCD.ActMarginPer,0),	
							ActualRevenue = ISNULL(WOCD.ActRevenue,0),
							ChargesCost = ISNULL(WOCD.ChargesCost,0),
							DirectCost = ISNULL(WOCD.DirectCost,0),
							DirectCostPercentage = ISNULL(WOCD.DirectCostPer,0),
							ExclusionCost = ISNULL(WOCD.ExclusionCost,0),
							FreightCost = ISNULL(WOCD.FreightCost,0),
							LaborCost = ISNULL(WOCD.TotalLaborCost,0),
							LaborRevPercentage = ISNULL(WOCD.LaborRevePer,0),
							Margin = ISNULL(WOCD.Margin,0),
							MarginPercentage = ISNULL(WOCD.MarginPer,0),
							OtherCost = ISNULL(WOCD.ChargesCost,0),
							OverHeadCost = ISNULL(WOCD.BurdenRateAmount,0),
							OverHeadPercentage = ISNULL(WOCD.OverHeadPer,0),
							PartsCost = ISNULL(WOCD.MaterialCost,0),
							PartsRevPercentage = ISNULL(WOCD.PartsRevePer,0),
							Revenue = ISNULL(WOCD.Revenue,0),
							TotalCost = ISNULL(WOCD.TotalCost,0),
							WOBillingShippingId = 0,
							WOPartNoId = @WOPartNoId,
							WOQuoteId = WorkOrderQuoteId,
							WorkOrderId = WOCD.WorkOrderId,
							UpdatedBy = @UpdatedBy,
							UpdatedDate = GETDATE()
					FROM dbo.WorkOrderMPNCostDetails WOC WITH(NOLOCK) 
						JOIN #WOCostDetails WOCD ON WOC.WorkOrderId = WOCD.WorkOrderId 
					WHERE WOC.WOPartNoId = @WOPartNoId
				END
				ELSE
				BEGIN
					INSERT INTO WorkOrderMPNCostDetails(
							ActualMargin,
							ActualMarginPercentage,
							ActualRevenue,
							ChargesCost,
							DirectCost,
							DirectCostPercentage,
							ExclusionCost,
							FreightCost,
							LaborCost,
							LaborRevPercentage,
							Margin,
							MarginPercentage,
							OtherCost,
							OverHeadCost,
							OverHeadPercentage,
							PartsCost,
							PartsRevPercentage,
							Revenue,
							TotalCost,
							CreatedBy,
							UpdatedBy,
							CreatedDate,
							UpdatedDate,
							IsActive,
							IsDeleted,
							MasterCompanyId,
							WOBillingShippingId,
							WOPartNoId,
							WOQuoteId,
							WorkOrderId
					)
					SELECT  WOCD.ActMargin,
							WOCD.ActMarginPer,
							WOCD.ActRevenue,
							WOCD.ChargesCost,
							WOCD.DirectCost,
							WOCD.DirectCostPer,
							WOCD.ExclusionCost,
							WOCD.FreightCost,
							WOCD.TotalLaborCost,
							WOCD.LaborRevePer,
							WOCD.Margin,
							WOCD.MarginPer,
							WOCD.ChargesCost,
							WOCD.BurdenRateAmount,
							WOCD.OverHeadPer,
							WOCD.MaterialCost,
							WOCD.PartsRevePer,
							WOCD.Revenue,
							WOCD.TotalCost,
							@UpdatedBy,
							@UpdatedBy,
							GETDATE(),
							GETDATE(),
							1,
							0,
							@MasterCompanyId,
							0,
							@WOPartNoId,
							WOCD.WorkOrderQuoteId,
							WOCD.WorkOrderId FROM #WOCostDetails WOCD 
				END

				IF OBJECT_ID(N'tempdb..#WOCostDetails') IS NOT NULL
				BEGIN
				DROP TABLE #WOCostDetails 
				END

				IF OBJECT_ID(N'tempdb..#WOMaterials') IS NOT NULL
				BEGIN
				DROP TABLE #WOMaterials
				END

				IF OBJECT_ID(N'tempdb..#WOQuoteDetails') IS NOT NULL
				BEGIN
				DROP TABLE #WOQuoteDetails 
				END

				IF OBJECT_ID(N'tempdb..#WOQuoteLaborHeader') IS NOT NULL
				BEGIN
				DROP TABLE #WOQuoteLaborHeader 
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
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWOTotalCostDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderWorkflowId, '') + '' 
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