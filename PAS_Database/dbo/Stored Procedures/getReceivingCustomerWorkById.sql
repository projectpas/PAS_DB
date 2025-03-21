/***************************************************************  
 ** File:   [getReceivingCustomerWorkById]             
 ** Author:   Shrey Chandegara
 ** Description: Receiving CustomerWork By Id
 ** Date:  20-03-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    20-Mar-2025		Shrey Chandegara		Created  	
		
	exec dbo.getReceivingCustomerWorkById 5837
**************************************************************/
CREATE   PROCEDURE [dbo].[getReceivingCustomerWorkById]
@ReceivingCustomerWorkId BIGINT


AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @ModuleId BIGINT = 0;
		SET @ModuleId = (SELECT ManagementStructureModuleId FROM ManagementStructureModule WHERE ModuleName = 'RecevingCustomer')
			
			SELECT 
				ISNULL(wo.WorkOrderNum, '') AS WONum,
				ISNULL(wo.CreatedBy, '') AS WOCreatedBy,
				ISNULL(CONVERT(VARCHAR, wo.CreatedDate, 101), '') AS WOCreatedDate,
				con.FirstName + ' ' + con.LastName AS CustomerContact,
				con.WorkPhone + ' ' + con.WorkPhoneExtn AS ContactPhone,
				im.PartNumber,
				im.PartDescription,
				man.Name AS Manufacturer,
				COALESCE(rp.PartNumber, '') AS RevisedPart,
				rc.TagType,
				rc.TagTypeIds,
				rc.Site,
				rc.Warehouse,
				rc.Location,
				rc.Shelf,
				rc.Bin,
				rc.WorkScope AS workScopeName,
				rc.Condition,
				im.PurchaseUnitOfMeasureId,
				ISNULL(uom.ShortName, '') AS PurchaseUnitOfMeasure,
				rc.RemovalReasonId,
				rc.RemovalReasons,
				rc.RemovalReasonsMemo,
				CASE 
					WHEN rc.OwnerTypeId = 1 THEN 'Customer'
					WHEN rc.OwnerTypeId = 2 THEN 'Vendor'
					WHEN rc.OwnerTypeId = 3 THEN 'Company'
					WHEN rc.OwnerTypeId = 4 THEN 'Others'
					ELSE ''
				END AS OwnerType,
				CASE 
					WHEN rc.TraceableToTypeId = 1 THEN 'Customer'
					WHEN rc.TraceableToTypeId = 2 THEN 'Vendor'
					WHEN rc.TraceableToTypeId = 3 THEN 'Company'
					WHEN rc.TraceableToTypeId = 4 THEN 'Others'
					ELSE ''
				END AS TracableToType,
				CASE 
					WHEN rc.ObtainFromTypeId = 1 THEN 'Customer'
					WHEN rc.ObtainFromTypeId = 2 THEN 'Vendor'
					WHEN rc.ObtainFromTypeId = 3 THEN 'Company'
					WHEN rc.ObtainFromTypeId = 4 THEN 'Others'
					ELSE ''
				END AS ObtainFromType,
				im.ItemGroupId,
				ISNULL(ig.ItemGroupCode, '') AS ItemGroup,
				CASE 
					WHEN rc.OwnerTypeId = 1 THEN (SELECT Name FROM Customer WHERE CustomerId = rc.Owner)
					WHEN rc.OwnerTypeId = 2 THEN (SELECT VendorName FROM Vendor WHERE VendorId = rc.Owner)
					WHEN rc.OwnerTypeId = 3 THEN (SELECT Name FROM LegalEntity WHERE LegalEntityId = rc.Owner)
					WHEN rc.OwnerTypeId = 4 THEN rc.OwnerName
					ELSE CAST(rc.Owner AS VARCHAR)
				END AS OwnerName,
				CASE 
					WHEN rc.TraceableToTypeId = 1 THEN (SELECT Name FROM Customer WHERE CustomerId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 2 THEN (SELECT VendorName FROM Vendor WHERE VendorId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 3 THEN (SELECT Name FROM LegalEntity WHERE LegalEntityId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 4 THEN rc.TraceableToName
					ELSE CAST(rc.TraceableTo AS VARCHAR)
				END AS TraceableToName,
				CASE 
					WHEN rc.ObtainFromTypeId = 1 THEN (SELECT Name FROM Customer WHERE CustomerId = rc.ObtainFrom)
					WHEN rc.ObtainFromTypeId = 2 THEN (SELECT VendorName FROM Vendor WHERE VendorId = rc.ObtainFrom)
					WHEN rc.ObtainFromTypeId = 3 THEN (SELECT Name FROM LegalEntity WHERE LegalEntityId = rc.ObtainFrom)
					WHEN rc.ObtainFromTypeId = 4 THEN rc.ObtainFromName
					ELSE CAST(rc.ObtainFrom AS VARCHAR)
				END AS ObtainFromName,
				rc.BinId,
				rc.InspectedBy,
				rc.InspectedById,
				rc.InspectedDate,
				rc.TaggedBy,
				rc.TagDate,
				rc.TaggedById,
				rc.TaggedByType,
				rc.TaggedByTypeName,
				rc.CertifiedDate,
				rc.CustomerCode,
				rc.CustomerName,
				rc.EmployeeName,
				rc.CertifiedBy,
				rc.CertifiedById,
				rc.CertifiedTypeId,
				rc.CertifiedType,
				rc.ConditionId,
				rc.CreatedBy,
				rc.CreatedDate,
				rc.CustomerContactId,
				rc.CustomerId,
				rc.EmployeeId,
				rc.ExpDate,
				rc.IsActive,
				rc.IsCustomerStock,
				rc.IsDeleted,
				rc.IsExpDate,
				rc.IsMFGDate,
				rc.IsSerialized,
				rc.IsTimeLife,
				rc.ItemMasterId,
				rc.LocationId,
				rc.WorkScopeId,
				rc.ManagementStructureId,
				im.ManufacturerId,
				rc.MasterCompanyId,
				rc.Memo,
				rc.MFGDate,
				rc.MFGLotNo,
				rc.MFGTrace,
				rc.ObtainFrom,
				rc.ObtainFromTypeId,
				rc.Owner,
				rc.OwnerTypeId,
				rc.PartCertificationNumber,
				rc.Quantity,
				rc.ReceivingCustomerWorkId,
				rc.ReceivingNumber,
				rc.Reference,
				im.RevisedPartId AS RevisePartId,
				rc.SerialNumber,
				rc.ShelfId,
				rc.SiteId,
				rc.StockLineId,
				rc.TimeLifeCyclesId,
				rc.TimeLifeDate,
				rc.TimeLifeOrigin,
				rc.TraceableTo,
				rc.TraceableToTypeId,
				rc.UpdatedBy,
				rc.UpdatedDate,
				rc.WarehouseId,
				rc.WorkOrderId,
				rc.IsSkipSerialNo,
				rc.IsSkipTimeLife,
				rc.ReceivedDate,
				rc.CustReqDate,
				rc.ACTailNum,
				rc.CertTypeId,
				rc.CertType,
				rc.ExchangeSalesOrderId,
				rc.CustReqTagType,
				rc.CustReqTagTypeId,
				rc.CustReqCertType,
				rc.CustReqCertTypeId,
				ISNULL(woi.WOInspectionId, 0) AS WOInspectionId,
				rc.ManagementStructureId AS EntityStructureId,
				msd.LastMSLevel,
				msd.AllMSlevels,
				im.IsExpirationDateAvailable,
				eso.ExchangeSalesOrderNumber,
				im.IsManufacturingDateAvailable,
				im.IsReceivedDateAvailable,
				im.IsTagDateAvailable,
				rc.IsPiecePart
			FROM ReceivingCustomerWork rc WITH(NOLOCK)
			JOIN ItemMaster im WITH(NOLOCK) ON rc.ItemMasterId = im.ItemMasterId
			JOIN CustomerContact cc WITH(NOLOCK) ON rc.CustomerContactId = cc.CustomerContactId
			JOIN Contact con WITH(NOLOCK) ON cc.ContactId = con.ContactId
			JOIN Manufacturer man WITH(NOLOCK) ON im.ManufacturerId = man.ManufacturerId
			JOIN WorkOrderManagementStructureDetails msd WITH(NOLOCK) ON rc.ReceivingCustomerWorkId = msd.ReferenceID AND msd.ModuleID = @ModuleId 
			LEFT JOIN ItemMaster rp WITH(NOLOCK) ON im.ItemMasterId = rp.RevisedPartId
			LEFT JOIN WorkOrder wo WITH(NOLOCK) ON rc.WorkOrderId = wo.WorkOrderId
			LEFT JOIN ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
			LEFT JOIN WOInspectionChecklist woi WITH(NOLOCK) ON rc.ReceivingCustomerWorkId = woi.ReceivingCustomerWorkId
			LEFT JOIN ExchangeSalesOrder eso WITH(NOLOCK) ON rc.ExchangeSalesOrderId = eso.ExchangeSalesOrderId
			LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			WHERE rc.ReceivingCustomerWorkId = @ReceivingCustomerWorkId;


		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'getReceivingCustomerWorkById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReceivingCustomerWorkId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
	
END