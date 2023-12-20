/*************************************************************           
 ** File:   [usp_GetPurchaseOrderSSRSDashboard]           
 ** Author:   Swetha  
 ** Description: Get Data for PurchaseOrderSSRSDashboard 
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
     
EXECUTE   [dbo].[usp_GetPurchaseOrderSSRSDashboard] 
**************************************************************/

CREATE PROCEDURE [dbo].[usp_GetPurchaseOrderSSRSDashboard]
@mastercompanyid int =0
--@vendorname varchar(max)
--@partnumber varchar(max)
--@description varchar(max),
--@firstname varchar(max),
--@status varchar(20)

AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY
    BEGIN TRANSACTION

      SELECT DISTINCT
        PO.level1 'Level1',
        PO.level2 'Level2',
        PO.level3 'Level3',
        PO.level4 'Level4',
        PO.PurchaseOrderNumber 'PO NUM',
        CONVERT(varchar, PO.OpenDate, 101) 'PO Date',
        IM.partnumber 'PN',
        IM.PartDescription 'PN Description',
        E2.FirstName 'Requestor',
        E1.FirstName 'Approved by',
        CONVERT(varchar, PO.dateapproved, 101) 'Approved Date',
        DATEDIFF(DAY, PO.OpenDate, GETDATE()) 'PO Age (Days)',
        PO.creditlimit 'Amount',
        POP.functionalcurrency 'Currency',
        V.VendorName 'Vendor Name',
        WO.workordernum 'WO Num',
        so.salesordernumber 'SO Num',
        RO.repairordernumber 'RO Num',
        '?' 'Promise Date',
        '?' 'Received Date',
        '?' 'Next Delvry Date',
        '?' 'Delay Status'
      FROM PurchaseOrder PO WITH (NOLOCK)

      LEFT JOIN PurchaseOrderPart POP WITH (NOLOCK)
        ON PO.PurchaseOrderId = POP.PurchaseOrderId
        INNER JOIN ItemMaster IM WITH (NOLOCK)
          ON POP.ItemMasterId = IM.ItemMasterId
        LEFT JOIN Vendor V WITH (NOLOCK)
          ON PO.VendorId = V.VendorId
        LEFT JOIN UnitOfMeasure WITH (NOLOCK)
          ON POP.UOMId = UnitOfMeasure.UnitOfMeasureId
        LEFT JOIN WorkOrder WO WITH (NOLOCK)
          ON POP.WorkOrderId = WO.WorkOrderId
        LEFT JOIN SalesOrder SO WITH (NOLOCK)
          ON POP.salesOrderId = SO.salesOrderId
        LEFT JOIN RepairOrder RO WITH (NOLOCK)
          ON POP.repairOrderId = RO.repairOrderId
        LEFT JOIN Currency WITH (NOLOCK)
          ON V.CurrencyId = Currency.CurrencyId
        LEFT JOIN ItemType IT WITH (NOLOCK)
          ON IM.itemtypeid = IT.ItemTypeId
        LEFT JOIN Employee E1 WITH (NOLOCK)
          ON PO.ApproverId = E1.EmployeeId
        LEFT JOIN Employee E2 WITH (NOLOCK)
          ON PO.RequestedBy = E2.EmployeeId

		  where PO.MasterCompanyId = @mastercompanyid

    COMMIT TRANSACTION
  END TRY

  BEGIN CATCH
    ROLLBACK TRANSACTION

    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usp_GetPurchaseOrderSSRSDashboard]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = '+@mastercompanyid+'',
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