
/*************************************************************           
 ** File:   [usp_GetWorkOrderBillingReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderBillingReport
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1					Swetha		Created
	2	        		Swetha		Added Transaction & NO LOCK
	3	30-Nov-2021		Hemant		Updated Managment Structure Details and Date filter Condition
     
EXECUTE   [dbo].[usp_GetWorkOrderBillingReport] 'krunal','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,59','51,52,53'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetWorkOrderBillingReport] @name varchar(40) = NULL,
@Fromdate datetime = NULL,
@Todate datetime = NULL,
@mastercompanyid varchar(200),
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
      BEGIN
        DROP TABLE #managmetnstrcture
      END

      CREATE TABLE #managmetnstrcture (
        id bigint NOT NULL IDENTITY,
        managementstructureid bigint NULL,
      )

      IF (ISNULL(@Level4, '0') != '0'
        AND ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level4, ',')
      END
      ELSE
      IF  (ISNULL(@Level3, '0') != '0'
        AND ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level3, ',')

      END
      ELSE
      IF (ISNULL(@Level2, '0') != '0'
        AND ISNULL(@Level1, '0') != '0')
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level2, ',')
      END
      ELSE
      IF ISNULL(@Level1, '0') != '0'
      BEGIN
        INSERT INTO #managmetnstrcture (managementstructureid)
          SELECT
            item
          FROM dbo.[Splitstring](@Level1, ',')
      END

      SELECT DISTINCT
        UPPER(C.Name) 'Customer Name',
        UPPER(C.CustomerCode) 'Customer Code',
        UPPER(IM.partnumber) 'PN',
        UPPER(IM.PartDescription) 'PN Description',
        UPPER(RC.SerialNumber) 'Serial Num',
        UPPER(WS.WorkScopeCode) 'work scope',
        UPPER(WO.WorkOrderNum) 'WO Num',
        (WOPN.ReceivedDate) 'Received Date',
        (WO.OpenDate) 'WO Open Date',
        WOBI.InvoiceNo 'Invoice Num',
        WOBI.InvoiceDate 'InvoiceDate',
        WOBI.GrandTotal 'Revenue',
        UPPER(WOQ.QuoteNumber) 'Quote Num',
        WOQ.SentDate 'Quote Date',
        WOQ.ApprovedDate 'Quote Approval Date',
        WOS.ShipDate 'Ship Date',
        CASE
          WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RC.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RC.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RC.ReceivedDate)
          WHEN RC.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, RC.ReceivedDate, GETDATE())
        END AS 'TAT',
		UPPER(WOPN.Level1) AS LEVEL1,
		UPPER(WOPN.Level2) AS LEVEL2,
		UPPER(WOPN.Level3) AS LEVEL3,
		UPPER(WOPN.Level4) AS LEVEL4,        
        UPPER(E.FirstName + ' ' + E.LastName) 'Sales Person',
        UPPER(E1.FirstName + ' ' + E1.LastName) 'CSR'
      FROM DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
      LEFT JOIN DBO.WorkOrder WO WITH (NOLOCK)
        ON WOBI.WorkOrderId = WO.WorkOrderId
        JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK)
          ON WO.WorkOrderId = WOC.WorkOrderId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WOBI.WorkOrderPartNoId = WOPN.ID
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON WO.WorkOrderId = woq.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON woq.WorkOrderquoteid = WOQD.WorkOrderQuoteId
        LEFT JOIN DBO.WorkOrderType WITH (NOLOCK)
          ON WO.WorkOrderTypeId = WorkOrderType.Id
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.ReceivingCustomerWork RC WITH (NOLOCK)
          ON WO.WorkOrderId = RC.WorkOrderId
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON WOBI.CustomerId = C.CustomerId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOBI.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK)
          ON WO.WorkOrderId = WOS.WorkOrderId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON WO.SalesPersonId = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON WO.CsrId = E1.EmployeeId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOBI.ManagementStructureId
      WHERE C.Name IN (@name) OR @name = ' '
	  AND CAST(WOBI.invoicedate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
      AND WO.mastercompanyid = @mastercompanyid

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
    BEGIN
      DROP TABLE #managmetnstrcture
    END

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetWorkOrderBillingReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@name, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END