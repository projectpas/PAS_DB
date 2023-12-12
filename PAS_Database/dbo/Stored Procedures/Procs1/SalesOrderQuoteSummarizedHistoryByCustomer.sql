
/*************************************************************           
 ** File:   [SalesOrderQuoteSummarizedHistoryByCustomer]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used for SOQ Summarized History By Customer.    
 ** Purpose: This stored procedure is used for SOQ Summarized History.        
 ** Date:   07/13/2021        
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2021   Vishal Suthar Created
     
--EXEC [SalesOrderQuoteSummarizedHistoryByCustomer] 125, 1
**************************************************************/

CREATE PROCEDURE [dbo].[SalesOrderQuoteSummarizedHistoryByCustomer]
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
						SOQ.SalesOrderQuoteId,
						Cond.Description AS Condition,
						CASE WHEN ISNULL(APPR.ApprovalActionId, 0) = 5 THEN 1 ELSE 0 END AS CustApproved,
						C.Code AS CurrencyName,
						((ISNULL(SOQP.UnitSalePrice, 0) * ISNULL(SOQP.QtyQuoted, 0)) + ISNULL(SUM(Charges.BillingAmount), 0)) AS Revenue,
						((ISNULL(SOQP.UnitCost, 0) * ISNULL(SOQP.QtyQuoted, 0)) + ISNULL(SUM(Charges.BillingAmount), 0)) AS DirectCost,
						SOQ.SalesOrderQuoteNumber,
						SOQ.VersionNumber,
						SOQ.OpenDate AS SOQDate,
						SOQ.StatusName,
						CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
						WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
						WHEN sl.TraceableToType = 9 THEN leTraceble.Name
						WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
						ELSE
							''
						END AS TracableToName,
						CASE WHEN SO.SalesOrderNumber IS NULL THEN '' ELSE SO.SalesOrderNumber END AS SalesOrderNum,
						ISNULL(SO.SalesOrderId, 0) SalesOrderId
					FROM dbo.SalesOrderQuotePart SOQP WITH(NOLOCK)
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON SOQP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = SOQP.StockLineId
						LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
						LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
						LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
						LEFT JOIN dbo.SalesOrderQuoteApproval APPR WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = APPR.SalesOrderQuotePartId
						JOIN dbo.Condition Cond WITH(NOLOCK) ON SOQP.ConditionId = Cond.ConditionId
						LEFT JOIN dbo.SalesOrderQuoteCharges Charges WITH (NOLOCK) ON Charges.SalesOrderQuoteId = SOQ.SalesOrderQuoteId 
							AND Charges.ItemMasterId = SOQP.ItemMasterId AND Charges.IsDeleted = 0 AND Charges.IsActive = 1
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = SOQ.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
						LEFT JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						WHERE SOQP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, SOQ.OpenDate, GETDATE()) < @Month
						GROUP BY SOQ.CustomerName,
						SOQ.CustomerId,
						SOQ.SalesOrderQuoteId,
						Cond.Description, APPR.ApprovalActionId, C.Code, SOQP.UnitSalePrice, SOQP.QtyQuoted, SOQP.UnitCost,
						SOQ.SalesOrderQuoteNumber,
						SOQ.VersionNumber,
						SOQ.OpenDate, SO.SalesOrderNumber, SO.SalesOrderId,
						SOQ.StatusName, sl.TraceableToType, cusTraceble.Name, vTraceble.VendorName, leTraceble.Name, sl.TraceableTo
					)

					SELECT CustomerName, CustomerId, SalesOrderQuoteId, Condition, CustApproved, CurrencyName, SalesOrderQuoteNumber, VersionNumber, SOQDate, StatusName, Revenue AS Revenue,
					DirectCost AS DirectCost, (Revenue - DirectCost) AS Margin,
					CASE WHEN ISNULL(Revenue, 0) > 0 THEN CONVERT(DECIMAL(18,2), (ISNULL((Revenue - DirectCost), 0) / ISNULL(Revenue, 0)) * 100) ELSE 0 END AS MarginPercentage,
					TracableToName, SalesOrderNum, SalesOrderId
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