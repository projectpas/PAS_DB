/*************************************************************                 
 ** File:  [getReceivingCustomerWorkById]      
 ** Author:    Shrey Chandegara   
 ** Description: Receiving CustomerWork By Id    
 ** Purpose:               
 ** Date:   20-Mar-2025      
                
 ** PARAMETERS:      
               
 ** RETURN VALUE:                 
 **************************************************************                 
 ** Change History                 
 **************************************************************                 
 ** PR   Date         Author			Change Description                  
 ** --   --------     -------		  --------------------------------                
	1    20-Mar-2025		Shrey Chandegara		Created  	
	2    16-Apr-2025		Abhishek Jirawla		Added Is Repair Management
	3	 16-JUL-2025        Moin Bloch   		    Added IsBatchStock And Batch Number
	4	 20-JAN-2026        Priyansh Patel  		Added CSN, TSN, CSO, TSO fields
	5	 24-FEB-2026        Moin Bloch   		    Added OutGoingItemMasterId And OutGoingPartNumber
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 --exec dbo.getReceivingCustomerWorkById 5837
      
**************************************************************/    
CREATE   PROCEDURE [dbo].[getReceivingCustomerWorkById]
@ReceivingCustomerWorkId BIGINT


AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION

		DECLARE @ModuleId BIGINT = 0;
		SET @ModuleId = (SELECT ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'RecevingCustomer')
			
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
					WHEN rc.OwnerTypeId = 1 THEN (SELECT Name FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = rc.Owner)
					WHEN rc.OwnerTypeId = 2 THEN (SELECT VendorName FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = rc.Owner)
					WHEN rc.OwnerTypeId = 3 THEN (SELECT Name FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE LegalEntityId = rc.Owner)
					WHEN rc.OwnerTypeId = 4 THEN rc.OwnerName
					ELSE CAST(rc.Owner AS VARCHAR)
				END AS OwnerName,
				CASE 
					WHEN rc.TraceableToTypeId = 1 THEN (SELECT Name FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 2 THEN (SELECT VendorName FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 3 THEN (SELECT Name FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE LegalEntityId = rc.TraceableTo)
					WHEN rc.TraceableToTypeId = 4 THEN rc.TraceableToName
					ELSE CAST(rc.TraceableTo AS VARCHAR)
				END AS TraceableToName,
				CASE 
					WHEN rc.ObtainFromTypeId = 1 THEN (SELECT Name FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = rc.ObtainFrom)
					WHEN rc.ObtainFromTypeId = 2 THEN (SELECT VendorName FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = rc.ObtainFrom)
					WHEN rc.ObtainFromTypeId = 3 THEN (SELECT Name FROM [dbo].[LegalEntity] WITH(NOLOCK) WHERE LegalEntityId = rc.ObtainFrom)
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
				rc.IsPiecePart,
				rc.IsRepairManagement,
				ISNULL(stk.IsBatchStock,0) IsBatchStock,
				stk.BatchNumber,
				rc.CSN,
				rc.TSN,
				rc.CSO,
				rc.TSO,
				rc.OutGoingItemMasterId,
				rc.OutGoingPartNumber
			FROM [dbo].[ReceivingCustomerWork] rc WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.ItemMasterId = im.ItemMasterId
			INNER JOIN [dbo].[CustomerContact] cc WITH(NOLOCK) ON rc.CustomerContactId = cc.CustomerContactId
			INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.ContactId = con.ContactId
			INNER JOIN [dbo].[Manufacturer] man WITH(NOLOCK) ON im.ManufacturerId = man.ManufacturerId
			INNER JOIN [dbo].[WorkOrderManagementStructureDetails] msd WITH(NOLOCK) ON rc.ReceivingCustomerWorkId = msd.ReferenceID AND msd.ModuleID = @ModuleId 
			LEFT JOIN [dbo].[ItemMaster] rp WITH(NOLOCK) ON im.ItemMasterId = rp.RevisedPartId
			 AND ISNULL(rp.IsNonStock,0) = 0 LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON rc.WorkOrderId = wo.WorkOrderId
			LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
			LEFT JOIN [dbo].[WOInspectionChecklist] woi WITH(NOLOCK) ON rc.ReceivingCustomerWorkId = woi.ReceivingCustomerWorkId
			LEFT JOIN [dbo].[ExchangeSalesOrder] eso WITH(NOLOCK) ON rc.ExchangeSalesOrderId = eso.ExchangeSalesOrderId
			LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId
			LEFT JOIN [dbo].[Stockline] stk WITH(NOLOCK) ON rc.StockLineId = stk.StockLineId
			WHERE rc.ReceivingCustomerWorkId = @ReceivingCustomerWorkId AND ISNULL(im.IsNonStock,0) = 0 ;


		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'getReceivingCustomerWorkById' 
			  , @ProcedureParameters VARCHAR(3000) = '@ReceivingCustomerWorkId = ''' + CAST(ISNULL(@ReceivingCustomerWorkId, '') AS VARCHAR(100))  
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