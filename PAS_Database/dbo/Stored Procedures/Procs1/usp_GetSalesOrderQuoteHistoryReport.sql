
/*************************************************************           
 ** File:   [usp_GetSalesOrderQuoteHistoryReport]           
 ** Author:   Swetha  
 ** Description: Get Data for SalesOrderQuote History Report 
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
     
EXECUTE   [dbo].[usp_GetSalesOrderQuoteHistoryReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetSalesOrderQuoteHistoryReport] @customername varchar(40) = NULL,
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
        SOQP.partnumber 'PN',
        SOQP.partdescription 'PNDescription',
        SOQ.customername 'Acct Name',
        SOQ.customercode 'Acct Code',
        CT.description 'Acct Type',
        SOQP.conditionname 'Condition',
        SOQ.salesorderquotenumber 'SO Quote Num',
        SOQ.statusname 'QuoteStatus',
        ((ISNULL(SOQP.UnitSalePrice, 0) * ISNULL(SOQP.QtyQuoted, 0)) + ISNULL(Charges.BillingAmount, 0)) AS 'Quote Amount',
        E.firstname + ' ' + E.lastname 'Sales Person',
        CONVERT(varchar, SOQ.opendate, 101) 'QuoteDate',
        SOQ.leadsourcename 'Lead Source',
        E.firstname + ' ' + E.lastname 'Employee',
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
        END AS LEVEL4

      FROM DBO.SalesOrderQuote SOQ WITH (NOLOCK)
      LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK)
        ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK)
          ON SO.SalesOrderId = SOP.SalesOrderId
        LEFT JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
          ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON SOQP.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON SOQP.stocklineId = STL.StockLineId
        LEFT JOIN DBO.CustomerType CT WITH (NOLOCK)
          ON SOQ.AccountTypeId = CT.CustomerTypeId
        --LEFT JOIN DBO.SalesOrderBillingInvoicing SOBI WITH(NOLOCK) ON SO.SalesOrderId=SOBI.SalesOrderId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON SOQ.EmployeeId = E.EmployeeId
        LEFT JOIN dbo.SalesOrderQuoteCharges Charges WITH (NOLOCK)
          ON Charges.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
          AND Charges.ItemMasterId = SOQP.ItemMasterId
        --LEFT JOIN DBO.SOMarginSummary SOMS WITH(NOLOCK) ON SO.SalesOrderId=SOMS.SalesOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON SO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = SOQ.ManagementStructureId
        JOIN DBO.ManagementStructure level4 WITH (NOLOCK)
          ON SOQ.ManagementStructureId = level4.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level3 WITH (NOLOCK)
          ON level4.ParentId = level3.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level2 WITH (NOLOCK)
          ON level3.ParentId = level2.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level1 WITH (NOLOCK)
          ON level2.ParentId = level1.ManagementStructureId

      WHERE SOQ.CustomerName IN (@customername)
      OR @customername = ' '
      AND SOQ.opendate BETWEEN (@FromDate) AND (@ToDate)
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
            @AdhocComments varchar(150) = '[usp_GetSalesOrderQuoteHistoryReport]',
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