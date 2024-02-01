/*************************************************************           
 ** File:   [usp_GetWorkOrderQuoteconversionReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrder Quote Conversion Report
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
     
EXECUTE   [dbo].[usp_GetWorkOrderQuoteconversionReport] '','2020-04-25','2021-04-25','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetWorkOrderQuoteconversionReport] @name varchar(40) = NULL,
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
        Customer.CustomerCode 'Customer Code',
        (IM.PartNumber) 'PN',
        (IM.PartDescription) 'PN Description',
        RCW.SerialNumber 'Serial Num',
        WS.WorkScopeCode 'Work Scope',
        (CDTN.Description) 'Condition',
        WOQ.QuoteNumber 'Quote Num',
        WOQ.Versionno 'Version',
        WOQ.SentDate 'QuoteDate',
        WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount 'Revenue',
        WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost 'Direct Cost',
        (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost) 'Margin',
        ((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost)) / NULLIF(WOQD.materialrevenue + WOQD.laborrevenue + WOQD.chargesrevenue + WOQD.FreightRevenue, 0) 'Margin %',
        WO.WorkOrderNum 'WO Num',
        WOBI.InvoiceNo 'Invoice Num',
        WOBI.GrandTotal 'Actual Revenue',
        WOMPN.directcost 'Actual Direct Cost',
        WOBI.GrandTotal - WOMPN.directcost 'Actual Margin',
        (WOBI.GrandTotal - WOMPN.directcost) / NULLIF(WOBI.GrandTotal, 0) 'Actual Margin %',
        WOBI.GrandTotal - (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) 'Revenue Amt',
        (WOBI.GrandTotal - (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount)) / NULLIF(WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount, 0) 'Rev % Change',
        (WOBI.GrandTotal - WOMPN.directcost) - ((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost)) 'Margin Amt',
        ((WOBI.GrandTotal - WOMPN.directcost) - ((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost))) /
        NULLIF((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost), 0) 'Margin % Change',

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
        E.FirstName + ' ' + E.LastName 'Sales Person',
        E1.FirstName 'CSR'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      JOIN DBO.WorkOrderMPNCostDetails WOMPN WITH (NOLOCK)
        ON WO.WorkOrderId = WOMPN.WorkOrderId
        LEFT JOIN DBO.Customer WITH (NOLOCK)
          ON WO.CustomerId = Customer.CustomerId
        LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK)
          ON wo.WorkOrderId = woq.WorkOrderId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON woq.WorkOrderQuoteId = WOQD.WorkOrderQuoteId
        LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
          ON WO.WorkOrderId = RCW.WorkOrderId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.ItemMasterId
        LEFT JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.Workorderbillinginvoicing WOBI WITH (NOLOCK)
          ON WO.workorderid = WOBI.workorderid
        LEFT JOIN DBO.Condition CDTN WITH (NOLOCK)
          ON WOPN.ConditionId = CDTN.ConditionId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON woq.SalesPersonId = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON WO.CsrId = E1.EmployeeId
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

      WHERE Customer.Name IN (@name)
      OR @name = ' '
      AND WOQ.opendate BETWEEN (@FromDate) AND (@ToDate)
      AND WO.mastercompanyid = @mastercompanyid
	  AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderQuoteconversionReport]',
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