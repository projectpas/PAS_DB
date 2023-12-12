/*************************************************************           
 ** File:   [usp_GetSODashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for SODashboard 
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
     
EXECUTE   [dbo].[usp_GetSODashboard] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetSODashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
      SELECT
        ((SOBI.GrandTotal)) AS SalesAmt,
        (C.Name) AS Customer,
        IM.partnumber AS Part,
        SOQ.SalesPersonName AS Salesperson,
        (SOP.netsales + SOMS.Misc) 'Revenue',
        SOBI.InvoiceDate,
        SO.OpenDate,
        SOA.customerapproveddate,
        CASE
          WHEN SO.statusid = 1 THEN 'open'
          WHEN SO.StatusId = 2 THEN 'closed'
          WHEN SO.StatusId = 3 THEN 'sent'
          WHEN SO.StatusId = 4 THEN 'Approved'
          WHEN SO.StatusId = 5 THEN 'Cancelled'
          WHEN SO.StatusId = 6 THEN 'Expired'
          WHEN SO.StatusId = 7 THEN 'PartiallyApproved'
          WHEN SO.StatusId = 8 THEN 'Pending'
          WHEN SO.StatusId = 9 THEN 'Rejected'
        END AS 'Status'
      FROM dbo.SalesOrder AS SO WITH (NOLOCK)
      INNER JOIN dbo.SalesOrderBillingInvoicing AS SOBI WITH (NOLOCK)
        ON SO.salesorderid = SOBI.SalesOrderId
        LEFT JOIN dbo.Customer AS C WITH (NOLOCK)
          ON SOBI.CustomerId = C.CustomerId
        LEFT OUTER JOIN dbo.SalesOrderQuote AS SOQ WITH (NOLOCK)
          ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT OUTER JOIN dbo.SalesOrderPart AS SOP WITH (NOLOCK)
          ON SOBI.SalesOrderId = SOP.SalesOrderId
        LEFT OUTER JOIN dbo.ItemMaster AS IM WITH (NOLOCK)
          ON SOP.ItemMasterId = IM.ItemMasterId
        LEFT JOIN dbo.SOMarginSummary SOMS WITH (NOLOCK)
          ON SO.SalesOrderId = SOMS.SalesOrderId
        LEFT JOIN dbo.SalesOrderApproval SOA WITH (NOLOCK)
          ON SO.SalesOrderId = SOA.SalesOrderId

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetSODashboard]',
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