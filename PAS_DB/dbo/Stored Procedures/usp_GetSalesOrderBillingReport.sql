﻿
/*************************************************************           
 ** File:   [usp_GetSalesOrderBillingReport]           
 ** Author:   Swetha  
 ** Description: Get Data for SalesOrderBilling Report 
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1              Swetha Created
    2              Swetha Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetSalesOrderBillingReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
--select * from dbo.ManagementStructure WHERE ParentId in (1,4,43,44,45,80,84,88) 
--select * from dbo.ManagementStructure WHERE ParentId in (46,47,66) 
--select * from dbo.ManagementStructure WHERE ParentId in (48,49,50,58,59,67,68,69) 
CREATE PROCEDURE [dbo].[usp_GetSalesOrderBillingReport] @name varchar(40) = NULL,
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
        C.NAME 'Customer Name',
        C.customercode 'Customer Code',
        IM.partnumber 'PN',
        IM.partdescription 'PN Description',
        CDTN.description 'Condition',
        SO.salesordernumber 'SO Num',
        WO.workordernum 'WO Num',
        STL.receiveddate 'Received Date',
        SO.opendate ' Open Date',
        SOBI.invoiceno 'Invoice Num',
        SOBI.invoicedate 'InvoiceDate',
        --(SOP.unitsaleprice * SOP.qty) + (SOBI.freight) + SOBI.misccharges + (SOBI.salestax / 2) 'Revenue',
		(isnull(SOP.SalesPriceExtended,0) + (select isnull(sum(sc.billingamount),0) from SalesOrderCharges  sc where sc.SalesOrderId =SO.SalesOrderId and sop.SalesOrderPartId=sc.SalesOrderPartId and sc.isdeleted=0 and sc.isactive =1 ) )as  'Revenue',
        SOQ.OpenDate 'Quote Date',
        --CASE
        --  WHEN soq.StatusName = 'Approved' THEN soq.ApprovedDate
        --END AS 'Quote Approval Date',
		soq.ApprovedDate AS 'Quote Approval Date',
        --SOQ.approveddate 'Quote Approval Date',
        SOBI.shipdate 'Ship Date',
		SOBI.level1 AS LEVEL1,
		SOBI.level2 AS LEVEL2,
		SOBI.level3 AS LEVEL3,
		SOBI.level4 AS LEVEL4,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level1.code + '-' + level1.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END
        --AS LEVEL1,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level2.code + '-' + level2.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END
        --AS LEVEL2,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level3.code + '-' + level3.NAME
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END
        --AS LEVEL3,
        --CASE
        --  WHEN level4.code + '-' + level4.NAME IS NOT NULL AND
        --    level3.code + '-' + level3.NAME IS NOT NULL AND
        --    level2.code + '-' + level2.NAME IS NOT NULL AND
        --    level1.code + '-' + level1.NAME IS NOT NULL THEN level4.code + '-' + level4.NAME
        --  ELSE ''
        --END
        --AS LEVEL4,
        E.firstname + ' ' + E.lastname 'Sales Person',
        E1.firstname + ' ' + E1.lastname 'CSR'
      FROM dbo.salesorder SO WITH (NOLOCK)
      LEFT JOIN dbo.salesorderpart SOP WITH (NOLOCK) ON So.salesorderid = SOP.salesorderid
        LEFT JOIN dbo.salesorderquote SOQ WITH (NOLOCK)  ON SO.SalesOrderQuoteId = SOQ.salesorderquoteid
        LEFT JOIN dbo.salesorderbillinginvoicing SOBI WITH (NOLOCK)
          ON SO.salesorderid = SOBI.salesorderid
        LEFT JOIN dbo.customer C WITH (NOLOCK)
          ON SOBI.customerid = C.customerid
        LEFT JOIN dbo.itemmaster IM WITH (NOLOCK)
          ON SOP.itemmasterid = IM.itemmasterid
        LEFT JOIN dbo.stockline STL WITH (NOLOCK)
          ON SOP.stocklineid = STL.stocklineid and stl.IsParent=1
        LEFT JOIN dbo.workorder WO WITH (NOLOCK)
          ON STL.workorderid = WO.workorderid
        LEFT JOIN dbo.condition CDTN WITH (NOLOCK)
          ON SOP.conditionid = CDTN.conditionid
        LEFT JOIN dbo.employee AS E WITH (NOLOCK)
          ON SO.salespersonid = E.employeeid
        LEFT JOIN dbo.employee AS E1 WITH (NOLOCK)
          ON SO.customersevicerepid = E1.employeeid
        LEFT OUTER JOIN dbo.mastercompany MC WITH (NOLOCK)
          ON SO.mastercompanyid = MC.mastercompanyid
        INNER JOIN #managmetnstrcture MS WITH (NOLOCK)
          ON MS.managementstructureid = SO.managementstructureid
        --JOIN dbo.managementstructure level4 WITH (NOLOCK)
        --  ON SO.managementstructureid = level4.managementstructureid
        --LEFT JOIN dbo.managementstructure level3 WITH (NOLOCK)
        --  ON level4.parentid = level3.managementstructureid
        --LEFT JOIN dbo.managementstructure level2 WITH (NOLOCK)
        --  ON level3.parentid = level2.managementstructureid
        --LEFT JOIN dbo.managementstructure level1 WITH (NOLOCK)
        --  ON level2.parentid = level1.managementstructureid

      WHERE C.Name IN (@name) OR @name = ' '
      --AND SOBI.invoicedate BETWEEN (@Fromdate) AND (@Todate)
	  AND CAST(SOBI.invoicedate AS DATETIME) BETWEEN CAST(@FromDate AS DATETIME) AND CAST(@ToDate AS DATETIME)
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
            @AdhocComments varchar(150) = '[usp_GetSalesOrderBillingReport]',
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