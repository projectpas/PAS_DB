
/*************************************************************           
 ** File:   [usp_GetReceivingLogReport]           
 ** Author:   Swetha  
 ** Description: Get Data for ReceivingLog Report  
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
     
EXECUTE   [dbo].[usp_GetReceivingLogReport] '','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetReceivingLogReport] @partnumber varchar(50) = NULL,
@Fromdate datetime2,
@Todate datetime2,
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
		STL.Level1,
		STL.Level2,
		STL.Level3,
		STL.Level4,        
        STL.ReceiverNumber 'Receiving Num',
        STL.OrderDate 'Order Date',
        STL.ReceivedDate 'Received Date',
        PO.PurchaseOrderNumber AS 'PO/RO Num',
        PO.status 'PO/RO Status',
        STL.ControlNumber 'Control Num',
        STL.IdNumber 'ID Num',
        STL.StockLineNumber 'SL Num',
        (IM.partnumber) 'PN',
        (IM.PartDescription) 'PN Description',
        STL.SerialNumber 'Serial Num',
        POP.stocktype 'StockType',
        POP.AltEquiPartNumber 'Alt/Equiv',
        POP.manufacturer 'Manufacturer',
        POP.itemtype 'Item Type',
        POP.QuantityOrdered 'Qty Ordered',
        POP.QuantityBackOrdered 'Qty Received',
        POP.UnitCost 'Unit Cost',
        POP.ExtendedCost 'Extended Cost',
        POP.QuantityRejected 'Qty Rejected',
        '?' 'Qty on Backlog',
        STL.ReceivedDate 'Last Received Date',
        PO.Requisitioner 'Requestor',
        PO.approvedby 'Approver',
        STL.Site 'Site',
        STL.Warehouse 'Warehouse',
        STL.Location 'Location',
        STL.Shelf 'Shelf',
        STL.bin 'Bin'
      FROM DBO.PurchaseOrder PO WITH (NOLOCK)
    
        INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK)
          ON PO.PurchaseOrderId = POP.PurchaseOrderId and POP.isParent=1
		INNER JOIN DBO.ItemMaster im WITH (NOLOCK)
          ON POP.ItemMasterId = im.ItemMasterId
		INNER JOIN DBO.Stockline STL WITH (NOLOCK)
        ON STL.PurchaseOrderPartRecordId = POP.PurchaseOrderPartRecordId and STL.IsParent=1       
        INNER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON STL.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = STL.ManagementStructureId
      WHERE (IM.partnumber IN (@partnumber) OR ISNULL(@partnumber, '') = '')
	  AND CAST(STL.receiveddate AS DATE) BETWEEN CAST(@Fromdate AS DATE)  AND CAST(@Todate AS DATE)
      AND STL.mastercompanyid = @mastercompanyid 

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
            @AdhocComments varchar(150) = '[usp_GetReceivingLogReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@fromdate, '') AS varchar(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@todate, '') AS varchar(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@partnumber, '') AS varchar(100)) +
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