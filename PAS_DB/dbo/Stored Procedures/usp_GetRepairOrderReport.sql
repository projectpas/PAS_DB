
/*************************************************************           
 ** File:   [usp_GetRepairOrderReport]           
 ** Author:   Swetha  
 ** Description: Get Data for RepairOrder Report  
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
     
EXECUTE   [dbo].[usp_GetRepairOrderReport] '','','','','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetRepairOrderReport] @name varchar(40) = NULL,
@workordernum varchar(40) = NULL,
@salesordernumber varchar(40) = NULL,
@vendorname varchar(40) = NULL,
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
        RO.repairordernumber 'RO Num',
        CONVERT(varchar, RO.opendate, 101) 'Open Date',
        RO.status 'RO Status',
        WO.workordernum 'WO Num',
        SO.salesordernumber 'SO Num',
        (C.Name) 'Customer Name',
        (ROP.partnumber) 'PN',
        (ROP.partdescription) 'PN Description',
        STL.SerialNumber 'Serial Num',
        (RO.vendorname) 'Vendor Name',
        RO.Priority 'Priority',
        --ROP.QuantityOrdered	   'Number of Items',
        ROP.unitcost 'Unit Cost',
        ROP.ExtendedCost 'Extended Cost',
        CONVERT(varchar, RO.NeedByDate, 101) 'Need By Date',
        '?' 'Promise Date',
        '?' 'Estimated Ship Date',
        CONVERT(varchar, STL.receiveddate, 101) 'Received Date',
        STL.receivernumber 'Receiver Num',
        RO.Requisitioner 'Requestor',
        RO.ApprovedBy 'Approver',
        RO.Level1 'LEVEl1',
        RO.Level2 'LEVEL2',
        RO.level3 'LEVEL3',
        RO.Level4 'LEVEL4'
      FROM DBO.RepairOrder RO WITH (NOLOCK)
      JOIN DBO.Repairorderpart ROP WITH (NOLOCK)
        ON RO.RepairOrderId = ROP.repairorderid
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON ROP.stocklineid = STL.stocklineid and STL.IsParent =1
        LEFT JOIN DBO.Workorder WO WITH (NOLOCK)
          ON ROP.workorderid = WO.workorderid and ROP.SalesOrderId is null
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
       
        INNER JOIN DBO.Salesorder SO WITH (NOLOCK)
          ON ROP.salesorderid = SO.salesorderid and ROP.WorkOrderId is null
		LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON SO.CustomerId = C.CustomerId
        --LEFT JOIN Itemmaster IM ON WOPN.itemmasterid=IM.itemmasterid
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON RO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = RO.ManagementStructureId

      WHERE RO.opendate BETWEEN (@Fromdate) AND (@Todate)
      AND (C.Name IN (@name)
      OR @name = ' ')
      AND (WO.WorkOrderNum IN (@workordernum)
      OR @workordernum = ' ')
      AND (SO.salesordernumber IN (@salesordernumber)
      OR @salesordernumber = ' ')
      AND (RO.VendorName IN (@vendorname)
      OR @vendorname = ' ')
      AND RO.mastercompanyid = @mastercompanyid

	  UNION ALL

	   SELECT DISTINCT
        RO.repairordernumber 'RO Num',
        CONVERT(varchar, RO.opendate, 101) 'Open Date',
        RO.status 'RO Status',
        WO.workordernum 'WO Num',
        SO.salesordernumber 'SO Num',
        (C.Name) 'Customer Name',
        (ROP.partnumber) 'PN',
        (ROP.partdescription) 'PN Description',
        STL.SerialNumber 'Serial Num',
        (RO.vendorname) 'Vendor Name',
        RO.Priority 'Priority',
        --ROP.QuantityOrdered	   'Number of Items',
        ROP.unitcost 'Unit Cost',
        ROP.ExtendedCost 'Extended Cost',
        CONVERT(varchar, RO.NeedByDate, 101) 'Need By Date',
        '?' 'Promise Date',
        '?' 'Estimated Ship Date',
        CONVERT(varchar, STL.receiveddate, 101) 'Received Date',
        STL.receivernumber 'Receiver Num',
        RO.Requisitioner 'Requestor',
        RO.ApprovedBy 'Approver',
        RO.Level1 'LEVEl1',
        RO.Level2 'LEVEL2',
        RO.level3 'LEVEL3',
        RO.Level4 'LEVEL4'
      FROM DBO.RepairOrder RO WITH (NOLOCK)
      JOIN DBO.Repairorderpart ROP WITH (NOLOCK)
        ON RO.RepairOrderId = ROP.repairorderid
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON ROP.stocklineid = STL.stocklineid and STL.IsParent =1
        inner JOIN DBO.Workorder WO WITH (NOLOCK)
          ON ROP.workorderid = WO.workorderid and ROP.SalesOrderId is null
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON WO.CustomerId = C.CustomerId
        LEFT JOIN DBO.Salesorder SO WITH (NOLOCK)
          ON ROP.salesorderid = SO.salesorderid and ROP.WorkOrderId is null
        --LEFT JOIN Itemmaster IM ON WOPN.itemmasterid=IM.itemmasterid
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON RO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = RO.ManagementStructureId

      WHERE RO.opendate BETWEEN (@Fromdate) AND (@Todate)
      AND (C.Name IN (@name)
      OR @name = ' ')
      AND (WO.WorkOrderNum IN (@workordernum)
      OR @workordernum = ' ')
      AND (SO.salesordernumber IN (@salesordernumber)
      OR @salesordernumber = ' ')
      AND (RO.VendorName IN (@vendorname)
      OR @vendorname = ' ')
      AND RO.mastercompanyid = @mastercompanyid



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
            @AdhocComments varchar(150) = '[usp_GetRepairOrderReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@name, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@salesordernumber, '') AS varchar(100)) +
            '@Parameter9 = ''' + CAST(ISNULL(@vendorname, '') AS varchar(100)) +
            '@Parameter10 = ''' + CAST(ISNULL(@workordernum, '') AS varchar(100)),
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