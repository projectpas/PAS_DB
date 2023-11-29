

/*************************************************************           
 ** File:   [WorkOrderSummarizedHistoryByCustomer]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Summarized History By Customer.    
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
     
--EXEC [WorkOrderSummarizedHistoryByCustomer] 240,1
**************************************************************/

CREATE   PROCEDURE [dbo].[WorkOrderSummarizedHistoryByCustomer]
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

					SELECT 
						WO.CustomerName,
						WO.WorkOrderNum,
						WO.WorkOrderId,
						WO.OpenDate,
						WOP.WorkScope,
						WOP.WorkOrderScopeId AS WorkScopeId,
						C.Code AS CurrencyName,
						WOSG.Code + '-' + WOSG.Stage AS  Stage,
						WOS.Description AS WorkOrderStatus,
						SUM(ISNULL(WC.Revenue, 0)) AS Revenue,
						SUM(ISNULL(WC.DirectCost, 0)) AS DirectCost,
						SUM(ISNULL(WC.Margin, 0)) AS Margin,
						CASE WHEN SUM(ISNULL(WC.Revenue, 0)) > 0 THEN CONVERT(DECIMAL(18,2),(SUM(ISNULL(WC.Margin, 0)) * 100 ) / SUM(ISNULL(WC.Revenue, 0))) ELSE 0 END AS RevenuePercentage,
						sum(dbo.FN_GetTatCurrentDays(WOP.Id)) As TATDays
					FROM dbo.WorkOrderCostDetails WC WITH(NOLOCK) 
						JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WC.WOPartNoId = WOP.ID
						LEFT JOIN dbo.WorkOrderTurnArroundTime WTT WITH(NOLOCK) ON WTT.WorkOrderPartNoId = WOP.ID AND WOP.WorkOrderStageId = WTT.CurrentStageId
						JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WC.WorkOrderId
						JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WOP.WorkOrderStageId = WOSG.WorkOrderStageId	
						JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WO.WorkOrderStatusId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = WO.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
					WHERE WOP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, WC.createdDate, GETDATE()) < @Month
					GROUP BY WO.CustomerName,WO.WorkOrderNum, WO.WorkOrderId, WO.OpenDate, WOP.WorkScope, WOP.WorkOrderScopeId,C.Code, WOS.Description, WOSG.Code + '-' + WOSG.Stage
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'WOSummarizedHistoryByCustomer' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''',
													   @Parameter2 = ' + ISNULL(CAST(@IsTwelveMonth AS VARCHAR(10)) ,'') +''
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