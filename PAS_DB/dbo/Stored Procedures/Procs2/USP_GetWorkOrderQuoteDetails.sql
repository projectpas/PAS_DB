
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: USP_GetWorkOrderQuoteDetails   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetWorkOrderQuoteDetails.sql)
-- ---------------------------------------------------------------------------------------------------
/***************************************************************  
 ** File:   [USP_GetWorkOrderQuoteDetails]             
 ** Author:   Hemnat Saliya
 ** Description: Get WorkOrder Quote Details
 ** Date:  18-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    21-04-2025		Hemnat Saliya			Created  		
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
		
	exec dbo.USP_GetWorkOrderQuoteDetails 8374
**************************************************************/

/***************************************************************************************************************************************
  ** Change History
 ***************************************************************************************************************************************
 ** PR   Date						 Author							Change Description
 ** --   --------					 -------						-------------------------------
****************************************************************************************************************************************/
CREATE   PROCEDURE USP_GetWorkOrderQuoteDetails
    @WorkOrderId INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON; 
	
	BEGIN TRY  
		SELECT DISTINCT
			wop.ID,
			im.PartNumber,
			im.PartDescription,
			im.ManufacturerName,
			im.RevisedPart AS RevisedPartNo,
			Revenue = 
				CASE 
					WHEN wqd.QuoteMethod = 1 THEN wqd.CommonFlatRate
					ELSE CASE WHEN wqd.MaterialBuildMethod = 3 THEN ISNULL(wqd.MaterialFlatBillingAmount, 0) ELSE ISNULL(MaterialBilling, 0) END +
						 CASE WHEN wqd.LaborBuildMethod = 3 THEN ISNULL(wqd.LaborFlatBillingAmount, 0) ELSE ISNULL(LaborBilling, 0) END  +
						 CASE WHEN wqd.ChargesBuildMethod = 3 THEN ISNULL(wqd.ChargesFlatBillingAmount, 0) ELSE ISNULL(ChargesBilling, 0) END				
				END,
			MaterialRevenue = CASE WHEN wqd.MaterialBuildMethod = 3 THEN ISNULL(wqd.MaterialFlatBillingAmount, 0) ELSE ISNULL(MaterialBilling, 0) END,
			MaterialCost = ISNULL(wqd.MaterialCost, 0),
			MaterialRevenuePercentage = ISNULL(wqd.MaterialRevenuePercentage, 0),
			TotalLaborCost = ISNULL(wqd.LaborCost, 0),
			LaborCost = ISNULL(wqd.LaborCost, 0) - ISNULL(wqd.OverHeadCost, 0),
			LaborRevenuePercentage = CASE WHEN wqd.LaborBuildMethod = 3 THEN ISNULL(wqd.LaborFlatBillingAmount, 0) ELSE ISNULL(LaborBilling, 0) END,
			OverHeadCost = ISNULL(wqd.OverHeadCost, 0),
			OverHeadCostRevenuePercentage = ISNULL(wqd.OverHeadCostRevenuePercentage, 0),
			ChargesCost = ISNULL(wqd.ChargesCost, 0),
			wqd.FreightCost,
			wqd.FreightFlatBillingAmount,
			OtherCost = ISNULL(wqd.ChargesCost, 0),
			DirectCost = ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0),
			DirectCostRevenuePercentage = 
				CASE 
					WHEN (ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)) > 0 
					THEN CAST(
							(ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0)) /
							(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0))
						  AS FLOAT) * 100.00 
					ELSE 0
				END,
			Margin =
				CASE 
					WHEN wqd.QuoteMethod = 1 
						THEN ISNULL(wqd.CommonFlatRate, 0) - (ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0))
					ELSE 
						(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)) - 
						(ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0))
				END,
			MarginPercentage =
				CASE 
					WHEN wqd.QuoteMethod = 1 AND ISNULL(wqd.CommonFlatRate, 0) > 0
						THEN CAST((ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0))/ISNULL(wqd.CommonFlatRate, 1) AS FLOAT) * 100.0 
					WHEN (ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0)) > 0
						THEN CAST(
								(ISNULL(wqd.MaterialCost, 0) + ISNULL(wqd.LaborCost, 0) + ISNULL(wqd.ChargesCost, 0))/
								(ISNULL(wqd.MaterialFlatBillingAmount, 0) + ISNULL(wqd.LaborFlatBillingAmount, 0) + ISNULL(wqd.ChargesFlatBillingAmount, 0))
							 AS FLOAT) * 100.0 
					ELSE 0
				END,
			c.Name AS CustomerName,
			wo.WorkOrderNum,
			s.Stage,
			st.Description AS Status,
			ws.WorkScopeCode AS WorkScope
		FROM [dbo].WorkOrder wo WITH(NOLOCK)
			INNER JOIN [dbo].WorkOrderQuote woq WITH(NOLOCK) ON wo.WorkOrderId = woq.WorkOrderId AND ISNULL(woq.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].WorkOrderQuoteDetails wqd WITH(NOLOCK) ON woq.WorkOrderQuoteId = wqd.WorkOrderQuoteId AND ISNULL(wqd.IsVersionIncrease, 0) = 0
			INNER JOIN [dbo].WorkOrderPartNumber wop WITH(NOLOCK) ON wqd.WOPartNoId = wop.ID
			INNER JOIN [dbo].ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
			INNER JOIN [dbo].Customer c WITH(NOLOCK) ON wo.CustomerId = c.CustomerId
			INNER JOIN [dbo].WorkOrderStage s WITH(NOLOCK) ON wop.WorkOrderStageId = s.WorkOrderStageId
			INNER JOIN [dbo].WorkOrderStatus st WITH(NOLOCK) ON wop.WorkOrderStatusId = st.Id
			INNER JOIN [dbo].WorkScope ws WITH(NOLOCK) ON wop.WorkOrderScopeId = ws.WorkScopeId
		WHERE wo.WorkOrderId = @WorkOrderId
		 AND ISNULL(im.IsNonStock,0) = 0
		 ORDER BY wop.ID
	END TRY      
	  BEGIN CATCH        
	   IF @@trancount > 0  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteDetails'   
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''  
				  , @ApplicationName VARCHAR(100) = 'PAS'  
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
				  exec spLogException   
						   @DatabaseName   = @DatabaseName  
						 , @AdhocComments   = @AdhocComments  
						 , @ProcedureParameters  = @ProcedureParameters  
						 , @ApplicationName         = @ApplicationName  
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;  
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
				  RETURN(1);  
	  END CATCH  
END