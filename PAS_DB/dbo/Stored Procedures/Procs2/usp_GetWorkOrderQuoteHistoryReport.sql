
/*************************************************************           
 ** File:   [usp_GetWorkOrderQuoteHistoryReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderQuote History Report
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
     
EXECUTE   [dbo].[usp_GetWorkOrderQuoteHistoryReport] '','2020-04-25','2021-04-25','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
--EXEC usp_GetWorkOrderQuoteHistoryReport  '1,4,43,44,45,80,84,88','46,47','58,59','64,65,77'
CREATE PROCEDURE [dbo].[usp_GetWorkOrderQuoteHistoryReport] @name varchar(40) = NULL,
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
        (IM.PartNumber) 'PN',
        (IM.PartDescription) 'PNDescription',
        (C.Name) 'Acct Name',
        C.CustomerCode 'Acct Code',
        CT.Description 'Acct Type',
        WS.WorkScopeCode 'Workscope',
        WOQ.Quotenumber 'Quote Num',
        WOQS.Description 'Status',
        WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount 'Quote Amount',
        E.FirstName + ' ' + E.lastname 'Sales Person',
        WOQ.SentDate 'QuoteDate',
        E1.FirstName + ' ' + E1.lastname 'Employee',

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

      FROM DBO.WorkOrder WO WITH (NOLOCK)
      LEFT JOIN DBO.Customer C WITH (NOLOCK)
        ON WO.CustomerId = C.CustomerId
        LEFT JOIN DBO.CustomerType CT WITH (NOLOCK)
          ON C.CustomerTypeId = CT.CustomerTypeId
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON wo.WorkOrderId = woq.WorkOrderId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON WOQ.SalesPersonId = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON woq.EmployeeId = E1.EmployeeId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON woq.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.workorderquotestatus WOQS WITH (NOLOCK)
          ON WOQ.QuoteStatusId = WOQS.WorkOrderQuoteStatusId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId
        JOIN DBO.ManagementStructure level4 WITH (NOLOCK)
          ON WOPN.ManagementStructureId = level4.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level3 WITH (NOLOCK)
          ON level4.ParentId = level3.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level2 WITH (NOLOCK)
          ON level3.ParentId = level2.ManagementStructureId
        LEFT JOIN DBO.ManagementStructure level1 WITH (NOLOCK)
          ON level2.ParentId = level1.ManagementStructureId

      WHERE C.Name IN (@name)
      OR @name = ' '
      AND WOQ.opendate BETWEEN (@FromDate) AND (@ToDate)
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderQuoteHistoryReport]',
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