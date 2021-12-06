
/*************************************************************           
 ** File:   [usp_GetWorkOrderTATReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderTAT Report
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
     
EXECUTE   [dbo].[usp_GetWorkOrderTATReport] '','2020-04-25','2021-04-25','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
--EXEC usp_GetWorkOrderTATReport  '1,4,43,44,45,80,84,88','46,47','58,59','64,65,77'
CREATE PROCEDURE [dbo].[usp_GetWorkOrderTATReport] @name varchar(40) = NULL,
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
        (Customer.Name) 'Customer Name',
        Customer.CustomerCode 'CustomerCode',
        (IM.PartNumber) 'PN',
        (IM.PartDescription) 'PN Description',
        WOPN.Quantity 'Qty',
        WS.WorkScopeCode 'Workscope',
        (CDTN.Description) 'Condition',
        WO.WorkOrderNum 'WO Num',
        WOPN.ReceivedDate 'Received Date',
        WO.opendate 'Open Date',
        WOQ.sentDate 'Quote Date',
        (DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate)) 'Days to Qte',
        WOQ.approveddate 'Approved Date',
        DATEDIFF(DAY, WOQ.sentDate, WOQ.approveddate) 'Days to Appv',
        WOPN.EstimatedShipDate 'Shipped Date ',
        DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) 'Days to Ship',
        DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) + DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) 'TAT',
        WBI.InvoiceDate 'Invoice Date',
		WOPN.Level1 AS LEVEL1,
		WOPN.Level2 AS LEVEL2,
		WOPN.Level3 AS LEVEL3,
		WOPN.Level4 AS LEVEL4,
        E.FirstName + ' ' + E.LastName 'Tech'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      LEFT JOIN DBO.Customer WITH (NOLOCK)
        ON WO.CustomerId = Customer.CustomerId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.itemmasterId
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.Condition CDTN WITH (NOLOCK)
          ON WOPN.ConditionId = CDTN.ConditionId
        LEFT JOIN DBO.Employee E WITH (NOLOCK)
          ON WOPN.TechnicianId = E.EmployeeId
        LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK)
          ON WO.WorkOrderId = WBI.WorkOrderId and IsVersionIncrease=0
        LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK)
          ON WO.WorkOrderId = WOS.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON WO.WorkOrderId = woq.WorkOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId

      WHERE customer.name IN (@name) OR @name = ' '
      AND CAST(WOPN.estimatedshipdate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderTATReport]',
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