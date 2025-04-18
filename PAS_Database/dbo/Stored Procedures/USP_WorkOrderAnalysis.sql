/***************************************************************  
 ** File:   [USP_WorkOrderAnalysis]             
 ** Author:   Shrey Chandegara
 ** Description: Get WorkOrder Analysis
 ** Date:  11-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    11-04-2025		Shrey Chandegara		Created  	
	2    11-04-2025		Hemnat Saliya			Added DB Standards  	
		
	exec dbo.USP_WorkOrderAnalysis 8631,8331
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_WorkOrderAnalysis]
    @WorkOrderId BIGINT,
    @WorkOrderPartNoId BIGINT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		
		IF EXISTS (SELECT TOP 1 1 WOBillingInvoicingItemId FROM [dbo].[WorkOrderBillingInvoicingItem] WITH(NOLOCK) WHERE WorkOrderPartId = @WorkOrderPartNoId AND ISNULL(IsVersionIncrease, 0) = 0 AND ISNULL(IsPerformaInvoice, 0) <> 1)
		BEGIN
			SELECT DISTINCT
				wop.ID,
				im.PartNumber,
				im.PartDescription,
				im.RevisedPart AS RevisedPartNo,
				ISNULL(woc.Revenue, 0) AS Revenue,
				ISNULL(woc.PartsCost, 0) AS MaterialCost,
				CASE WHEN ISNULL(woc.Revenue, 0) > 0 THEN woc.PartsRevPercentage ELSE 0 END AS MaterialRevenuePercentage,
				ISNULL(woc.LaborCost, 0) AS LaborCost,
				CASE WHEN ISNULL(woc.Revenue, 0) > 0 THEN woc.LaborRevPercentage ELSE 0 END AS LaborRevenuePercentage,
				ISNULL(woc.OverHeadCost, 0) AS OverHeadCost,
				woc.OverHeadPercentage AS OverHeadCostRevenuePercentage,
				ISNULL(woc.ChargesCost, 0) AS ChargesCost,
				ISNULL(wb.FreightCost, 0) AS FreightCost,
				CASE WHEN ISNULL(woc.Revenue, 0) > 0 THEN ISNULL(wb.FreightCostPlus, 0) ELSE 0 END AS Freightbilling,
				ISNULL(woc.OtherCost, 0) AS OtherCost,
				ISNULL(woc.DirectCost, 0) AS DirectCost,
				CASE 
					WHEN ISNULL(woc.Revenue, 0) > 0 
					THEN ROUND((ISNULL(woc.PartsCost, 0.00) + ISNULL(woc.LaborCost, 0.00) + ISNULL(woc.ChargesCost, 0.00)) * 100.00 / woc.Revenue, 2) 
					ELSE 0 
				END AS DirectCostRevenuePercentage,
				(ISNULL(woc.Revenue, 0) - (ISNULL(woc.PartsCost, 0.00) + ISNULL(woc.LaborCost, 0.00) + ISNULL(woc.ChargesCost, 0))) AS Margin,
				CASE 
					WHEN ISNULL(woc.Revenue, 0) > 0 
					THEN ROUND((ISNULL(woc.Revenue, 0) - (ISNULL(woc.PartsCost, 0.00) + ISNULL(woc.LaborCost, 0.00) + ISNULL(woc.ChargesCost, 0.00))) * 100.00 / woc.Revenue, 2) 
					ELSE 0 
				END AS MarginPercentage,
				c.Name AS CustomerName,
				wo.WorkOrderNum,
				s.Stage,
				st.Description AS Status,
				CAST(0 AS BIT) AS IsQuoteRevenue
			FROM WorkOrderMPNCostDetails woc WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON woc.WorkOrderId = wo.WorkOrderId
				INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON woc.WOPartNoId = wop.ID
				LEFT JOIN [dbo].[WorkOrderBillingInvoicingItem] wbi WITH(NOLOCK) ON wop.ID = wbi.WorkOrderPartId AND ISNULL(wbi.IsVersionIncrease, 0) = 0 AND ISNULL(wbi.IsPerformaInvoice, 0) != 1
				LEFT JOIN [dbo].[WorkOrderBillingInvoicing] wb WITH(NOLOCK) ON wbi.BillingInvoicingId = wb.BillingInvoicingId AND ISNULL(wb.IsVersionIncrease, 0) = 0 AND ISNULL(wb.IsPerformaInvoice, 0) != 1
				INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON wo.CustomerId = c.CustomerId
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
				INNER JOIN [dbo].[WorkOrderStage] s WITH(NOLOCK) ON wop.WorkOrderStageId = s.WorkOrderStageId
				INNER JOIN [dbo].[WorkOrderStatus] st WITH(NOLOCK) ON wop.WorkOrderStatusId = st.Id
			WHERE wo.WorkOrderId = @WorkOrderId AND woc.WOPartNoId = @WorkOrderPartNoId
			ORDER BY wop.ID;
		END

		ELSE
		BEGIN
			-- Quote Path
			;WITH QuoteList AS (
				SELECT DISTINCT
					wo.WorkOrderId,
					wqd.WOPartNoId,
					Revenue = 
						CASE 
							WHEN wqd.QuoteMethod = 1 
							THEN ISNULL(wqd.CommonFlatRate, 0)
							ELSE ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)
						END
				FROM WorkOrder wo WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderQuote] woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId
				INNER JOIN [dbo].[WorkOrderQuoteDetails] wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId
				WHERE wo.WorkOrderId = @WorkOrderId AND wqd.WOPartNoId = @WorkOrderPartNoId
			)
			SELECT DISTINCT
				wop.ID,
				im.PartNumber,
				im.PartDescription,
				im.RevisedPart AS RevisedPartNo,
				ISNULL(q.Revenue, 0) Revenue,
				ISNULL(woc.PartsCost, 0) AS MaterialCost,
				CASE WHEN q.Revenue > 0 THEN woc.PartsRevPercentage ELSE 0 END AS MaterialRevenuePercentage,
				ISNULL(woc.LaborCost, 0) LaborCost,
				CASE WHEN q.Revenue > 0 THEN woc.LaborRevPercentage ELSE 0 END AS LaborRevenuePercentage,
				ISNULL(woc.OverHeadCost, 0) OverHeadCost,
				woc.OverHeadPercentage AS OverHeadCostRevenuePercentage,
				ISNULL(woc.ChargesCost, 0) ChargesCost,
				ISNULL(woc.FreightCost, 0) FreightCost,
				CASE WHEN q.Revenue > 0 THEN woc.FreightCost ELSE 0 END AS Freightbilling,
				ISNULL(woc.OtherCost, 0) OtherCost,
				ISNULL(woc.DirectCost, 0) DirectCost,
				CASE 
					WHEN ISNULL(q.Revenue, 0) > 0 
					THEN ROUND(ISNULL(woc.DirectCost, 0) * 100.00 / q.Revenue, 2) 
					ELSE 0 
				END AS DirectCostRevenuePercentage,
				(ISNULL(q.Revenue, 0) - ISNULL(woc.DirectCost, 0)) AS Margin,
				CASE 
					WHEN ISNULL(q.Revenue, 0) > 0 
					THEN ROUND((ISNULL(q.Revenue, 0.00) - ISNULL(woc.DirectCost, 0.00)) * 100.00 / q.Revenue, 2) 
					ELSE 0 
				END AS MarginPercentage,
				c.Name AS CustomerName,
				wo.WorkOrderNum,
				s.Stage,
				st.Description AS Status,
				CAST(1 AS BIT) AS IsQuoteRevenue
			FROM WorkOrderMPNCostDetails woc WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON woc.WorkOrderId = wo.WorkOrderId
				INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON woc.WOPartNoId = wop.ID
				LEFT JOIN QuoteList q WITH(NOLOCK) ON q.WorkOrderId = woc.WorkOrderId AND q.WOPartNoId = woc.WOPartNoId
				INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON wo.CustomerId = c.CustomerId
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
				INNER JOIN [dbo].[WorkOrderStage] s WITH(NOLOCK) ON wop.WorkOrderStageId = s.WorkOrderStageId
				INNER JOIN [dbo].[WorkOrderStatus] st WITH(NOLOCK) ON wop.WorkOrderStatusId = st.Id
			WHERE wo.WorkOrderId = @WorkOrderId AND woc.WOPartNoId = @WorkOrderPartNoId
			ORDER BY wop.ID;
		END

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_WorkOrderAnalysis' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END