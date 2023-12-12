
/*************************************************************           
 ** File:   [WorkOrderSummarizedHistoryByMPN]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Summarized History By MPN.    
 ** Purpose: This stored procedure is used WO Summarized History.        
 ** Date:   07/06/2021        
          
 ** PARAMETERS:           
 @@WorkOrderId BIGINT
 @WorkOrderPartNumberId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/06/2021   Hemant Saliya Created
     
--EXEC [WorkOrderSummarizedHistoryByMPN] 18,1
**************************************************************/

CREATE   PROCEDURE [dbo].[WorkOrderSummarizedHistoryByMPN]
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
						 RevenuePercentage DECIMAL(18,2) NULL,
						 TATDays INT NULL,
						 AvgRevenue DECIMAL(18,2) NULL,
						 WOCount INT NULL,
					)

					INSERT INTO #tmpWorkOrderCostDetails(PartNumber, ItemMasterId, WorkScope, WorkScopeId, CurrencyName, Revenue, DirectCost, Margin, RevenuePercentage, TATDays, WOCount)
					SELECT 
						IM.partnumber AS PartNumber,
						WOP.ItemMasterId,
						WOP.WorkScope,
						WOP.WorkOrderScopeId AS WorkScopeId,
						max(C.Code) AS CurrencyName,
						SUM(ISNULL(WC.Revenue, 0)) AS Revenue,
						SUM(ISNULL(WC.DirectCost, 0)) AS DirectCost,
						SUM(ISNULL(WC.Margin, 0)) AS Margin,
						CASE WHEN SUM(ISNULL(WC.Revenue, 0)) > 0 THEN CONVERT(DECIMAL(18,2),(SUM(ISNULL(WC.Margin, 0)) * 100 ) / SUM(ISNULL(WC.Revenue, 0))) ELSE 0 END AS RevenuePercentage,
						--SUM(ISNULL(WOP.TATDaysCurrent, 0)) As TATDays,
						sum(dbo.FN_GetTatCurrentDays(WOP.Id)) As TATDays,
						COUNT(WO.WorkOrderId)
					FROM dbo.WorkOrderCostDetails WC WITH(NOLOCK) 
						JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WC.WOPartNoId = WOP.ID
						LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WOP.ID AND WOP.WorkOrderStageId = WTT.CurrentStageId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON WOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = WO.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
					WHERE WOP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, WC.createdDate, GETDATE()) < @Month
					GROUP BY IM.partnumber, WOP.ItemMasterId, WOP.WorkScope, WOP.WorkOrderScopeId

					IF((SELECT COUNT(1) FROM #tmpWorkOrderCostDetails) > 0)
					BEGIN
						;WITH CTE AS(
							SELECT	SUM(ISNULL(WOC.Revenue, 0))/ WOCount AS CalAvgRevenue,
									SUM(ISNULL(WOC.DirectCost, 0))/ WOCount AS CalDirectCost,
									WOC.WorkScopeId,
									WOC.ItemMasterId, 
									Max(WOC.CurrencyName) as CurrencyName
							FROM #tmpWorkOrderCostDetails WOC 
							GROUP BY WOC.WorkScopeId, WOC.WOCount, WOC.ItemMasterId
						)UPDATE #tmpWorkOrderCostDetails 
						SET AvgRevenue = CTE.CalAvgRevenue, DirectCost = CalDirectCost FROM CTE 
						WHERE #tmpWorkOrderCostDetails.WorkScopeId = CTE.WorkScopeId 
							AND #tmpWorkOrderCostDetails.ItemMasterId = CTE.ItemMasterId 
							AND #tmpWorkOrderCostDetails.CurrencyName = CTE.CurrencyName

						SELECT * FROM #tmpWorkOrderCostDetails
					END
					ELSE
					BEGIN
						SELECT * FROM #tmpWorkOrderCostDetails
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
              , @AdhocComments     VARCHAR(150)    = 'WorkOrderSummarizedHistoryByMPN' 
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