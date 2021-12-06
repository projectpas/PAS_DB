
/*************************************************************           
 ** File:   [WorkOrderQuoteSummarizedHistoryByMPN]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Quote Summarized History By MPN.    
 ** Purpose: This stored procedure is used WO Quote Summarized History.        
 ** Date:   07/13/2021        
          
 ** PARAMETERS:           
 @@WorkOrderId BIGINT
 @WorkOrderPartNumberId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2021   Hemant Saliya Created
     
--EXEC [WorkOrderQuoteSummarizedHistoryByMPN] 5,0
**************************************************************/

CREATE PROCEDURE [dbo].[WorkOrderQuoteSummarizedHistoryByMPN]
@ItemMasterId BIGINT,
@IsTwelveMonth BIT = 1
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					DECLARE @Month INT;

					IF(@IsTwelveMonth = 1)
					BEGIN
						SET @Month = 12
					END
					ELSE
					BEGIN
						SET @Month = 18
					END

					IF OBJECT_ID(N'tempdb..#tmpWorkOrderCostDetails') IS NOT NULL
					BEGIN
					DROP TABLE #tmpWorkOrderCostDetails
					END
				
					CREATE TABLE #tmpWorkOrderCostDetails
					(
						 ID BIGINT NOT NULL IDENTITY, 
						 ItemMasterId BIGINT NULL,
						 PartNumber VARCHAR(500) NULL,
						 WorkScopeId BIGINT NULL,
						 WorkScope VARCHAR(50) NULL,
						 CurrencyName VARCHAR(50) NULL,					 
						 Revenue DECIMAL(18,2) NULL,
						 DirectCost DECIMAL(18,2) NULL,
						 Margin DECIMAL(18,2) NULL,
						 MarginPercentage DECIMAL(18,2) NULL,
						 ApprovedStatus VARCHAR(50) NULL,
						 AvgRevenue DECIMAL(18,2) NULL,
						 AvgMargin DECIMAL(18,2) NULL,
						 WorkOrderId BIGINT NULL,
					)

					INSERT INTO #tmpWorkOrderCostDetails(PartNumber, ItemMasterId, WorkScope, WorkScopeId, CurrencyName, Revenue, DirectCost, Margin, MarginPercentage, ApprovedStatus, WorkOrderId)

					SELECT 
						IM.partnumber AS PartNumber,
						WOP.ItemMasterId,
						WS.WorkScopeCode AS WorkScope,
						WS.WorkScopeId,
						C.Code AS CurrencyName,
						(ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) AS Revenue,
						(ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0)) AS DirectCost,
						(ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) -  (ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0)) As Margin,
						CASE WHEN (ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) > 0 
							 THEN (((ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) -  (ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0))) / (ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0))) * 100
						ELSE 0 END AS MarginPercentage,
						CASE WHEN UPPER(WOQS.Description) = 'APPROVED' THEN 'YES' ELSE 'NO' END AS ApprovedStatus,
						WO.WorkOrderId
					FROM dbo.WorkOrder WO WITH(NOLOCK) 
						JOIN dbo.WorkOrderQuote WOQ WITH(NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId
						JOIN dbo.WorkOrderQuoteDetails WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId AND WOQD.IsVersionIncrease = 0
						JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOQD.WOPartNoId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON WOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.WorkScope WS WITH (NOLOCK) ON WS.WorkScopeId = WOP.WorkOrderScopeId
						JOIN dbo.WorkOrderQuoteStatus WOQS WITH (NOLOCK) ON WOQS.WorkOrderQuoteStatusId = WOQ.QuoteStatusId 
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = WOQ.CurrencyId						
					WHERE IM.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, WOQ.createdDate, GETDATE()) < @Month 

					IF((SELECT COUNT(1) FROM #tmpWorkOrderCostDetails) > 0)
					BEGIN
						;WITH CTE AS(
							SELECT	SUM(ISNULL(WOC.Revenue, 0))/ COUNT(DISTINCT WorkOrderId) AS CalAvgRevenue,
									SUM(ISNULL(WOC.DirectCost, 0))/ COUNT(DISTINCT WorkOrderId) AS CalDirectCost,
									WOC.WorkScopeId,
									WOC.ItemMasterId, 
									WOC.CurrencyName
							FROM #tmpWorkOrderCostDetails WOC 
							GROUP BY WOC.WorkScopeId, WOC.ItemMasterId, WOC.CurrencyName
						)UPDATE #tmpWorkOrderCostDetails 
						SET AvgRevenue = CTE.CalAvgRevenue, DirectCost = CalDirectCost FROM CTE 
						WHERE #tmpWorkOrderCostDetails.WorkScopeId = CTE.WorkScopeId 
							AND #tmpWorkOrderCostDetails.ItemMasterId = CTE.ItemMasterId 
							AND #tmpWorkOrderCostDetails.CurrencyName = CTE.CurrencyName

						UPDATE #tmpWorkOrderCostDetails SET AvgMargin = ISNULL(AvgRevenue,0) - ISNULL(DirectCost, 0)
						UPDATE #tmpWorkOrderCostDetails SET MarginPercentage = (AvgMargin * 100) / AvgRevenue
						SELECT * FROM #tmpWorkOrderCostDetails
					END
					ELSE
					BEGIN
						SELECT * FROM #tmpWorkOrderCostDetails
					END

					IF OBJECT_ID(N'tempdb..#tmpWorkOrderCostDetails') IS NOT NULL
					BEGIN
					DROP TABLE #tmpWorkOrderCostDetails
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
              , @AdhocComments     VARCHAR(150)    = 'WorkOrderQuoteSummarizedHistoryByMPN' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@IsTwelveMonth AS VARCHAR(10)), '') + ''',
													   @Parameter2 = ' + ISNULL(@ItemMasterId ,'') +''
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