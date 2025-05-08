/*************************************************************           
 ** File:   [USP_GetStocklinePrintDataByStockLineId]           
 ** Author:   Bhargav Saliya 
 ** Description: Get Stockline Print Data By StockLine Id
 ** Purpose:         
 ** Date:   07-May-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    07-May-2025   Bhargav Saliya		Created

**************************************************************/
CREATE OR ALTER  PROCEDURE [dbo].[USP_GetStocklinePrintDataByStockLineId]
	@StocklineId BIGINT,
	@WorkOrderMaterialsId BIGINT,
	@PickTicketId BIGINT,
	@SubWorkOrderMaterialId BIGINT = 0,
	@IsKitType BIT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	IF(@WorkOrderMaterialsId = 0 AND @SubWorkOrderMaterialId = 0)
	BEGIN
		SELECT TOP 1
			stl.StockLineId,
			stl.PartNumber,
			CASE 
				WHEN LEN(stl.PNDescription) > 28 THEN LEFT(stl.PNDescription, 28) + '...'
				ELSE stl.PNDescription
			END AS PartDescription,
			stl.StockLineNumber,
			stl.SerialNumber,
			stl.Condition,
			stl.ControlNumber,
			stl.Site AS siteName,
			stl.Warehouse,
			stl.Location,
			stl.Shelf AS shelfName,
			stl.Bin AS binName,
			ISNULL(ve.VendorName, '') AS VendorName,
			CASE 
				WHEN ISNULL(stl.QuantityOnHand, 0) > 0 THEN CAST(stl.QuantityOnHand AS INT)
				ELSE 0
			END AS Quantity,
			stl.IdNumber AS ControlId,
			ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
			stl.ExpirationDate,
			UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
			stl.ReceiverNumber AS Receiver,
			stl.ReceivedDate,
			stl.Memo AS Notes,
			stl.GlAccountName AS Class,
			stl.SerialNumber AS Barcode,
			stl.UpdatedDate,
			stl.IsSerialized,
			stl.TraceableToName,
			stl.UnitOfMeasure AS UnitOfMeasureName,
			'' AS MPNNum,
			wo.WorkOrderNum AS WoNum,
			CAST(0 AS BIT) AS IsFromSubWO,
			'' Figure,
            '' Item,
			'' MPNDesc
		FROM [dbo].[Stockline] stl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK)ON stl.ItemMasterId = im.ItemMasterId
			LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
			LEFT JOIN [dbo].[WorkOrderMaterials] womst WITH(NOLOCK) ON stl.WorkOrderMaterialsId = womst.WorkOrderMaterialsId
			LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON womst.WorkOrderId = wo.WorkOrderId
		WHERE ISNULL(stl.IsDeleted, 0) = 0 AND stl.StockLineId = @StocklineId;
	END
	ELSE IF(@SubWorkOrderMaterialId > 0)
	BEGIN
		SELECT TOP 1
            stl.StockLineId,
            stl.PartNumber,
            CASE 
                WHEN LEN(stl.PNDescription) > 28 THEN LEFT(stl.PNDescription, 28) + '...'
                ELSE stl.PNDescription
            END AS PartDescription,
            stl.StockLineNumber,
            stl.SerialNumber,
            stl.Condition,
            stl.ControlNumber,
            stl.Site AS siteName,
            stl.Warehouse,
            stl.Location,
            stl.Shelf AS shelfName,
            stl.Bin AS binName,
            ISNULL(ve.VendorName, '') AS VendorName,
            ISNULL(stl.QuantityOnHand, 0) AS Quantity,
            stl.IdNumber AS ControlId,
            ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
            stl.ExpirationDate,
            UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
            stl.ReceiverNumber AS Receiver,
            stl.ReceivedDate,
            stl.Memo AS Notes,
            stl.GlAccountName AS Class,
			'' AS Barcode, 
            stl.UpdatedDate,
            stl.IsSerialized,
            stl.TraceableToName,
            stl.UnitOfMeasure AS UnitOfMeasureName,
            wo.SubWorkOrderNo AS SubWorkOrderNo,
            im.PartNumber AS MPNNum,
			'' AS WoNum,
            im.PartDescription AS MPNDesc,
            mst.Figure,
            mst.Item,
            1 AS IsFromSubWO
        FROM [dbo].[Stockline] stl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
			LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
			LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
			LEFT JOIN [dbo].[SubWorkOrderMaterialStockLine] mst WITH(NOLOCK) ON stl.StockLineId = mst.StockLIneId AND mst.SubWorkOrderMaterialsId = @SubWorkOrderMaterialId
			LEFT JOIN [dbo].[SubWorkOrderMaterials] womst WITH(NOLOCK) ON mst.SubWorkOrderMaterialsId = womst.SubWorkOrderMaterialsId
			LEFT JOIN [dbo].[SubWorkOrder] wo WITH(NOLOCK) ON womst.SubWorkOrderId = wo.SubWorkOrderId
        WHERE ISNULL(stl.IsDeleted, 0) = 0 AND stl.StockLineId = @StocklineId
	END
	ELSE IF(@PickTicketId > 0)
	BEGIN
		IF(@IsKitType = 1)
		BEGIN
			SELECT TOP 1
				stl.StockLineId,
				stl.PartNumber,
				CASE
					WHEN LEN(stl.PNDescription) > 28 THEN SUBSTRING(stl.PNDescription, 1, 28) + '...'
					ELSE stl.PNDescription
				END AS PartDescription,
				stl.StockLineNumber,
				stl.SerialNumber,
				stl.Condition,
				stl.ControlNumber,
				stl.Site AS siteName,
				stl.Warehouse,
				stl.Location,
				stl.Shelf AS shelfName,
				stl.Bin AS binName,
				ISNULL(ve.VendorName, '') AS VendorName,
				ISNULL(stl.QuantityOnHand, 0) AS Quantity,
				stl.IdNumber AS ControlId,
				ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
				stl.ExpirationDate,
				UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
				stl.ReceiverNumber AS Receiver,
				stl.ReceivedDate,
				stl.Memo AS Notes,
				stl.GlAccountName AS Class,
				stl.StockLineNumber AS Barcode, 
				stl.UpdatedDate,
				stl.IsSerialized,
				wo.WorkOrderNum AS WoNum,
				itm.PartNumber AS MPNNum,
				itm.PartDescription AS MPNDesc,
				mst.Figure,
				mst.Item,
				CAST(0 AS BIT) AS IsFromSubWO,
				stl.TraceableToName,
				stl.UnitOfMeasure AS UnitOfMeasureName
			FROM [dbo].[Stockline] stl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
				LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] mst WITH(NOLOCK) ON stl.StockLineId = mst.StocklineId AND mst.WorkOrderMaterialsKitId = @WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderMaterialsKit] womst WITH(NOLOCK) ON mst.WorkOrderMaterialsKitId = womst.WorkOrderMaterialsKitId
				LEFT JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON womst.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wp WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wp.ID
				LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON wp.ItemMasterId = itm.ItemMasterId
				LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON womst.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON stl.StockLineId = wopt.StocklineId AND wopt.PickTicketId = @PickTicketId
			WHERE ISNULL(stl.IsDeleted, 0) = 0 AND stl.StockLineId = @StockLineId
		END 
		ELSE
		BEGIN
			SELECT TOP 1
				stl.StockLineId,
				stl.PartNumber,
				CASE 
					WHEN LEN(stl.PNDescription) > 28 THEN LEFT(stl.PNDescription, 28) + '...'
					ELSE stl.PNDescription
				END AS PartDescription,
				stl.StockLineNumber,
				stl.SerialNumber,
				stl.Condition,
				stl.ControlNumber,
				stl.Site AS siteName,
				stl.Warehouse,
				stl.Location,
				stl.Shelf AS shelfName,
				stl.Bin AS binName,
				ISNULL(ve.VendorName, '') AS VendorName,
				CASE WHEN stl.QuantityOnHand > 0 THEN CAST(stl.QuantityOnHand AS INT) ELSE 0 END AS Quantity,
				stl.IdNumber AS ControlId,
				ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
				stl.ExpirationDate,
				UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
				stl.ReceiverNumber AS Receiver,
				stl.ReceivedDate,
				stl.Memo AS Notes,
				stl.GlAccountName AS Class,
				stl.StockLineNumber AS Barcode,
				stl.UpdatedDate,
				stl.IsSerialized,
				wo.WorkOrderNum AS WoNum,
				itm.PartNumber AS MPNNum,
				itm.PartDescription AS MPNDesc,
				mst.Figure,
				mst.Item,
				CAST(0 AS BIT) AS IsFromSubWO,
				stl.TraceableToName,
				stl.UnitOfMeasure AS UnitOfMeasureName
			FROM [dbo].[Stockline] stl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
				LEFT JOIN [dbo].[WorkOrderMaterials] womst WITH(NOLOCK) ON stl.WorkOrderMaterialsId = womst.WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderMaterialStockLine] mst WITH(NOLOCK) ON stl.StockLineId = mst.StocklineId AND mst.WorkOrderMaterialsId = womst.WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON womst.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wp WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wp.ID
				LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON wp.ItemMasterId = itm.ItemMasterId
				LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON womst.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON stl.StockLineId = wopt.StocklineId AND wopt.PickTicketId = @PickTicketId
			WHERE ISNULL(stl.IsDeleted, 0) = 0
			  AND stl.StockLineId = @StockLineId;
		END
	END
	ELSE
	BEGIN
		IF(@IsKitType = 1)
		BEGIN
			SELECT TOP 1
				stl.StockLineId,
				stl.PartNumber,
				CASE 
					WHEN LEN(stl.PNDescription) > 28 THEN LEFT(stl.PNDescription, 28) + '...'
					ELSE stl.PNDescription
				END AS PartDescription,
				stl.StockLineNumber,
				stl.SerialNumber,
				stl.Condition,
				stl.ControlNumber,
				stl.Site AS siteName,
				stl.Warehouse,
				stl.Location,
				stl.Shelf AS shelfName,
				stl.Bin AS binName,
				ISNULL(ve.VendorName, '') AS VendorName,
				ISNULL(stl.QuantityOnHand, 0) AS Quantity,
				stl.IdNumber AS ControlId,
				ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
				stl.ExpirationDate,
				UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
				stl.ReceiverNumber AS Receiver,
				stl.ReceivedDate,
				stl.Memo AS Notes,
				stl.GlAccountName AS Class,
				stl.StockLineNumber AS Barcode,
				stl.UpdatedDate,
				stl.IsSerialized,
				wo.WorkOrderNum AS WoNum,
				itm.PartNumber AS MPNNum,
				itm.PartDescription AS MPNDesc,
				mst.Figure,
				mst.Item,
				0 AS IsFromSubWO,
				stl.TraceableToName,
				stl.UnitOfMeasure AS UnitOfMeasureName
			FROM [dbo].[Stockline] stl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
				LEFT JOIN [dbo].[WorkOrderMaterialStockLineKit] mst WITH(NOLOCK) ON stl.StockLineId = mst.StocklineId 
					AND mst.WorkOrderMaterialsKitId = @WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderMaterialsKit] womst WITH(NOLOCK) ON mst.WorkOrderMaterialsKitId = womst.WorkOrderMaterialsKitId
				LEFT JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON womst.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wp WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wp.ID
				LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON wp.ItemMasterId = itm.ItemMasterId
				LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON womst.WorkOrderId = wo.WorkOrderId
			WHERE ISNULL(stl.IsDeleted, 0) = 0 AND stl.StockLineId = @StocklineId
		END
		ELSE
		BEGIN
			SELECT TOP 1
				stl.StockLineId,
				stl.PartNumber,
				CASE 
					WHEN LEN(stl.PNDescription) > 28 THEN LEFT(stl.PNDescription, 28) + '...'
					ELSE stl.PNDescription
				END AS PartDescription,
				stl.StockLineNumber,
				stl.SerialNumber,
				stl.Condition,
				stl.ControlNumber,
				stl.Site AS siteName,
				stl.Warehouse,
				stl.Location,
				stl.Shelf AS shelfName,
				stl.Bin AS binName,
				ISNULL(ve.VendorName, '') AS VendorName,
				ISNULL(stl.QuantityOnHand, 0) AS Quantity,
				stl.IdNumber AS ControlId,
				ISNULL(po.PurchaseOrderNumber, '') AS PurchaseOrderNumber,
				stl.ExpirationDate,
				UPPER(ISNULL(stl.Manufacturer, '')) AS Manufacturer,
				stl.ReceiverNumber AS Receiver,
				stl.ReceivedDate,
				stl.Memo AS Notes,
				stl.GlAccountName AS Class,
				stl.StockLineNumber AS Barcode,
				stl.UpdatedDate,
				stl.IsSerialized,
				wo.WorkOrderNum AS WoNum,
				itm.PartNumber AS MPNNum,
				itm.PartDescription AS MPNDesc,
				mst.Figure,
				mst.Item,
				0 AS IsFromSubWO,
				stl.TraceableToName,
				stl.UnitOfMeasure AS UnitOfMeasureName
			FROM [dbo].[Stockline] stl WITH(NOLOCK)
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON stl.ItemMasterId = im.ItemMasterId
				LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[Vendor] ve WITH(NOLOCK) ON stl.VendorId = ve.VendorId
				LEFT JOIN [dbo].[WorkOrderMaterials] womst WITH(NOLOCK) ON stl.WorkOrderMaterialsId = womst.WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderMaterialStockLine] mst WITH(NOLOCK) ON stl.StockLineId = mst.StocklineId AND womst.WorkOrderMaterialsId = mst.WorkOrderMaterialsId
				LEFT JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON womst.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wp WITH(NOLOCK) ON wowf.WorkOrderPartNoId = wp.ID
				LEFT JOIN [dbo].[ItemMaster] itm WITH(NOLOCK) ON wp.ItemMasterId = itm.ItemMasterId
				LEFT JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON womst.WorkOrderId = wo.WorkOrderId
			WHERE ISNULL(stl.IsDeleted, 0) = 0 AND stl.StockLineId = @StocklineId
		END
	END
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetWOShippingLabel',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderMaterialsId, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@PickTicketId, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@SubWorkOrderMaterialId, '') AS varchar(100)) + 
			'@Parameter5 = ''' + CAST(ISNULL(@IsKitType, '') AS varchar(100)),  
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
END
