CREATE PROCEDURE [dbo].[usp_GetPOtoWOSOReport] @status varchar(20),
@vendorname varchar(40) = NULL,
@fromdate datetime,
@todate datetime,
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
        DROP TABLE #ManagmetnStrcture
      END
      CREATE TABLE #ManagmetnStrcture (
        ID bigint NOT NULL IDENTITY,
        ManagementStructureId bigint NULL,
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
        PO.Level1,
        PO.Level2,
        PO.Level3,
        PO.Level4,
        PO.PurchaseOrderNumber 'PO NUM',
        CONVERT(varchar, PO.OpenDate, 101) 'PO Date',
        (POP.partnumber) 'PN',
        (POP.PartDescription) 'PN Description',
        POP.itemtype 'Item Type',
        POP.stocktype 'StockType',
        PO.status 'Status',
        (PO.VendorName) 'Vendor Name',
        PO.VendorCode 'Vendor Code',
        POP.unitofmeasure 'UOM',
        POP.QuantityOrdered 'Qty',
        POP.UnitCost 'Unit Cost',
        POP.functionalcurrency 'Currency',
        pop.ExtendedCost 'Ext.Amount',
        '?' 'Local Amount',
        CONVERT(varchar, POP.NeedByDate, 101) 'Request date',
        '?' 'Promise Date',
        '?' 'Next Del Date',
        POP.workorderno 'WO Num',
        (IM1.partnumber) 'WO MPN',
        (IM1.partdescription) 'MPN Description',
        POP.salesorderno 'SO Num',
        (IM2.partnumber) 'SO PN',
        (IM2.partdescription) 'SOPN Description',
        C.name 'Customer'
      FROM DBO.PurchaseOrder PO WITH (NOLOCK)
      LEFT JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK)
        ON PO.PurchaseOrderId = POP.PurchaseOrderId
        LEFT JOIN DBO.Workorder WO WITH (NOLOCK)
          ON POP.workorderid = WO.workorderid
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON Wo.WorkOrderId = C.CustomerId
        LEFT JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK)
          ON WO.WorkOrderId = WOPN.WorkOrderId
        LEFT JOIN DBO.Salesorder SO WITH (NOLOCK)
          ON POP.salesorderid = SO.salesorderid
        LEFT JOIN DBO.SalesOrderPart SOP WITH (NOLOCK)
          ON SO.SalesOrderId = SOP.SalesOrderId
        LEFT JOIN DBO.ItemMaster IM2 WITH (NOLOCK)
          ON SOP.ItemMasterId = IM2.ItemMasterId
        INNER JOIN DBO.ItemMaster IM1 WITH (NOLOCK)
          ON WOPN.itemmasterId = IM1.itemmasterid
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON PO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = PO.ManagementStructureId

      WHERE (PO.VendorName = @vendorname
      OR @vendorname = ' ')
      AND PO.opendate BETWEEN (@Fromdate) AND (@Todate)
      AND PO.status IN (SELECT
        value
      FROM string_split(@status, ','))
      AND PO.MasterCompanyId = @mastercompanyid
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
            @AdhocComments varchar(150) = 'usp_GetPOtoWOSOReport',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@status, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter9 = ''' + CAST(ISNULL(@vendorname, '') AS varchar),
            @ApplicationName varchar(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
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