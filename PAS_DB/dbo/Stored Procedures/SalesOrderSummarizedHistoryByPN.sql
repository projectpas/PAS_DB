
/*************************************************************           
 ** File:   [SalesOrderSummarizedHistoryByPN]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used for SO Summarized History By PN.    
 ** Purpose: This stored procedure is used for SO Summarized History.        
 ** Date:   07/12/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2021   Vishal Suthar Created
     
--EXEC [SalesOrderSummarizedHistoryByPN] 246,0
**************************************************************/

CREATE PROCEDURE [dbo].[SalesOrderSummarizedHistoryByPN]
@ItemMasterId BIGINT=3,
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

					;WITH summary AS 
					(SELECT 
						IM.partnumber AS PartNumber,
						SOP.ItemMasterId,
						Cond.Description AS Condition,
						Cond.ConditionId,
						C.Code AS CurrencyName,
						((ISNULL(SOP.UnitSalePrice, 0) * ISNULL(SOP.Qty, 0)) + ISNULL(Charges.BillingAmount, 0)) AS Revenue,
						((ISNULL(SOP.UnitCost, 0) * ISNULL(SOP.Qty, 0)) + ISNULL(Charges.BillingAmount, 0)) AS DirectCost
					FROM dbo.SalesOrderPart SOP WITH(NOLOCK)
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.SalesOrder SO WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
						JOIN dbo.Condition Cond WITH(NOLOCK) ON SOP.ConditionId = Cond.ConditionId
						LEFT JOIN dbo.SalesOrderCharges Charges WITH (NOLOCK) ON Charges.SalesOrderId = SO.SalesOrderId AND Charges.ItemMasterId = SOP.ItemMasterId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = SO.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
					WHERE SOP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, SO.OpenDate, GETDATE()) < @Month)

					SELECT PartNumber, ItemMasterId, Condition, CurrencyName, SUM(Revenue) AS Revenue,(SUM(ISNULL(Revenue,0))) / COUNT(ConditionId) AS AvgRevenue,
					--SUM(DirectCost) AS DirectCost,
					(SUM(ISNULL(DirectCost,0))) / COUNT(ConditionId) AS DirectCost,
					--(SUM(Revenue) - SUM(DirectCost)) AS Margin,
					((SUM(ISNULL(Revenue,0))) / COUNT(ConditionId) - (SUM(ISNULL(DirectCost,0))) / COUNT(ConditionId)) AS Margin,
					CASE WHEN SUM(ISNULL(Revenue, 0)) > 0 THEN CONVERT(DECIMAL(18,2), (ISNULL((SUM(Revenue) - SUM(DirectCost)), 0) * 100 ) / SUM(ISNULL(Revenue, 0))) ELSE 0 END AS MarginPercentage
					FROM summary
					GROUP BY partnumber, ItemMasterId, Condition, CurrencyName;
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SalesOrderSummarizedHistoryByPN' 
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