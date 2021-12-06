
/*************************************************************           
 ** File:   [usp_GetSOBacklogReport]           
 ** Author:   Swetha  
 ** Description: Get Data for SOBacklog Report  
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author    Change Description            
 ** --   --------     -------    --------------------------------          
    1                 Swetha Created
  2              Swetha Added Transaction & NO LOCK
     
EXECUTE   [dbo].[usp_GetSOBacklogReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetSOBacklogReport] @Customername varchar(40) = NULL,
@Fromdate datetime,
@Todate datetime,
@mastercompanyid int,
@level1 varchar(max) = NULL,
@level2 varchar(max) = NULL,
@level3 varchar(max) = NULL,
@level4 varchar(max) = NULL

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
        SO.SalesOrderNumber 'SONum',
        CONVERT(varchar, SO.openDate, 101) 'OpenDate',
        SOQ.SalesOrderQuoteNumber 'Quote Num',
		ST.name AS 'Status',        
        IM.partnumber AS 'PN',
        IM.PartDescription AS 'PNDescription',
        C.Name AS 'Customer',
        SO.customerreference 'Cust Ref',
        SOP.qty 'Qty',
        SOP.unitcost 'Unit Cost',
        SOP.qty * SOP.unitcost 'Ext cost',
        SOP.CustomerRequestDate AS 'Cust Request Date',
        SOP.EstimatedShipDate AS ' Ship Date',
        SO.Statuschangedate 'SO Approved Date',
        SOBI.level1 AS LEVEL1,
		SOBI.level2 AS LEVEL2,
		SOBI.level3 AS LEVEL3,
		SOBI.level4 AS LEVEL4
      FROM DBO.salesorder SO WITH (NOLOCK)
	  JOIN dbo.MasterSalesOrderQuoteStatus ST WITH (NOLOCK) ON SO.StatusId = ST.id
      LEFT JOIN DBO.SalesOrderquote SOQ WITH (NOLOCK)
        ON SO.SalesOrderQuoteId = SOQ.SalesOrderQuoteId
        LEFT JOIN DBO.SalesOrderQuotePart SOQP WITH (NOLOCK)
          ON SOQ.SalesOrderQuoteId = SOQP.SalesOrderQuoteId
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON SOQ.CustomerId = C.CustomerId
        LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK)
          ON SOQP.ItemMasterId = IM.ItemMasterId
        LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK)
          ON SO.SalesOrderId = SOP.SalesOrderId
        LEFT JOIN DBO.Salesorderapproval SOA WITH (NOLOCK)
          ON So.SalesOrderId = SOA.SalesOrderId
        LEFT JOIN DBO.SalesOrderShipping SOS WITH (NOLOCK)
          ON SOA.SalesOrderId = SOS.SalesOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON SO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = SO.ManagementStructureId        

      WHERE SO.CustomerName IN (@Customername) OR @Customername = ' '
	  AND CAST(SO.OpenDate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)
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
            @AdhocComments varchar(150) = '[usp_GetSOBacklogReport]',
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