
/*************************************************************           
 ** File:   [WOSummarizedHistory]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Summarized History.    
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
     
--EXEC [WOSummarizedHistory] 378,369,1
**************************************************************/

CREATE PROCEDURE [dbo].[WOSummarizedHistory]
@WorkOrderId BIGINT,
@WorkOrderPartNumberId BIGINT,
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
						IM.partnumber AS PartNumber,
						WOP.ItemMasterId,
						WOP.WorkScope,
						WOP.WorkOrderScopeId,
						C.Code AS CurrencyName,
						SUM(ISNULL(WC.Revenue, 0)) AS Revenue,
						SUM(ISNULL(WC.DirectCost, 0)) AS DirectCost,
						SUM(ISNULL(WC.Margin, 0)) AS Margin,
						CASE WHEN SUM(ISNULL(WC.Revenue, 0)) > 0 THEN CONVERT(DECIMAL(18,2),(SUM(ISNULL(WC.Margin, 0)) * 100 ) / SUM(ISNULL(WC.Revenue, 0))) ELSE 0 END AS RevenuePercentage
						--WOP.TATDaysCurrent,
						--WOP.TATDaysStandard
					FROM dbo.WorkOrderCostDetails WC WITH(NOLOCK) 
						JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WC.WOPartNoId = WOP.ID
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON WOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.WorkOrder WO WITH(NOLOCK) ON WO.WorkOrderId = WC.WorkOrderId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = WO.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
					WHERE WC.WorkOrderId = @WorkOrderId AND WC.WOPartNoId = @WorkOrderPartNumberId AND DATEDIFF(MM, WC.createdDate, GETDATE()) < @Month
					GROUP BY IM.partnumber, WOP.ItemMasterId, WOP.WorkScope, WOP.WorkOrderScopeId,C.Code
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'WOSummarizedHistory' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''',
													   @Parameter2 = ' + ISNULL(@WorkOrderPartNumberId ,'') +''
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