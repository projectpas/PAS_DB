/*************************************************************           
 ** File:   [dbo].[SearchStockLinePickTicketPop]          
 ** Author:   Vishal Suthar
 ** Description: Get pick ticket stockline data to pick
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/15/2023   Vishal Suthar Updated the SP to handle invoice before shipping and versioning
    2    06/21/2023   Vishal Suthar Updated the SP to include pick ticket even after invoice is created
    3    10/15/2024   Vishal Suthar Modified SP to get Pick ticket stockline list from new SO Part tables

EXEC [dbo].[SearchStockLinePickTicketPop] 3, 7, 1103, 0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[SearchStockLinePickTicketPop]
	@ItemMasterIdlist bigint, 
	@ConditionId BIGINT,
	@SalesOrderId bigint,
	@IsMultiplePickTicket bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	--  [dbo].[SearchStockLinePickTicketPop] 272,1,82,1
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@IsMultiplePickTicket =1)
		BEGIN
			SELECT DISTINCT
					sop.SalesOrderPartId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sop.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					--,@MappingType AS MappingType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					--,uom.ShortName AS UomDescription
					,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
					,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand
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
						 ,((sor.QtyToReserve + 
						 (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId)) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM SOPickTicket s WITH(NOLOCK) Where s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartId = sop.SalesOrderPartId)) AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				LEFT JOIN DBO.SalesOrderStocklineV1 stk on stk.StockLineId = sl.StockLineId
				LEFT JOIN DBO.SalesOrderPartV1 sop on sop.SalesOrderPartId = stk.SalesOrderPartId
				LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.SOPickTicket Pick WITH(NOLOCK) ON Pick.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					so.SalesOrderId = @SalesOrderId AND 
					((sor.QtyToReserve + 
					(SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId)) - 
					(SELECT ISNULL(SUM(QtyToShip), 0) FROM SOPickTicket s WITH(NOLOCK) Where s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartId = sop.SalesOrderPartId)) > 0
		END
		ELSE
		BEGIN
			SELECT DISTINCT
					sop.SalesOrderPartId
					,im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,sop.ConditionId
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
						 ,((sor.QtyToReserve + (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId)) - 
						 (SELECT ISNULL(SUM(QtyToShip), 0) FROM SOPickTicket s WITH(NOLOCK) Where s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartId = sop.SalesOrderPartId))
						 AS QtyToReserve
				FROM DBO.ItemMaster im  WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0
				LEFT JOIN DBO.SalesOrderStocklineV1 stk on stk.StockLineId = sl.StockLineId
				LEFT JOIN DBO.SalesOrderPartV1 sop on sop.SalesOrderPartId = stk.SalesOrderPartId
				LEFT JOIN DBO.SalesOrder so WITH(NOLOCK) on so.SalesOrderId = sop.SalesOrderId
				INNER JOIN DBO.SalesOrderReserveParts sor WITH(NOLOCK) on sor.SalesOrderId = so.SalesOrderId AND sor.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.SOPickTicket Pick WITH(NOLOCK) ON Pick.SalesOrderPartId = sop.SalesOrderPartId
				LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK) INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
				WHERE 
					im.ItemMasterId = @ItemMasterIdlist AND 
					so.SalesOrderId = @SalesOrderId AND 
					((sor.QtyToReserve + (SELECT ISNULL(SUM(ship_item.QtyShipped), 0) FROM DBO.SalesOrderShipping ship WITH(NOLOCK) LEFT JOIN SalesOrderShippingItem ship_item WITH(NOLOCK) on ship_item.SalesOrderShippingId = ship.SalesOrderShippingId AND ship.SalesOrderId = @SalesOrderId and ship_item.SalesOrderPartId = sop.SalesOrderPartId)) - 
					(SELECT ISNULL(SUM(QtyToShip), 0) FROM SOPickTicket s WITH(NOLOCK) Where s.SalesOrderId = @SalesOrderId AND s.SalesOrderPartId = sop.SalesOrderPartId)
					) > 0
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
            , @AdhocComments     VARCHAR(150)    = 'SearchStockLinePickTicketPop' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',
													 @Parameter2 = ' + ISNULL(@ConditionId,'') + ',
													 @Parameter3 = ' + ISNULL(@SalesOrderId,'') + ''
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