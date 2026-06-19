/*************************************************************           
 ** File:   [SalesOrderQuoteSummarizedHistoryByPN]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used for SOQ Summarized History By PN.    
 ** Purpose: This stored procedure is used for SOQ Summarized History.        
 ** Date:   07/12/2021        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/12/2021   Vishal Suthar   Created
    2    11/04/2024   Vishal Suthar   Modified to make use of new tables
	3    16-Apr-026   Bhargav Saliya  UOM Changes
    4    18/06/2026   Bhargav Saliya	Added Case For Skip UOM Function If FROM uom and TO uom Both are Same
--EXEC [SalesOrderQuoteSummarizedHistoryByPN] 246,0
**************************************************************/

CREATE PROCEDURE [dbo].[SalesOrderQuoteSummarizedHistoryByPN]
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
						IM.partnumber AS PartNumber,
						SOQP.ItemMasterId,
						Cond.Description AS Condition,
						CASE WHEN ISNULL(APPR.ApprovalActionId, 0) = 5 THEN 1 ELSE 0 END AS CustApproved,
						C.Code AS CurrencyName,
						(
							(CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOQPC.UnitSalesPrice, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOQPC.UnitSalesPrice, 0),IM.[StockUnitOfMeasure],IM.[ConsumeUnitOfMeasure],1,SOQP.MasterCompanyId) END)
							* (CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOQP.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOQP.QtyQuoted, 0),IM.[StockUnitOfMeasure],IM.[ConsumeUnitOfMeasure],0,SOQP.MasterCompanyId) END)
						) + ISNULL(SUM(Charges.BillingAmount), 0) AS Revenue,
						(
							(CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOQPC.UnitCost, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOQPC.UnitCost, 0),IM.[StockUnitOfMeasure],IM.[ConsumeUnitOfMeasure],1,SOQP.MasterCompanyId) END)
							* (CASE WHEN IM.[StockUnitOfMeasure] = IM.[ConsumeUnitOfMeasure] THEN ISNULL(SOQP.QtyQuoted, 0) ELSE [dbo].[fn_ConvertUOM](ISNULL(SOQP.QtyQuoted, 0),IM.[StockUnitOfMeasure],IM.[ConsumeUnitOfMeasure],0,SOQP.MasterCompanyId) END)
						) + ISNULL(SUM(Charges.BillingAmount), 0) AS DirectCost
					FROM dbo.SalesOrderQuotePartV1 SOQP WITH(NOLOCK)
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON SOQP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.SalesOrderQuote SOQ WITH(NOLOCK) ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
						LEFT JOIN dbo.SalesOrderQuoteApproval APPR WITH(NOLOCK) ON SOQP.SalesOrderQuotePartId = APPR.SalesOrderQuotePartId
						JOIN dbo.Condition Cond WITH(NOLOCK) ON SOQP.ConditionId = Cond.ConditionId
						LEFT JOIN dbo.SalesOrderQuoteCharges Charges WITH (NOLOCK) ON Charges.SalesOrderQuoteId = SOQ.SalesOrderQuoteId 
							AND Charges.ItemMasterId = SOQP.ItemMasterId AND Charges.IsDeleted = 0 AND Charges.IsActive = 1
						LEFT JOIN dbo.CustomerFinancial CF WITH (NOLOCK) ON CF.CustomerId = SOQ.CustomerId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = CF.CurrencyId
						LEFT JOIN dbo.SalesOrderQuotePartCost SOQPC WITH (NOLOCK) ON SOQPC.SalesOrderQuotePartId = SOQP.SalesOrderQuotePartId
					WHERE SOQP.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, SOQ.OpenDate, GETDATE()) < @Month
					GROUP BY IM.partnumber, SOQP.ItemMasterId, Cond.Description, APPR.ApprovalActionId, C.Code,
					SOQPC.UnitSalesPrice, SOQP.QtyQuoted, SOQPC.UnitCost,IM.[ConsumeUnitOfMeasure],IM.[StockUnitOfMeasure],SOQP.MasterCompanyId
					)

					SELECT PartNumber, ItemMasterId, Condition, MIN(CustApproved) CustApproved, CurrencyName, SUM(Revenue) AS Revenue,
					SUM(DirectCost) AS DirectCost, (SUM(Revenue) - SUM(DirectCost)) AS Margin,
					CASE WHEN SUM(ISNULL(Revenue, 0)) > 0 THEN CONVERT(DECIMAL(18,2), (ISNULL((SUM(Revenue) - SUM(DirectCost)), 0) * 100 ) / SUM(ISNULL(Revenue, 0))) ELSE 0 END AS MarginPercentage
					FROM summary
					GROUP BY partnumber, ItemMasterId, Condition, CustApproved, CurrencyName;
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SalesOrderQuoteSummarizedHistoryByPN' 
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