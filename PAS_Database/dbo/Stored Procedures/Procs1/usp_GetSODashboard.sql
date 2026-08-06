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
    1                 Swetha		Created
	2	        	  Swetha		Added Transaction & NO LOCK
	1	02/1/2024	  AMIT GHEDIYA	added isperforma Flage for SO
    2   11/05/2024	  Vishal Suthar	Modified to make use of new SO Part tables
	3   07-07-2025    Moin Bloch    Changed Old To New Billing Table
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5    24/July/2026			 RAJESH GAMI						[PN-17350] - Removed 1 leftover IsNonStock=0 exclusion filter added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filters no longer needed).
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
EXECUTE   [dbo].[usp_GetSODashboard] 
**************************************************************/

CREATE      PROCEDURE [dbo].[usp_GetSODashboard]
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION
	 
	 DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

      SELECT
        ((SOBI.GrandTotal)) AS SalesAmt,
        (C.Name) AS Customer,
        IM.partnumber AS Part,
        SOQ.SalesPersonName AS Salesperson,
        (SOPC.NetSaleAmount + SOMS.Misc) 'Revenue',
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
      INNER JOIN dbo.BillingInvoicing AS SOBI WITH (NOLOCK)
        ON SO.salesorderid = SOBI.ReferenceId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0 AND SOBI.[ModuleId] = @SOModuleId
        LEFT JOIN dbo.Customer AS C WITH (NOLOCK)
          ON SOBI.CustomerId = C.CustomerId
        LEFT OUTER JOIN dbo.SalesOrderQuote AS SOQ WITH (NOLOCK)
          ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT OUTER JOIN dbo.SalesOrderPartV1 AS SOP WITH (NOLOCK) ON SOBI.ReferenceId = SOP.SalesOrderId
        LEFT OUTER JOIN dbo.SalesOrderPartCost AS SOPC WITH (NOLOCK) ON SOPC.SalesOrderPartId = SOP.SalesOrderPartId
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