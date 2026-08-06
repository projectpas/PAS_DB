
/*************************************************************           
 ** File:   [SP_GetSubWorkOrderMPNsById]           
 ** Author: Rajesh Gami
 ** Description: This stored procedure is used to Get SubWork Order MPNs By Subworkorder Id
 ** Date:   21 MAR 2025
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date          Author  		 Change Description            
 ** --   --------      -------		 ---------------------------     
    1    21 MAR 2025   Rajesh Gami     Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************
 EXEC SP_GetSubWorkOrderMPNsById 246
 **************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[SP_GetSubWorkOrderMPNsById] 
@SubWorkOrderId bigint =0
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN

		IF (@SubWorkOrderId >0)
		BEGIN
				SELECT 
					wop.SubWOPartNoId,
					ISNULL(wop.IsFinishGood,0)IsFinishGood,
					ISNULL(wop.IsClosed,0) AS isWOClose,
					im.PartNumber,
					im.PartDescription,
					im.ManufacturerName,
					ISNULL(ig.Description, '') AS ItemGroup,
					ISNULL(im.RevisedPart, '') AS RevisePartNo,
					con.Description AS Condition,
					wop.ItemMasterId,
					wop.ConditionId,
					ISNULL(wop.Quantity,0)Quantity,
					wop.SubWorkOrderScopeId,
					wop.SubWorkOrderStageId,
					wop.SubWorkOrderStatusId,
					wop.SubWorkOrderPriorityId,
					wop.CustomerRequestDate,
					wop.PromisedDate,
					wop.EstimatedCompletionDate,
					wop.EstimatedShipDate,
					wop.CMMIds,
					wop.CreatedBy,
					wop.CreatedDate,
					ISNULL(wop.IsActive,0)IsActive,
					ISNULL(wop.IsDeleted,0)IsDeleted,
					ISNULL(wop.IsDER,0)IsDER,
					ISNULL(wop.IsPMA,0)IsPMA,
					wop.MasterCompanyId,
					wop.NTE,
					wop.StockLineId,
					wop.SubWorkOrderId,
					wop.TATDaysCurrent,
					wop.TATDaysStandard,
					wop.TechnicianId,
					wop.TechStationId,
					ISNULL(emp.FirstName + ' ' + emp.LastName, '') AS TechnicianName,
					wop.UpdatedBy,
					wop.UpdatedDate,
					wop.WorkflowId,
					wop.WorkOrderId,
					0 WorkOrderMaterialsId,
					ISNULL(wop.RevisedSerialNumber, ISNULL(sl.SerialNumber, '')) AS SerialNumber,
					ISNULL(sl.StockLineNumber, '') AS StockLineNumber,
					ISNULL(sl.ControlNumber, '') AS ControlNumber,
					ISNULL(sl.IdNumber, '') AS ControlerId,
					(CASE WHEN wop.WorkflowId > 0 THEN (SELECT TOP 1 WorkflowExpirationDate FROM dbo.Workflow WITH(NOLOCK) WHERE WorkflowId = wop.WorkflowId) END) AS WorkflowExpirationDate,
					sl.SiteId,
					ISNULL(ssi.Name, '') AS Site,
					ISNULL(wh.Name, '') AS Warehouse,
					ISNULL(lo.Name, '') AS Location,
					ISNULL(sh.Name, '') AS Shelf,
					ISNULL(bi.Name, '') AS Bin,
					ISNULL(wop.IsTraveler,0)IsTraveler,
					ISNULL(wop.IsManualForm,0)IsManualForm,
					ISNULL(wop.islocked, 0) AS IsLocked
				FROM dbo.SubWorkOrderPartNumber wop WITH(NOLOCK)
				JOIN dbo.ItemMaster im WITH(NOLOCK) ON wop.ItemMasterId = im.ItemMasterId
				JOIN dbo.Condition con WITH(NOLOCK) ON wop.ConditionId = con.ConditionId
				LEFT JOIN dbo.Itemgroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN dbo.StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
				LEFT JOIN dbo.Site ssi WITH(NOLOCK) ON sl.SiteId = ssi.SiteId
				LEFT JOIN dbo.Warehouse wh WITH(NOLOCK) ON sl.WarehouseId = wh.WarehouseId
				LEFT JOIN dbo.Location lo WITH(NOLOCK) ON sl.LocationId = lo.LocationId
				LEFT JOIN dbo.Shelf sh WITH(NOLOCK) ON sl.ShelfId = sh.ShelfId
				LEFT JOIN dbo.Bin bi WITH(NOLOCK) ON sl.BinId = bi.BinId
				LEFT JOIN dbo.Employee emp WITH(NOLOCK) ON wop.TechnicianId = emp.EmployeeId
				WHERE wop.SubWorkOrderId = @SubWorkOrderId AND ISNULL(im.IsNonStock,0) = 0 ;
		END
		
	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[SP_GetSubWorkOrderMPNsById]',
            @ProcedureParameters varchar(3000) = '@SubWorkOrderId = ''' + CAST(ISNULL(@SubWorkOrderId, '') AS varchar(100)),
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
END