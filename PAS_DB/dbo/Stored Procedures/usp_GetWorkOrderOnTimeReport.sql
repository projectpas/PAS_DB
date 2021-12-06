
/*************************************************************           
 ** File:   [usp_GetWorkOrderOnTimeReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderOnTime Report
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
	3	30-Nov-2021		Hemant		Updated Managment Structure Details and Date filter Condition
     
EXECUTE   [dbo].[usp_GetWorkOrderOnTimeReport] '','2020-04-25','2021-04-25','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
--select * from dbo.ManagementStructure WHERE ParentId in (1,4,43,44,45,80,84,88) 
--select * from dbo.ManagementStructure WHERE ParentId in (46,47,66) 
--select * from dbo.ManagementStructure WHERE ParentId in (48,49,50,58,59,67,68,69) 
CREATE PROCEDURE [dbo].[usp_GetWorkOrderOnTimeReport] @name varchar(40) = NULL,
@Fromdate datetime,
@Todate datetime,
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

      --select * FROM #ManagmetnStrcture
      SELECT DISTINCT
        (Customer.Name) 'Customer Name',
        Customer.CustomerCode 'CustomerCode',
        (IM.PartNumber) 'PN',
        (IM.PartDescription) 'PN Description',
        WS.WorkScopeCode 'Workscope',
        (CDTN.Description) 'Condition',
        WO.WorkOrderNum 'WO Num',
        WOPN.ReceivedDate 'Received Date',
        WOQ.sentDate 'Quote Date',
        WOQ.approveddate 'Approved Date',
        WOS.ShipDate 'Shipped Date ',
        WOPN.CustomerRequestDate 'Customer Request Date',
        WOPN.promiseddate 'Promise Date',
        WBI.InvoiceDate 'Invoice Date',
        (CASE
          WHEN WOS.ShipDate <= WOPN.PromisedDate THEN 'Yes'
          ELSE 'No'
        END) AS [PerformedonTime],
		WOPN.Level1 AS LEVEL1,
		WOPN.Level2 AS LEVEL2,
		WOPN.Level3 AS LEVEL3,
		WOPN.Level4 AS LEVEL4, 
        E.FirstName + ' ' + E.lastname 'Salesperson',
        E1.firstname + ' ' + E1.lastname 'CSR'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      LEFT JOIN DBO.Customer WITH (NOLOCK)
        ON WO.CustomerId = Customer.CustomerId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.itemmasterId
        LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
          ON WO.WorkOrderId = RCW.WorkOrderId
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.Condition CDTN WITH (NOLOCK)
          ON WOPN.ConditionId = CDTN.ConditionId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON WO.salespersonid = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON WO.csrid = E1.Employeeid
        LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK)
          ON WO.WorkOrderId = WBI.WorkOrderId and IsVersionIncrease=0
	    LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK)
          ON WOPN.ID = WOSI.WorkOrderPartNumId
        LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK)
          ON WOSI.WorkOrderShippingId = WOS.WorkOrderShippingId
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON WO.WorkOrderId = woq.WorkOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId
      WHERE CAST(WOS.ShipDate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
      AND (customer.name = @name OR @name = ' ')
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderOnTimeReport]',
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