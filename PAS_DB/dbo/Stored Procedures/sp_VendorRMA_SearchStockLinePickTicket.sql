/*************************************************************           
 ** File:   [dbo].[sp_VendorRMA_SearchStockLinePickTicket]          
 ** Author:   Amit Ghediya
 ** Description: Get pick ticket stockline data to pick for Vendor RMA.
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/22/2023   Amit Ghediya   created
	2    06/23/2023   Amit Ghediya   Get Data Based on ItemMasterId.
	3    07/04/2023   Amit Ghediya   Updated for get Qty base ticket.

-- EXEC [dbo].[sp_VendorRMA_SearchStockLinePickTicket] 330,1,42,0
-- EXEC [dbo].[sp_VendorRMA_SearchStockLinePickTicket] 1,1,42,1
**************************************************************/ 
CREATE       PROCEDURE [dbo].[sp_VendorRMA_SearchStockLinePickTicket]
	@ItemMasterIdlist bigint, 
	@ConditionId BIGINT,
	@VendorRMAId bigint,
	@IsMultiplePickTicket bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@IsMultiplePickTicket =1)
		BEGIN
			SELECT DISTINCT
					sop.VendorRMADetailId
					,so.VendorRMAId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sl.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL(((SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMADetailId = sop.VendorRMADetailId AND ItemMasterId = sop.ItemMasterId) - SUM(ISNULL(Pick.QtyToShip,0))),0) as QtyToPick
					,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
							ELSE
								''
							END
						 AS TracableToName
						 ,sl.TagDate
						 ,sl.TagType
						 ,sl.CertifiedBy
						 ,sl.CertifiedDate
						 ,sl.Memo
						 ,'Stock Line' AS Method
						 ,'S' AS MethodType
						 ,CONVERT(BIT,0) AS PMA
						 ,Smf.Name as StkLineManufacturer
						 ,((
						 (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.RMAShipping ship WITH(NOLOCK) LEFT JOIN RMAShippingItem ship_item WITH(NOLOCK) on ship_item.RMAShippingItemId = ship.RMAShippingId AND ship.VendorRMAId = @VendorRMAId and ship_item.VendorRMADetailId = sop.VendorRMADetailId)) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM RMAPickTicket s WITH(NOLOCK) Where s.VendorRMAId = @VendorRMAId AND s.VendorRMADetailId = sop.VendorRMADetailId)) AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
				LEFT JOIN DBO.VendorRMADetail sop on sop.StockLineId = sl.StockLineId
				LEFT JOIN DBO.VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sop.VendorRMAId
				--INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.RMAPickTicket Pick WITH(NOLOCK) ON Pick.VendorRMADetailId = sop.VendorRMADetailId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					so.VendorRMAId = @VendorRMAId 
					--AND 
					--((
					--(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.RMAShipping ship WITH(NOLOCK) LEFT JOIN RMAShippingItem ship_item WITH(NOLOCK) on ship_item.RMAShippingId = ship.RMAShippingId AND ship.VendorRMAId = @VendorRMAId and ship_item.VendorRMADetailId = sop.VendorRMADetailId)) - 
					--(SELECT ISNULL(SUM(QtyToShip), 0) FROM RMAPickTicket s WITH(NOLOCK) Where s.VendorRMAId = @VendorRMAId AND s.VendorRMADetailId = sop.VendorRMADetailId)) > 0
				GROUP BY sop.VendorRMADetailId,im.PartNumber,sl.StockLineId,im.ItemMasterId ,im.ItemMasterId,im.PartDescription ,ig.Description ,mf.Name,im.ManufacturerId,sl.ConditionId
					,sl.StockLineNumber ,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,sl.QuantityAvailable,sl.QuantityOnHand,im.IsPma,im.IsDER,so.VendorRMAId ,sop.ItemMasterId,sl.PurchaseOrderUnitCost
					,sl.TraceableToType,cusTraceble.Name,vTraceble.VendorName,leTraceble.Name,sl.TraceableTo,sl.TagType,sl.TagDate,sl.CertifiedBy,sl.CertifiedDate,sl.Memo,Smf.Name
		END
		ELSE
		BEGIN
			SELECT DISTINCT
					sop.VendorRMADetailId,
					so.VendorRMAId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sl.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
					,ISNULL(((SELECT TOP 1 Qty FROM VendorRMADetail WITH(NOLOCK) Where VendorRMADetailId = sop.VendorRMADetailId AND ItemMasterId = sop.ItemMasterId) - SUM(ISNULL(Pick.QtyToShip,0))),0) as QtyToPick
					,ISNULL(sl.PurchaseOrderUnitCost, 0) AS unitCost
					,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
							WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
							WHEN sl.TraceableToType = 9 THEN leTraceble.Name
							WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
							ELSE
								''
							END
						 AS TracableToName
						 ,sl.TagDate
						 ,sl.TagType
						 ,sl.CertifiedBy
						 ,sl.CertifiedDate
						 ,sl.Memo
						 ,'Stock Line' AS Method
						 ,'S' AS MethodType
						 ,CONVERT(BIT,0) AS PMA
						 ,Smf.Name as StkLineManufacturer
						 ,(((SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.RMAShipping ship WITH(NOLOCK) LEFT JOIN RMAShippingItem ship_item WITH(NOLOCK) on ship_item.RMAShippingId = ship.RMAShippingId AND ship.VendorRMAId = @VendorRMAId and ship_item.VendorRMADetailId = sop.VendorRMADetailId)) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM RMAPickTicket s WITH(NOLOCK) Where s.VendorRMAId = @VendorRMAId AND s.VendorRMADetailId = sop.VendorRMADetailId)) 
						 AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
				LEFT JOIN DBO.VendorRMADetail sop on sop.StockLineId = sl.StockLineId
					--AND sop.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
											--THEN @ConditionId ELSE sl.ConditionId 
											--END
				LEFT JOIN DBO.VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sop.VendorRMAId
				--INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.RMAPickTicket Pick WITH(NOLOCK) ON Pick.VendorRMADetailId = sop.VendorRMADetailId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					im.ItemMasterId = @ItemMasterIdlist AND 
					--so.VendorRMAId = @VendorRMAId 
					sop.VendorRMADetailId = @VendorRMAId 
					--AND 
					--(((SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.RMAShipping ship WITH(NOLOCK) LEFT JOIN RMAShippingItem ship_item WITH(NOLOCK) on ship_item.RMAShippingId = ship.RMAShippingId AND ship.VendorRMAId = @VendorRMAId and ship_item.VendorRMADetailId = sop.VendorRMADetailId)) - 
					--(SELECT ISNULL(SUM(QtyToShip), 0) FROM RMAPickTicket s WITH(NOLOCK) Where s.VendorRMAId = @VendorRMAId AND s.VendorRMADetailId = sop.VendorRMADetailId)
					--) > 0
				GROUP BY sop.VendorRMADetailId,im.PartNumber,sl.StockLineId,im.ItemMasterId ,im.ItemMasterId,im.PartDescription ,ig.Description ,mf.Name,im.ManufacturerId,sl.ConditionId
					,sl.StockLineNumber ,sl.SerialNumber,sl.ControlNumber,sl.IdNumber,sl.QuantityAvailable,sl.QuantityOnHand,im.IsPma,im.IsDER,so.VendorRMAId ,sop.ItemMasterId,sl.PurchaseOrderUnitCost
					,sl.TraceableToType,cusTraceble.Name,vTraceble.VendorName,leTraceble.Name,sl.TraceableTo,sl.TagType,sl.TagDate,sl.CertifiedBy,sl.CertifiedDate,sl.Memo,Smf.Name
					
		END

				
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_VendorRMA_SearchStockLinePickTicket' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',
													 @Parameter2 = ' + ISNULL(@ConditionId,'') + ',
													 @Parameter3 = ' + ISNULL(@VendorRMAId,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END