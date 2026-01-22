
/*************************************************************           
 ** File:   [usp_GetPurchaseOrderReport]           
 ** Author:   Swetha  
 ** Description: Get Data for PurchaseOrderReport  
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
	3	        	  Hemant Added Updated for Upper Case
     
EXECUTE   [dbo].[usp_GetPurchaseOrderReport] '','','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
EXECUTE   [dbo].[usp_GetPurchaseOrderReport] '','','2020-06-15','2021-06-15','1','1,4,43,44,45,80,84,88','46,47,66','48,49,50,58,59,67,68,69','51,52,53,54,55,56,57,60,61,62,64,70,71,72'
**************************************************************/
CREATE PROCEDURE [dbo].[usp_GetPurchaseOrderReport] @status varchar(20),
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
      SELECT
        UPPER(PO.Level1),
        UPPER(PO.Level2),
        UPPER(PO.Level3),
        UPPER(PO.Level4),
        UPPER(PO.PurchaseOrderNumber) 'PO NUM',
        UPPER(PO.OpenDate) 'PO Date',
        UPPER(POP.partnumber) 'PN',
        UPPER(POP.PartDescription) 'PN Description',
        UPPER(POP.itemtype) 'Item Type',
        UPPER(POP.stocktype) 'StockType',
        UPPER(PO.status) 'Status',
        DATEDIFF(DAY, PO.OpenDate, GETDATE()) 'PO Age',
        UPPER(PO.VendorName) 'Vendor Name',
        UPPER(PO.VendorCode) 'Vendor Code',
        UPPER(POP.unitofmeasure) 'UOM',
        UPPER(PO.Approvedby) 'Approver',
        UPPER(PO.Requisitioner) 'Requisitioner ',
        UPPER(POP.QuantityOrdered) 'Qty',
        UPPER(POP.UnitCost) 'Unit Cost',
        UPPER(POP.functionalcurrency) 'Currency',
        UPPER(pop.ExtendedCost) 'ExtendedCost',
        UPPER(POP.NeedByDate) 'Need By',
        'NA' 'Promise Date',
        'NA' 'Next Del Date'

      FROM dbo.PurchaseOrder PO WITH (NOLOCK)
      INNER JOIN DBO.PurchaseOrderPart POP WITH (NOLOCK)
        ON PO.PurchaseOrderId = POP.PurchaseOrderId
        LEFT OUTER JOIN DBO.mastercompany MC WITH (NOLOCK)
          ON PO.MasterCompanyId = MC.MasterCompanyId
        INNER JOIN #ManagmetnStrcture MS WITH (NOLOCK)
          ON MS.ManagementStructureId = PO.ManagementStructureId
      WHERE PO.status IN (SELECT
        value
      FROM String_split(@status, ','))
	  AND CAST(PO.opendate AS DATE) BETWEEN CAST(@FromDate AS DATE) AND CAST(@ToDate AS DATE)     
      AND (PO.VendorName = @vendorname
      OR @vendorname = ' ')
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
            @AdhocComments varchar(150) = '[usp_GetPurchaseOrderReport]',
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
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END