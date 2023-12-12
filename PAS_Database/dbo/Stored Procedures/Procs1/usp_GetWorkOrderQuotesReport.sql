
/*************************************************************           
 ** File:   [usp_GetWorkOrderQuotesReport]           
 ** Author:   Swetha  
 ** Description: Get Data for WorkOrderQuotes Report
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1					Swetha		Created
	2					Swetha		Added Transaction & NO LOCK
	3	30-Nov-2021		Hemant		Updated Managment Structure Details and Date filter Condition
     
EXECUTE   [dbo].[usp_GetWorkOrderQuotesReport] '','2020-04-25','2021-09-25','4','4','','',''
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetWorkOrderQuotesReport] @name varchar(40) = NULL,
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

	  --select * FROM #ManagmetnStrcture
      SELECT DISTINCT
        UPPER(IM.PartNumber) 'PN',
        UPPER(IM.PartDescription) 'PN Description',
        UPPER(RCW.SerialNumber) 'Serial Num',
        UPPER(WS.WorkScopeCode) 'Workscope',
        UPPER(WOQ.QuoteNumber) 'Quote Num',
        UPPER(WOQ.Versionno) 'Version',
        UPPER(WOQS.Description) 'Quote Status',
        WOQ.sentDate 'QuoteDate',
        WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount 'Revenue',
        WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost 'Direct Cost',
        (WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost) 'Margin',
        ((WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount) - (WOQD.MaterialCost + WOQD.laborcost + WOQD.ChargesCost)) / NULLIF(WOQD.MaterialFlatBillingAmount + WOQD.LaborFlatBillingAmount + WOQD.ChargesFlatBillingAmount + WOQD.FreightFlatBillingAmount, 0) 'Margin %',
        UPPER(C.Name) 'Customer Name',
        UPPER(C.CustomerCode) 'CustomerCode',
        UPPER((ISNULL(Contact.FirstName, '') + ' ' + ISNULL(Contact.LastName, ''))) AS 'Customercontact',
        UPPER(C.Email) 'Email',
        UPPER(C.CustomerPhone) 'Phone',
		UPPER(WOPN.Level1) AS LEVEL1,
		UPPER(WOPN.Level2) AS LEVEL2,
		UPPER(WOPN.Level3) AS LEVEL3,
		UPPER(WOPN.Level4) AS LEVEL4, 
        UPPER(E.FirstName + ' ' + E.lastname) 'Sales Person',
        UPPER(E1.FirstName) 'CSR'
      FROM DBO.WorkOrder WO WITH (NOLOCK)
      INNER JOIN DBO.WorkOrderQuote WOQ WITH (NOLOCK)
        ON WO.WorkOrderId = WOQ.WorkOrderId
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON WOQ.CustomerId = C.CustomerId
        LEFT JOIN DBO.WorkOrderQuoteDetails WOQD WITH (NOLOCK)
          ON WOQ.workorderquoteid = WOQD.workorderquoteid
        LEFT JOIN DBO.ReceivingCustomerWork RCW WITH (NOLOCK)
          ON WO.ReceivingCustomerWorkId = RCW.ReceivingCustomerWorkId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON WOPN.itemmasterId = IM.ItemMasterId
        INNER JOIN DBO.WorkScope AS WS WITH (NOLOCK)
          ON WOPN.WorkOrderScopeId = WS.WorkScopeId
        LEFT JOIN DBO.CustomerContact CC WITH (NOLOCK)
          ON WO.CustomercontactId = CC.CustomerContactId
        LEFT JOIN DBO.Contact WITH (NOLOCK)
          ON CC.ContactId = Contact.ContactId
        LEFT JOIN DBO.Employee AS E WITH (NOLOCK)
          ON WOQ.SalesPersonId = E.EmployeeId
        LEFT JOIN DBO.Employee AS E1 WITH (NOLOCK)
          ON WO.CSRId = E1.EmployeeId
        LEFT JOIN DBO.workorderquotestatus WOQS WITH (NOLOCK)
          ON WOQ.QuoteStatusId = WOQS.WorkOrderQuoteStatusId
        LEFT JOIN DBO.WorkOrderBillingInvoicing AS WBI WITH (NOLOCK)
          ON WO.WorkOrderId = WBI.WorkOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON WO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = WOPN.ManagementStructureId        
      WHERE (C.Name IN (@name) OR isnull(@name,'') = '')
	  AND CAST(WOQ.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
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
            @AdhocComments varchar(150) = '[usp_GetWorkOrderQuotesReport]',
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