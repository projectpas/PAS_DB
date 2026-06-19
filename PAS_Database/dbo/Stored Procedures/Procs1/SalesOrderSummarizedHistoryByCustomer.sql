/*************************************************************           
 ** File:   [SalesOrderSummarizedHistoryByCustomer]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used for SOQ Summarized History By Customer.    
 ** Purpose: This stored procedure is used for SOQ Summarized History.        
 ** Date:   07/13/2021        
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    07/13/2021		Vishal Suthar	Created
    2	 11/04/2024		Vishal Suthar	Modified to make use of new SO Part tables
	3	 01/05/2026	  Moin Bloch	Modified Added UOM changes
	4    07/01/2026   Rajesh Gami		Added MasterCompanyId Parameter While Calling UOM Conversion Function
	5    14/05/2026   Bhargav Saliya		Modified UOM Changes [PN-15067]
	6    18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same

--EXEC [SalesOrderSummarizedHistoryByCustomer] 115640, 1
**************************************************************/
CREATE      PROCEDURE [dbo].[SalesOrderSummarizedHistoryByCustomer]
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
						Cust.Name AS CustomerName,
						SO.CustomerId,
						SO.SalesOrderId,
						Cond.Description AS Condition,
						0 AS CustApproved,
						C.Code AS CurrencyName,
						--((ISNULL(SOPC.NetSaleAmount, 0)) + ISNULL(Charges.BillingAmount, 0)) AS Revenue,
						ISNULL((CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOPC.NetSaleAmount, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOPC.NetSaleAmount, 0),IM.[StockUnitOfMeasure], IM.[ConsumeUnitOfMeasure],1,SOP.MasterCompanyId) END) + ISNULL(Charges.BillingAmount, 0),0) AS Revenue,
						--((ISNULL(SOPC.UnitCost, 0) * ISNULL(SOP.QtyOrder, 0)) + ISNULL(Charges.BillingAmount, 0)) AS DirectCost,
						ISNULL((CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOPC.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOPC.UnitCost, 0),IM.[StockUnitOfMeasure], IM.[ConsumeUnitOfMeasure],1,SOP.MasterCompanyId) END) * (CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOP.[QtyOrder],0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOP.[QtyOrder],0),IM.[StockUnitOfMeasure], IM.[ConsumeUnitOfMeasure],0,SOP.MasterCompanyId) END),0) + ISNULL(Charges.BillingAmount, 0) AS DirectCost,										
						SO.SalesOrderNumber,
						SOQ.SalesOrderQuoteNumber,
						SO.VersionNumber,
						SO.OpenDate AS SODate,
						St.Description AS StatusName,
						CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
						WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
						WHEN sl.TraceableToType = 9 THEN leTraceble.Name
						WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
						ELSE
							''
						END AS TracableToName
					FROM dbo.SalesOrderPartV1 SOP WITH(NOLOCK)
						LEFT JOIN dbo.SalesOrderStocklineV1 STK WITH(NOLOCK) ON STK.SalesOrderPartId = SOP.SalesOrderPartId
						LEFT JOIN dbo.SalesOrderPartCost SOPC WITH(NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON SOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.SalesOrder SO WITH(NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId
						LEFT JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
						JOIN dbo.Condition Cond WITH(NOLOCK) ON SOP.ConditionId = Cond.ConditionId
						LEFT JOIN dbo.SalesOrderCharges Charges WITH (NOLOCK) ON Charges.SalesOrderId = SO.SalesOrderId AND Charges.ItemMasterId = SOP.ItemMasterId
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = SO.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
						LEFT JOIN dbo.Customer Cust WITH (NOLOCK) ON Cust.CustomerId = SO.CustomerId
						LEFT JOIN dbo.MasterSalesOrderStatus St WITH (NOLOCK) ON St.Id = SO.StatusId
						LEFT JOIN dbo.Stockline SL WITH (NOLOCK) ON SL.StockLineId = STK.StockLineId
						LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
						LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
						LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
					WHERE SOP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, SO.OpenDate, GETDATE()) < @Month)

					SELECT CustomerName, CustomerId, SalesOrderId, Condition, CustApproved, CurrencyName, SalesOrderNumber, SalesOrderQuoteNumber,
					VersionNumber, SODate, StatusName, Revenue AS Revenue,DirectCost AS DirectCost, (Revenue - DirectCost) AS Margin,
					CASE WHEN ISNULL(Revenue, 0) > 0 THEN CONVERT(DECIMAL(18,2), (ISNULL((Revenue - DirectCost), 0) / ISNULL(Revenue, 0)) * 100) ELSE 0 END AS MarginPercentage,
					TracableToName
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
              , @AdhocComments     VARCHAR(150)    = 'SalesOrderSummarizedHistoryByCustomer' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(CAST(@ItemMasterId AS VARCHAR(100)) ,'') +''',
													   @Parameter2 = ' + ISNULL(CAST(@IsTwelveMonth AS VARCHAR(100)) ,'') +''
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