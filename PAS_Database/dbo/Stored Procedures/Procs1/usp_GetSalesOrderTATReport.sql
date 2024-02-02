
/*************************************************************           
 ** File:   [usp_GetSalesOrderTATReport]           
 ** Author:   Swetha  
 ** Description: Get Data for SalesOrderTAT Report 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha		Created
	2	        	  Swetha		Added Transaction & NO LOCK
	3	02/1/2024	  AMIT GHEDIYA	added isperforma Flage for SO
     
EXECUTE   [dbo].[usp_GetSalesOrderTATReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetSalesOrderTATReport] @customername varchar(40) = NULL,
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
        Customer.Name AS 'CustomerName',
        Customer.CustomerCode,
        ItemMaster.partnumber AS 'PN',
        ItemMaster.
        PartDescription AS 'PNDescription',
        CDTN.Description AS 'Condition',
        SO.SalesOrderNumber AS 'SO Num',
        '?' AS 'WO Num',
        SO.OpenDate AS ' OpenDate',
        SOA.customerapproveddate 'Apprv Date',
        SOP.EstimatedShipDate AS ' Ship Date',
        SOBI.InvoiceDate AS 'Invoice Date',
        DATEDIFF(DAY, SOA.customerapproveddate, SOP.estimatedshipdate) AS 'TAT',
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level1.code + '-' + level1.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS LEVEL1,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS LEVEL2,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS LEVEL3,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END
        AS LEVEL4,
        E.firstname + ' ' + E.lastname AS 'Sales Person'
      FROM dbo.salesorder AS SO WITH (NOLOCK)
      LEFT OUTER JOIN DBO.Customer WITH (NOLOCK)
        ON SO.CustomerId = Customer.CustomerId
        --LEFT OUTER JOIN DBO.WorkOrderPartNumber AS WOPN WITH(NOLOCK) ON WOPN.WorkOrderId = WOPN.ID 
        LEFT OUTER JOIN DBO.SalesOrderPart AS SOP WITH (NOLOCK)
          ON SO.SalesOrderId = SOP.SalesOrderId
        LEFT OUTER JOIN DBO.Stockline AS STL WITH (NOLOCK)
          ON SOP.StockLineId = STL.StockLineId
        --LEFT OUTER JOIN DBO.WorkOrder AS WO WITH(NOLOCK) ON STL.WorkOrderId = WO.WorkOrderId 
        LEFT OUTER JOIN DBO.ItemMaster WITH (NOLOCK)
          ON SOP.ItemMasterId = ItemMaster.ItemMasterId
        LEFT OUTER JOIN DBO.SalesOrderBillingInvoicing AS SOBI WITH (NOLOCK)
          ON SO.SalesOrderId = SOBI.SalesOrderId AND ISNULL(SOBI.IsProforma,0) = 0
        LEFT OUTER JOIN DBO.Condition AS CDTN WITH (NOLOCK)
          ON SOP.ConditionId = CDTN.ConditionId
        LEFT OUTER JOIN DBO.Employee AS E WITH (NOLOCK)
          ON SO.SalesPersonId = E.EmployeeId
        LEFT OUTER JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON SO.CustomerSeviceRepId = E1.EmployeeId
        --LEFT OUTER JOIN DBO.JobTitle AS JT WITH(NOLOCK) ON E.JobTitleId = JT.JobTitleId
        LEFT JOIN DBO.Salesorderapproval SOA WITH (NOLOCK)
          ON SO.salesorderid = SOA.salesorderid
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON SO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = SO.ManagementStructureId
        INNER JOIN DBO.ManagementStructure AS level4 WITH (NOLOCK)
          ON SO.ManagementStructureId = level4.ManagementStructureId
        LEFT OUTER JOIN DBO.ManagementStructure AS level3 WITH (NOLOCK)
          ON level4.ParentId = level3.ManagementStructureId
        LEFT OUTER JOIN DBO.ManagementStructure AS level2 WITH (NOLOCK)
          ON level3.ParentId = level2.ManagementStructureId
        LEFT OUTER JOIN DBO.ManagementStructure AS level1 WITH (NOLOCK)
          ON level2.ParentId = level1.ManagementStructureId

      WHERE (so.CustomerName IN (@customername)
      OR @customername = ' ')
      AND (SOP.estimatedshipdate BETWEEN @FromDate AND @ToDate)
      AND SO.mastercompanyid = @mastercompanyid

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
            @AdhocComments varchar(150) = '[usp_GetSalesOrderTATReport]',
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