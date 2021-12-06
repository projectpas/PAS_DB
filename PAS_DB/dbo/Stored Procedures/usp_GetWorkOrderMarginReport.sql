
/*************************************************************           
 ** File:   [usp_GetWorkOrderMarginReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderMargin Report
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
     
EXECUTE   [dbo].[usp_GetWorkOrderMarginReport] '128','','','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,59','51,52,53'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetWorkOrderMarginReport] @name varchar(40) = NULL,
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

      --select * FROM #ManagmetnStrctureselect distinct
      SELECT DISTINCT
        (C.Name) 'Customer Name',
        C.CustomerCode 'Customer Code',
        (IM.partnumber) 'PN',
        (IM.PartDescription) 'PN Description',
        RC.SerialNumber 'Serial Num',
        WS.WorkScopeCode 'work scope',
        WO.WorkOrderNum 'WO Num',
        CONVERT(varchar, WOPN.ReceivedDate, 101) 'Received Date',
        CONVERT(varchar, WO.OpenDate, 101) 'WO Open Date',
        WOBI.InvoiceNo 'Invoice Num',
        CONVERT(varchar, WOBI.InvoiceDate, 101) 'InvoiceDate',
        WOQ.QuoteNumber 'Quote Num',
        CONVERT(varchar, WOQ.SentDate, 101) 'Quote Date',
        CONVERT(varchar, WOQ.ApprovedDate, 101) 'Quote Approval Date',
        CONVERT(varchar, WOS.ShipDate, 101) 'Ship Date',
        WOBI.GrandTotal 'Revenue',
        WOC.PartsCost 'Parts Cost',
        WOC.PartsCost / WOBI.GrandTotal 'Parts rev %',
        WOC.LaborCost 'LaborCost',
        WOC.LaborCost / WOBI.GrandTotal 'Labor rev %',
        WOC.OverHeadCost 'OH Cost',
        WOC.OverHeadCost / WOBI.GrandTotal 'OH Cost %',
        WOC.DirectCost 'Direct Cost',
        WOC.DirectCost / WOBI.GrandTotal 'DC of Rev%',
        WOBI.GrandTotal - WOC.DirectCost 'Margin',
        (WOBI.GrandTotal - WOC.DirectCost) / WOBI.GrandTotal 'GM of Rev%',
        CASE
          WHEN WOS.ShipDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, RC.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN ApprovedDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, Rc.ReceivedDate) - DATEDIFF(DAY, ApprovedDate, SentDate) + DATEDIFF(DAY, WOS.ShipDate, ApprovedDate)
          WHEN SentDate IS NOT NULL THEN DATEDIFF(DAY, SentDate, Rc.ReceivedDate)
          WHEN RC.ReceivedDate IS NOT NULL THEN DATEDIFF(DAY, Rc.ReceivedDate, GETDATE())
        END AS 'TAT',
		WOPN.Level1 AS LEVEL1,
		WOPN.Level2 AS LEVEL2,
		WOPN.Level3 AS LEVEL3,
		WOPN.Level4 AS LEVEL4, 
        E.firstname + ' ' + E.lastname 'Sales Person',
        E1.firstname + ' ' + E1.lastname 'CSR'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      JOIN DBO.WorkOrderMPNCostDetails WOC WITH (NOLOCK)
        ON WO.WorkOrderId = WOC.WorkOrderId
        LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
          ON WO.WorkOrderId = WOBI.WorkOrderId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WOBI.WorkOrderPartNoId = WOPN.Id
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderMarginReport]',
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