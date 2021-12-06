CREATE PROCEDURE [dbo].[SearchStockLineExchangePickTicketPop]
@ItemMasterIdlist bigint, 
@ConditionId BIGINT,
@ExchangeSalesOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			SELECT DISTINCT
			sop.ExchangeSalesOrderPartId
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
				 ,(sor.QtyToReserve - (SELECT ISNULL(SUM(QtyToShip), 0) FROM ExchangeSOPickTicket s WITH(NOLOCK) Where s.ExchangeSalesOrderId = @ExchangeSalesOrderId AND s.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId)) AS QtyToReserve
		FROM DBO.ItemMaster im WITH(NOLOCK)
		JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.IsDeleted = 0 
		LEFT JOIN DBO.ExchangeSalesOrderPart sop WITH(NOLOCK) on sop.StockLineId = sl.StockLineId
			AND sop.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
									THEN @ConditionId ELSE sl.ConditionId 
									END
		LEFT JOIN DBO.ExchangeSalesOrder so WITH(NOLOCK) on so.ExchangeSalesOrderId = sop.ExchangeSalesOrderId
		INNER JOIN DBO.ExchangeSalesOrderReserveParts sor WITH(NOLOCK) on sor.ExchangeSalesOrderId = so.ExchangeSalesOrderId AND sor.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
		LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId AND sl.IsDeleted = 0
		LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
		LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
		LEFT JOIN DBO.ExchangeSOPickTicket Pick WITH(NOLOCK) ON Pick.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId
		LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = im.ItemMasterId AND Smf.StockLineId = sl.StockLineId
		WHERE 
			im.ItemMasterId = @ItemMasterIdlist AND so.ExchangeSalesOrderId=@ExchangeSalesOrderId AND 
			(sor.QtyToReserve - (SELECT ISNULL(SUM(QtyToShip), 0) FROM ExchangeSOPickTicket s Where s.ExchangeSalesOrderId = @ExchangeSalesOrderId AND s.ExchangeSalesOrderPartId = sop.ExchangeSalesOrderPartId)) > 0
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SearchStockLineExchangePickTicketPop' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',
													 @Parameter2 = ' + ISNULL(@ConditionId,'') + ',
													 @Parameter3 = ' + ISNULL(@ExchangeSalesOrderId,'') + ''
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