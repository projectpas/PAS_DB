
/*************************************************************           
 ** File:   [usp_GetVendorUtilizationReport]           
 ** Author:   Swetha  
 ** Description: Get Data for VendorUtilization Report  
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
     
EXECUTE   [dbo].[usp_GetVendorUtilizationReport] '','','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetVendorUtilizationReport] @status varchar(20),
@vendorname varchar(40) = NULL,
@fromdate datetime,
@todate datetime,
@mastercompanyid int = NULL,
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
        UPPER(PO.Level1),
        UPPER(PO.Level2),
        UPPER(PO.Level3),
        UPPER(PO.Level4),
        UPPER(PO.PurchaseOrderNumber) 'PO NUM',
        CONVERT(varchar, PO.OpenDate, 101) 'PO Date',
        UPPER(IM.partnumber) 'PN',
        UPPER(IM.PartDescription) 'PN Description',
        UPPER(STL.itemtype) 'Item Type',
        CASE
          WHEN stl.isPma = 1 AND
            stl.IsDER = 1 THEN 'PMA&DER'
          WHEN stl.isPma = 1 AND
            (stl.IsDER IS NULL OR
            stl.IsDER = 0) THEN 'PMA'
          WHEN (stl.isPma = 0 OR
            stl.isPma IS NULL) AND
            stl.IsDER = 1 THEN 'DER'
          ELSE 'OEM'
        END AS 'StockType',
        UPPER(PO.status) 'Status',
        UPPER(PO.VendorName) 'Vendor Name',
        UPPER(PO.VendorCode) 'Vendor Code',
        UPPER(POP.unitofmeasure) 'UOM',
        POP.QuantityOrdered 'Qty',
        POP.PurchaseOrderId,
        POP.PurchaseOrderPartRecordId,
        POP.QuantityOrdered,
        (((SELECT
              SUM(QtyReserved)
            FROM dbo.WorkOrderMaterials WOM WITH(NOLOCK)
            INNER JOIN dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK)
              ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
            WHERE WOM.POId = POP.PurchaseOrderId
            AND WOM.ItemMasterId = POP.ItemMasterId
            AND WOM.ConditionCodeId = POP.ConditionId)
            + (SELECT
              SUM(QtyIssued)
            FROM dbo.WorkOrderMaterials WOM
            INNER JOIN dbo.WorkOrderMaterialStockLine WOMS
              ON WOM.WorkOrderMaterialsId = WOMS.WorkOrderMaterialsId
            WHERE WOM.POId = POP.PurchaseOrderId
            AND WOM.ItemMasterId = POP.ItemMasterId
            AND WOM.ConditionCodeId = POP.ConditionId)
            )) AS QTY,
        STL.UnitCost 'Unit Cost',
        UPPER(POP.functionalcurrency) 'Currency',
        STL.PurchaseOrderExtendedCost 'Ext.Amount',
        'N/A' 'Local Amount',
        CONVERT(varchar, POP.NeedByDate, 101) 'Request date',
        UPPER(POP.workorderno) 'WO Num',
        UPPER(IM1.partnumber) 'WO MPN',
        UPPER(IM1.partdescription) 'MPN Description',
        UPPER(POP.salesorderno) 'SO Num',
        '' as  'SO PN',
        '' as 'SOPN Description',
        UPPER(C.name) 'Customer'
      FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
      LEFT JOIN DBO.PurchaseOrder PO WITH (NOLOCK)
        ON POP.PurchaseOrderId = PO.PurchaseOrderId
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON POP.PurchaseOrderPartRecordId = STL.PurchaseOrderPartRecordId and stl.IsParent=1
        LEFT JOIN DBO.Workorder WO WITH (NOLOCK)
          ON POP.workorderid = WO.workorderid
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON WO.CustomerId = C.CustomerId
        LEFT JOIN DBO.Itemmaster IM WITH (NOLOCK)
          ON POP.itemmasterid = IM.itemmasterid
        LEFT JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK)
          ON POP.PurchaseOrderId = WOM.POId
        LEFT JOIN DBO.itemmaster IM1 WITH (NOLOCK)
          ON WOM.itemmasterid = IM1.itemmasterid
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = PO.ManagementStructureId

      WHERE (PO.vendorname = @vendorname
      OR @vendorname = ' ')
      AND CAST(PO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
      AND PO.status IN (SELECT
        value
      FROM String_split(@status, ','))
      AND PO.mastercompanyid = @mastercompanyid

	  Union all

	  SELECT DISTINCT
        UPPER(PO.Level1),
        UPPER(PO.Level2),
        UPPER(PO.Level3),
        UPPER(PO.Level4),
        UPPER(PO.PurchaseOrderNumber) 'PO NUM',
        CONVERT(varchar, PO.OpenDate, 101) 'PO Date',
        UPPER(IM.partnumber) 'PN',
        UPPER(IM.PartDescription) 'PN Description',
        UPPER(STL.itemtype) 'Item Type',
        CASE
          WHEN stl.isPma = 1 AND
            stl.IsDER = 1 THEN 'PMA&DER'
          WHEN stl.isPma = 1 AND
            (stl.IsDER IS NULL OR
            stl.IsDER = 0) THEN 'PMA'
          WHEN (stl.isPma = 0 OR
            stl.isPma IS NULL) AND
            stl.IsDER = 1 THEN 'DER'
          ELSE 'OEM'
        END AS 'StockType',
        UPPER(PO.status) 'Status',
        UPPER(PO.VendorName) 'Vendor Name',
        UPPER(PO.VendorCode) 'Vendor Code',
        POP.unitofmeasure 'UOM',
        POP.QuantityOrdered 'Qty',
        POP.PurchaseOrderId,
        POP.PurchaseOrderPartRecordId,
        POP.QuantityOrdered,
        ((SELECT
              SUM(SORP.QtyToReserve)
            FROM dbo.SalesOrderPart SOP
            INNER JOIN dbo.SalesOrderReserveParts SORP
              ON SOP.SalesOrderPartId = SORP.SalesOrderPartId
            WHERE SOP.SalesOrderId = POP.SalesOrderId
            AND SOP.ItemMasterId = POP.ItemMasterId
            AND SOP.ConditionId = POP.ConditionId)) AS QTY,
        STL.UnitCost 'Unit Cost',
        UPPER(POP.functionalcurrency) 'Currency',
        STL.PurchaseOrderExtendedCost 'Ext.Amount',
        'N/A' 'Local Amount',
        CONVERT(varchar, POP.NeedByDate, 101) 'Request date',
        UPPER(POP.workorderno) 'WO Num',
        '' as  'WO MPN',
        '' as 'MPN Description',
        UPPER(POP.salesorderno) 'SO Num',
        UPPER(IM2.partnumber) 'SO PN',
        UPPER(IM2.partdescription) 'SOPN Description',
        UPPER(C.name) 'Customer'
      FROM DBO.PurchaseOrderPart POP WITH (NOLOCK)
      LEFT JOIN DBO.PurchaseOrder PO WITH (NOLOCK)
        ON POP.PurchaseOrderId = PO.PurchaseOrderId
        LEFT JOIN DBO.Stockline STL WITH (NOLOCK)
          ON POP.PurchaseOrderPartRecordId = STL.PurchaseOrderPartRecordId and stl.IsParent=1
	   LEFT JOIN DBO.SalesOrder SO WITH (NOLOCK)
          ON POP.salesorderid = SO.SalesOrderId
	    LEFT JOIN DBO.salesorderpart SOP WITH (NOLOCK)
          ON POP.salesorderid = SOP.SalesOrderId
        LEFT JOIN DBO.Customer C WITH (NOLOCK)
          ON SO.CustomerId = C.CustomerId
        LEFT JOIN DBO.Itemmaster IM WITH (NOLOCK)
          ON POP.itemmasterid = IM.itemmasterid
        LEFT JOIN DBO.itemmaster IM2 WITH (NOLOCK)
          ON SOP.ItemMasterId = IM2.itemmasterid
          AND (SOP.ItemMasterId = POP.ItemMasterId)
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = PO.ManagementStructureId

      WHERE (PO.vendorname = @vendorname
      OR @vendorname = ' ')
	  AND CAST(PO.opendate AS DATE) BETWEEN CAST(@Fromdate AS DATE) AND CAST(@Todate AS DATE)
      AND PO.status IN (SELECT
        value
      FROM String_split(@status, ','))
      AND PO.mastercompanyid = @mastercompanyid

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
            @AdhocComments varchar(150) = '[usp_GetVendorUtilizationReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@vendorname, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter6 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter7 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter8 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)) +
            '@Parameter9 = ''' + CAST(ISNULL(@status, '') AS varchar),
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