
/*************************************************************           
 ** File:   [usp_GetSalesOrderOnTimeReport]           
 ** Author:   Swetha  
 ** Description: Get Data for SalesOrderOnTime Report 
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
     
EXECUTE   [dbo].[usp_GetSalesOrderOnTimeReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetSalesOrderOnTimeReport] @customername varchar(40) = NULL,
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
        customer.NAME AS 'CustomerName',
        customer.customercode,
        itemmaster.partnumber AS 'PN',
        itemmaster.partdescription AS 'PNDescription',
        CDTN.description AS 'Condition',
        SO.salesordernumber AS 'SO Num',
        '?' 'WO Num',
        SO.opendate AS ' OpenDate',
        SOP.customerrequestdate AS 'Cust Request Date',
        SOP.promiseddate AS 'Promised Date',
        SOP.estimatedshipdate AS ' Ship Date',
        SOBI.invoicedate AS 'Invoice Date',
        (CASE
          WHEN SOP.estimatedshipdate <= SOP.promiseddate THEN 'YES'
          ELSE 'NO'
        END) AS [Performed on Time],

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
        END AS LEVEL1,
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
        END AS LEVEL2,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL3,
        CASE
          WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
            level3.code + '-' + level3.NAME IS NOT NULL AND
            level2.code + '-' + level2.NAME IS NOT NULL AND
            level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
          ELSE ''
        END AS LEVEL4,
        E.firstname + ' ' + E.lastname AS 'Sales Person',
        E1.firstname + ' ' + E1.lastname AS 'CSR'
      FROM dbo.salesorder AS SO WITH (NOLOCK)
      LEFT OUTER JOIN dbo.customer WITH (NOLOCK)
        ON SO.customerid = customer.customerid
        LEFT OUTER JOIN dbo.salesorderpart AS SOP WITH (NOLOCK)
          ON SO.salesorderid = SOP.salesorderid
        LEFT OUTER JOIN dbo.stockline AS STL WITH (NOLOCK)
          ON SOP.stocklineid = STL.stocklineid and STL.IsParent=1
        --LEFT OUTER JOIN DBO.WorkOrder AS WO WITH(NOLOCK) ON STl.WorkOrderId = WO.WorkOrderId           
        LEFT OUTER JOIN dbo.itemmaster WITH (NOLOCK)
          ON SOP.itemmasterid = itemmaster.itemmasterid
        LEFT OUTER JOIN dbo.salesorderbillinginvoicing AS SOBI WITH (NOLOCK)
          ON SO.salesorderid = SOBI.salesorderid
        LEFT OUTER JOIN dbo.condition AS CDTN WITH (NOLOCK)
          ON SOP.conditionid = CDTN.conditionid
        LEFT OUTER JOIN dbo.employee AS E WITH (NOLOCK)
          ON SO.salespersonid = E.employeeid
        LEFT OUTER JOIN dbo.employee AS E1 WITH (NOLOCK)
          ON SO.customersevicerepid = E1.employeeid
        LEFT JOIN dbo.salesordershipping SOS WITH (NOLOCK)
          ON SO.salesorderid = SOS.salesorderid
        LEFT OUTER JOIN dbo.mastercompany MC WITH (NOLOCK)
          ON SO.mastercompanyid = MC.mastercompanyid
        INNER JOIN #managmetnstrcture MS WITH (NOLOCK)
          ON MS.managementstructureid = SO.managementstructureid
        INNER JOIN dbo.managementstructure AS level4 WITH (NOLOCK)
          ON SO.managementstructureid = level4.managementstructureid
        LEFT OUTER JOIN dbo.managementstructure AS level3 WITH (NOLOCK)
          ON level4.parentid = level3.managementstructureid
        LEFT OUTER JOIN dbo.managementstructure AS level2 WITH (NOLOCK)
          ON level3.parentid = level2.managementstructureid
        LEFT OUTER JOIN dbo.managementstructure AS level1 WITH (NOLOCK)
          ON level2.parentid = level1.managementstructureid
      WHERE so.CustomerName IN (@customername)
      OR @customername = ' '
      AND SOP.estimatedshipdate BETWEEN @FromDate AND @ToDate
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
            @AdhocComments varchar(150) = '[usp_GetSalesOrderOnTimeReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@customername, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR (
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
    , 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH

  IF OBJECT_ID(N'tempdb..#ManagmetnStrcture') IS NOT NULL
  BEGIN
    DROP TABLE #managmetnstrcture
  END
END