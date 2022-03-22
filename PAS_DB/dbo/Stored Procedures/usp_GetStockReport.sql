
/*************************************************************           
 ** File:   [usp_GetStockReport]           
 ** Author:   Swetha  
 ** Description: Get Data for Stock Report  
 ** Purpose:         
 ** Date:   15-march-2020       
          
 ** PARAMETERS:           
   
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** S NO   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Swetha	Created
	2	        	  Swetha	Added Transaction & NO LOCK
	3	 27 Nov 2021  HEMANT	Updated Date Filter condition

     
EXECUTE   [dbo].[usp_GetStockReport] '1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetStockReport] @mastercompanyid int,
@Level1 varchar(max) = NULL,
@Level2 varchar(max) = NULL,
@Level3 varchar(max) = NULL,
@Level4 varchar(max) = NULL,
@Fromdate datetime2,
@Todate datetime2
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

      SELECT
        UPPER(im.partnumber) AS 'PN',
        UPPER(im.PartDescription) AS 'PN Description',
        UPPER(stl.SerialNumber) 'Serial Num',
        UPPER(stl.stocklineNumber) 'SL Num',
        UPPER(stl.condition) 'Cond',
        UPPER(stl.itemgroup) 'Item Group',
        UPPER(stl.unitofmeasure) 'UOM',
        UPPER(stl.itemtype) 'Item Type',
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
        END AS StockType,
        UPPER(POP.altequipartnumber) 'Alt/Equiv',
        UPPER(VNDR.VendorName) 'Vendor Name',
        UPPER(VNDR.VendorCode) 'Vendor Code',
        stl.QuantityOnHand 'QTY on Hand',
        stl.QuantityReserved 'Qty Reserved',
        UPPER(stl.QuantityAvailable) 'Qty Available',
        'NA' 'Qty Scrapped',
        CASE
          WHEN stladjtype.StocklineAdjustmentDataTypeId = 10 THEN STl.QuantityOnHand - stladj.ChangedTo
        END AS 'Qty Adjusted',
        stl.purchaseorderUnitCost 'Unit Cost',
        stl.PurchaseOrderExtendedCost 'Extended Cost',        
        UPPER(stl.OwnerName) 'Owner',
        UPPER(stl.TraceableToname) 'Traceable To',
        UPPER(stl.Obtainfromname) 'Obtain From',
        UPPER(stl.manufacturer) 'Mfg',
        stl.UnitSalesPrice 'unit_price',
        'NA' AS extendedPrice,
        UPPER(stl.Level1) AS Level1,
		UPPER(stl.Level2) AS Level2,
		UPPER(stl.Level3) AS Level3,
		UPPER(stl.Level4) AS Level4,
        UPPER(stl.site) 'Site',
        UPPER(stl.warehouse) 'Warehouse',
        UPPER(stl.location) 'Location',
        UPPER(stl.shelf) 'Shelf',
        UPPER(stl.bin) 'Bin',
        UPPER(stl.glAccountname) 'GL Account',
        UPPER(pox.PurchaseOrderNumber) 'PO Num',
        UPPER(rox.RepairOrderNumber) 'RO Num',
        stl.RepairOrderUnitCost 'RO Cost',
        CONVERT(date, stl.ReceivedDate) 'Received Date',
        UPPER(stl.ReceiverNumber) 'Receiver Num',
        UPPER(stl.ReconciliationNumber) 'Receiver Recon'
      FROM DBO.stockline stl WITH (NOLOCK)
      LEFT OUTER JOIN DBO.ItemMaster im WITH (NOLOCK)
        ON stl.ItemMasterId = im.ItemMasterId
        LEFT OUTER JOIN DBO.PurchaseOrder pox WITH (NOLOCK)
          ON stl.PurchaseOrderId = pox.PurchaseOrderId
        LEFT OUTER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK)
          ON stl.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId
        LEFT OUTER JOIN DBO.RepairOrder rox WITH (NOLOCK)
          ON stl.RepairOrderId = rox.repairorderid
        LEFT JOIN DBO.vendor VNDR WITH (NOLOCK)
          ON stl.VendorId = VNDR.VendorId
        LEFT JOIN DBO.StocklineAdjustment stladj WITH (NOLOCK)
          ON stl.StockLineId = stladj.StocklineId
        LEFT JOIN DBO.StocklineAdjustmentDataType stladjtype WITH (NOLOCK)
          ON stladj.StocklineAdjustmentDataTypeId = stladjtype.StocklineAdjustmentDataTypeId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON stl.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = stl.ManagementStructureId
     
      WHERE stl.mastercompanyid = @mastercompanyid and stl.IsParent =1 and  CAST(stl.CreatedDate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)

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
            @AdhocComments varchar(150) = '[usp_GetStockReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@level1, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@level2, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@level3, '') AS varchar(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@level4, '') AS varchar(100)) +
            '@Parameter5 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100)),
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