/*************************************************************           
 ** File:   [usp_GetSalespersonReport]           
 ** Author:   Swetha  
 ** Description: Get Data for Salesperson Report 
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
	3	01/31/2024		Devendra Shekh	added isperforma Flage for WO
     
EXECUTE   [dbo].[usp_GetSalespersonReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetSalespersonReport]
--@Salesperson varchar(40)=null,
@Techname varchar(40) = NULL,
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
        E.Firstname + ' ' + E.LastName AS Salesperson,
        E1.Firstname + ' ' + E1.LastName AS CSR,
        C.name 'Customer Name',
        C.customercode 'Customer Code',
        WOBI.GrandTotal 'Revenue',
        WOBI.GrandTotal - WOMPN.DirectCost 'Margin',
        (WOBI.GrandTotal - WOMPN.DirectCost) / NULLIF(WOBI.GrandTotal, 0) 'Margin %',
        (SOP.unitsaleprice * SOP.qty) + (SOBI.freight) + SOBI.misccharges + (SOBI.salestax / 2) 'SO Revenue',
        SOMS.marginamount 'SO Margin',
        ((SOMS.marginamount) / NULLIF((SOP.unitsaleprice * SOP.qty) + (SOBI.freight) + SOBI.misccharges + (SOBI.salestax / 2), 0)) 'SO Margin %',
        WOBI.GrandTotal + (SOP.unitsaleprice * SOP.qty) + (SOBI.freight) + SOBI.misccharges + (SOBI.salestax / 2) 'Total Revenue',
        (WOBI.GrandTotal - WOMPN.DirectCost) + (SOMS.marginamount) 'Total Margin',
        (((WOBI.GrandTotal - WOMPN.DirectCost) + (SOMS.marginamount)) / NULLIF((WOBI.GrandTotal) + (SOP.unitsaleprice * SOP.qty) + (SOBI.freight) + SOBI.misccharges + (SOBI.salestax / 2), 0)) 'Total Margin %',

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
        AS LEVEL4
      FROM DBO.customer C WITH (NOLOCK) 
	        LEFT JOIN DBO.Workorder WO WITH (NOLOCK)  ON C.customerid = WO.customerid       
			LEFT JOIN DBO.WorkOrderPartNumber WOp WITH (NOLOCK) ON WO.WorkOrderId = WOp.WorkOrderId
			LEFT JOIN DBO.Salesorder SO WITH (NOLOCK) ON C.customerid = SO.customerid
			LEFT JOIN DBO.WorkOrderMPNCostDetails WOMPN WITH (NOLOCK) ON WO.WorkOrderId = WOMPN.WorkOrderId
            LEFT JOIN DBO.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WO.WorkOrderId = WOBI.WorkOrderId and WOBI.IsVersionIncrease=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
            LEFT JOIN DBO.Salesorderpart SOP WITH (NOLOCK) ON SO.salesorderid = SOP.salesorderid
		  --LEFT JOIN DBO.CustomerSales CS WITH (NOLOCK) ON C.customerid = CS.customerid
            LEFT JOIN DBO.Employee E WITH (NOLOCK) ON SO.SalesPersonId = E.EmployeeId
            LEFT JOIN DBO.Employee E1 WITH (NOLOCK) ON SO.CustomerSeviceRepId = E1.employeeid
            LEFT JOIN DBO.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON SO.SalesOrderId = SOBI.SalesOrderId
            LEFT JOIN dbo.somarginsummary SOMS WITH (NOLOCK) ON SO.salesorderid = SOMS.salesorderid
            LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK) ON C.MasterCompanyId = MC.MasterCompanyId
            INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK) ON MS.ManagementStructureId = SO.ManagementStructureId 
                  JOIN DBO.ManagementStructure level4 WITH (NOLOCK) ON SO.ManagementStructureId = level4.ManagementStructureId 
            LEFT JOIN DBO.ManagementStructure level3 WITH (NOLOCK) ON level4.ParentId = level3.ManagementStructureId
            LEFT JOIN DBO.ManagementStructure level2 WITH (NOLOCK) ON level3.ParentId = level2.ManagementStructureId
            LEFT JOIN DBO.ManagementStructure level1 WITH (NOLOCK) ON level2.ParentId = level1.ManagementStructureId

      WHERE
      --salesperson IN ( @Salesperson ) OR @salesperson = ' ' AND
      --E.FirstName LIKE @Name OR E.LastName LIKE @Name OR E.FirstName +' '+ E.LastName LIKE @Name AND
      --(IsNull(@Techname,'') ='' OR @Techname like '%' + @Techname+'%') AND
      --E.FirstName+' '+E.LastName LIKE @Techname OR ISNULL(@Techname,' ')=' ' AND
      E.FirstName + ' ' + E.LastName LIKE @Techname
      OR (@Techname) = ' '
      AND SOBI.invoicedate BETWEEN (@FromDate) AND (@ToDate)
      AND SO.mastercompanyid = @mastercompanyid
	  AND COALESCE(SO.SalesPersonId, 0) <> 0 

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
            @AdhocComments varchar(150) = '[usp_GetSalespersonReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@Techname, '') AS varchar(100)) +
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