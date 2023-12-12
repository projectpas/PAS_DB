
/*************************************************************           
 ** File:   [usp_GetRCWReport]           
 ** Author:   Swetha  
 ** Description: Get Data for RCW Report 
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
     
--EXECUTE   [dbo].[usp_GetRCWReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetRCWReport] @customername varchar(40) = NULL,
@Fromdate datetime,
@Todate datetime,
@mastercompanyid int,
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
        UPPER(RCW.customerName) 'Customer Name',
        UPPER(RCW.CustomerCode) 'Customer Code',
        UPPER(RCW.ReceivingNumber) 'Receiver Num',
        UPPER(IM.partnumber) 'PN',
        UPPER(IM.PartDescription) 'PN Description',
        UPPER(RCW.SerialNumber) 'Serial Num',
        UPPER(WS.WorkScopeCode) 'work scope',
        CONVERT(date, RCW.ReceivedDate, 101) 'Received Date',
        UPPER(WO.WorkOrderNum) 'WO Num',
        CONVERT(date, WO.OpenDate, 101) 'WO Open Date',
        UPPER(WOS.code + '-' + stage) 'Stage Code',
        UPPER(WOSS.Description) 'Status',
        WOPN.NTE 'NTE',
        WOQD.MaterialRevenue + WOQD.LaborRevenue + WOQD.ChargesRevenue + WOQD.FreightRevenue 'Estimated Revenue',
        UPPER(WOT.Description) 'WO Type',
        UPPER(E1.FirstName + ' ' + E1.LastName) 'Sales Person',
        UPPER(E2.FirstName + ' ' + E2.LastName) 'CSR',
        UPPER(RCW.level1) 'LEVEL1',
        UPPER(RCW.level2) 'LEVEL2',
        UPPER(RCW.level3) 'LEVEL3',
        UPPER(RCW.level4) 'LEVEL4'
      FROM DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
      LEFT JOIN DBO.Customer C WITH (NOLOCK)
        ON RCW.CustomerId = C.CustomerId
        LEFT JOIN DBO.WorkOrder AS WO WITH (NOLOCK)
          ON RCW.WorkOrderId = WO.WorkOrderId
        LEFT JOIN DBO.WorkOrderPartNumber AS WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK)
          ON WO.WorkOrderId = WOQ.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON WOQ.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
        JOIN DBO.ItemMaster AS IM WITH (NOLOCK)
          ON RCW.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkOrderStage AS WOS WITH (NOLOCK)
          ON WOPN.WorkOrderStageId = WOS.WorkOrderStageId
        LEFT JOIN DBO.WorkOrderStatus AS WOSS WITH (NOLOCK)
          ON WO.WorkOrderStatusId = WOSS.Id
        LEFT JOIN DBO.WorkOrderType AS WOT WITH (NOLOCK)
          ON WO.WorkOrderTypeId = WOT.Id
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON RCW.WorkScopeId = WS.WorkScopeId
        LEFT JOIN DBO.Workflow AS WF WITH (NOLOCK)
          ON WOPN.WorkflowId = WF.WorkflowId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON RCW.EmployeeId = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON WO.SalesPersonId = E1.EmployeeId
        LEFT JOIN DBO.Employee AS E2 WITH (NOLOCK)
          ON WO.CsrId = E2.EmployeeId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON RCW.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = RCW.ManagementStructureId

      WHERE CAST(RCW.receiveddate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
      AND RCW.CustomerName IN (@customername)
      OR @customername = ' '
      AND RCW.mastercompanyid = @mastercompanyid

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
            @AdhocComments varchar(150) = '[usp_GetRCWReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@customername, '') AS varchar(100)) +
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