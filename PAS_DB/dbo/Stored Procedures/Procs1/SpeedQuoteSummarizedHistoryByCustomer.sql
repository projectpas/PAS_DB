
/*************************************************************           
 ** File:   [SpeedQuoteSummarizedHistoryByCustomer]           
 ** Author:   Deep Patel
 ** Description: This stored procedure is used for SQ Summarized History By Customer.    
 ** Purpose: This stored procedure is used for SQ Summarized History.        
 ** Date:   07/27/2021
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/27/2021   Deep Patel Created
     
--EXEC [SpeedQuoteSummarizedHistoryByCustomer] 125, 1
**************************************************************/

CREATE PROCEDURE [dbo].[SpeedQuoteSummarizedHistoryByCustomer]
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

					;WITH summary AS 
					(SELECT 
						SOQ.CustomerName,
						SOQ.CustomerId,
						SOQ.SpeedQuoteId,
						0 as CustApproved,
						Cond.Description AS Condition,
						C.Code AS CurrencyName,
						((ISNULL(SOQP.UnitSalePrice, 0) * ISNULL(SOQP.QuantityRequested, 0))) AS Revenue,
						((ISNULL(SOQP.UnitCost, 0) * ISNULL(SOQP.QuantityRequested, 0))) AS DirectCost,
						SOQ.SpeedQuoteNumber,
						SOQ.VersionNumber,
						SOQ.OpenDate AS SOQDate,
						SOQ.StatusName,
						SOQP.TAT
					FROM dbo.SpeedQuotePart SOQP WITH(NOLOCK)
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON SOQP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.SpeedQuote SOQ WITH(NOLOCK) ON SOQ.SpeedQuoteId = SOQP.SpeedQuoteId
						JOIN dbo.Condition Cond WITH(NOLOCK) ON SOQP.ConditionId = Cond.ConditionId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = SOQ.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
					WHERE SOQP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, SOQ.OpenDate, GETDATE()) < @Month)

					SELECT CustomerName, CustomerId, SpeedQuoteId, Condition, CustApproved, CurrencyName, SpeedQuoteNumber, VersionNumber, SOQDate, StatusName, Revenue AS Revenue,
					DirectCost AS DirectCost, (Revenue - DirectCost) AS Margin,TAT,
					CASE WHEN ISNULL(Revenue, 0) > 0 THEN CONVERT(DECIMAL(18,2), (ISNULL((Revenue - DirectCost), 0) / ISNULL(Revenue, 0)) * 100) ELSE 0 END AS MarginPercentage
					FROM summary

				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SpeedQuoteSummarizedHistoryByCustomer' 
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