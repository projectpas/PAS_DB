/*************************************************************           
 ** File:   [usp_GetMainSODashboardsample]           
 ** Author:   Swetha  
 ** Description: Get Data for MainSODashboard sample 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha Created
	2	        	  Swetha Added Transaction & NO LOCK
	3   16-OCT-2024	  Abhishek Jirawla	Implemented the new tables for SalesOrderQuotePart related tables
     
EXECUTE   [dbo].[usp_GetMainSODashboardsample] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetMainSODashboardsample]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      SELECT
        SOP.EstimatedShipDate 'SALE DATE',
        SOPC.NetSaleAmount + SOMS.misc AS PartsSaleBilling,
        SOQ.StatusName
      FROM dbo.SalesOrder AS SO WITH (NOLOCK)
      LEFT JOIN dbo.SalesOrderQuote AS SOQ WITH (NOLOCK)
        ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT JOIN dbo.SalesOrderPartV1 AS SOP WITH (NOLOCK)
          ON SO.SalesOrderId = SOP.SalesOrderId
        LEFT OUTER JOIN dbo.SalesOrderQuotePartV1 SOQP WITH (NOLOCK)
          ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
		LEFT JOIN SalesOrderPartCost SOPC WITH (NOLOCK) 
			ON SOPC.SalesOrderPartId=SOP.SalesOrderPartId and SOPC.IsDeleted=0
        LEFT JOIN dbo.SOMarginSummary SOMS WITH (NOLOCK)
          ON SO.SalesOrderId = SOMS.SalesOrderId
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetMainSODashboardsample]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END