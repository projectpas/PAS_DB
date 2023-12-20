/*************************************************************           
 ** File:   [usp_GetSODashboardforunfulfilleddata]           
 ** Author:   Swetha  
 ** Description: Get Data for SODashboardforunfulfilleddata 
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
     
EXECUTE   [dbo].[usp_GetSODashboardforunfulfilleddata] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetSODashboardforunfulfilleddata]
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
        SOS.shipdate,
        CASE
          WHEN SOA.approvalactionid = 1 THEN 'sentforinternalapproval'
          WHEN SOA.approvalactionid = 2 THEN 'submitinternalapproval'
          WHEN SOA.approvalactionid = 3 THEN 'sentforcustomerapproval'
          WHEN SOA.approvalactionid = 4 THEN 'submitcustomerapproval'
          WHEN SOA.approvalactionid = 5 THEN 'approved'
        END AS Staus,
        SO.SalesOrderNumber,
        SO.OpenDate 'Open Date'
      FROM dbo.SalesOrder AS SO WITH (NOLOCK)
      LEFT JOIN dbo.SalesOrderBillingInvoicing AS SOBI WITH (NOLOCK)
        ON SO.salesorderid = SOBI.SalesOrderId
        LEFT JOIN dbo.Customer AS C WITH (NOLOCK)
          ON SOBI.CustomerId = C.CustomerId
        LEFT OUTER JOIN dbo.SalesOrderQuote AS SOQ WITH (NOLOCK)
          ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT OUTER JOIN dbo.SalesOrderPart AS SOP WITH (NOLOCK)
          ON SOP.SalesOrderId = SO.SalesOrderId
        LEFT OUTER JOIN dbo.ItemMaster AS IM WITH (NOLOCK)
          ON SOP.ItemMasterId = IM.ItemMasterId
        LEFT JOIN dbo.SOMarginSummary SOMS WITH (NOLOCK)
          ON SO.SalesOrderId = SOMS.SalesOrderId
        LEFT JOIN dbo.SalesOrderApproval SOA WITH (NOLOCK)
          ON SOP.SalesOrderPartId = SOA.SalesOrderPartId
        LEFT JOIN dbo.SalesOrderShippingItem SOSI WITH (NOLOCK)
          ON SOA.SalesOrderPartId = SOSI.SalesOrderPartId
        LEFT JOIN dbo.SalesOrderShipping SOS WITH (NOLOCK)
          ON SO.SalesOrderId = SOS.SalesOrderId

      WHERE SOA.ApprovalActionId = 5
    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetSODashboardforunfulfilleddata]',
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