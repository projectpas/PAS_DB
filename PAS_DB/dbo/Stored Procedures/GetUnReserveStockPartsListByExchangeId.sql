/*************************************************************             
 ** File:   [USP_ReserveStocklineForReceivingPO]            
 ** Author:   Rajesh Gami  
 ** Description: This stored procedure is used to get Un Reserv eStockPartsList By ExchangeId
 ** Purpose:           
 ** Date:   21/10/2023          
            
 ** PARAMETERS:  
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1   21/10/2023    Rajesh Gami		Created

exec dbo.GetUnReserveStockPartsListByExchangeId 120
**************************************************************/  
CREATE     PROC [dbo].[GetUnReserveStockPartsListByExchangeId]
@ExchangeId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
			SELECT DISTINCT so.ExchangeSalesOrderId, im.ItemMasterId, sop.ConditionId, cond.Description as Condition, 0 AS ExchangeSalesOrderPartId,
			im.PartNumber, im.PartDescription, 
			im.ManufacturerName ManufacturerName,
			sop.QtyQuoted as Quantity
			, ISNULL(sor.ReservedById, 0) ReservedById
			, ISNULL(sor.IssuedById, 0) IssuedById
			, '5' as PartStatusId
			, ISNULL(sor.IsAltPart, 0) IsAltPart, ISNULL(sor.IsEquPart, 0) IsEquPart
			, sor.AltPartMasterPartId, sor.EquPartMasterPartId
			, 0 AS QtyToReserve
			, ISNULL(SL.QuantityReserved, 0) QuantityReserved
			, sl.QuantityAvailable, sl.QuantityOnHand, sl.QuantityOnOrder, sl.StockLineId
			, sl.StockLineNumber, sl.ControlNumber,
			CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' ELSE (CASE WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' ELSE (CASE WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER' ELSE 'OEM' END) END) END as StockType
			,SO.MasterCompanyId
			,SOR.ExchangeSalesOrderReservePartId
			,SOr.ReservedDate
			,sor.IssuedDate
			,ISNULL(sor.QtyToReserve,0) AS QtyToUnReserve
			, ((ISNULL(SOP.QtyQuoted,0)) - (ISNULL(SL.QuantityReserved,0))) AS QtyToReserve
			,sl.QuantityIssued
			,sl.QuantityToReceive
			,SOR.TotalReserved
			,SOR.ExchangeSalesOrderReservePartId
			FROM ExchangeSalesOrder SO WITH (NOLOCK)
			INNER JOIN ExchangeSalesOrderPart SOP WITH (NOLOCK) ON SO.ExchangeSalesOrderId = SOP.ExchangeSalesOrderId
			LEFT JOIN ItemMaster im WITH (NOLOCK) on sop.ItemMasterId = im.ItemMasterId
			LEFT JOIN DBO.Customer C WITH (NOLOCK) ON SO.CustomerId = C.CustomerId AND ISNULL(SO.IsVendor,0) = 0
			LEFT JOIN DBO.Vendor V WITH (NOLOCK) ON SO.CustomerId = V.VendorId AND ISNULL(SO.IsVendor,0) = 1
			LEFT JOIN ExchangeSalesOrderReserveParts SOR WITH (NOLOCK) ON sop.ExchangeSalesOrderPartId = SOR.ExchangeSalesOrderPartId AND SOR.TotalReserved >0
			LEFT JOIN StockLine SL WITH (NOLOCK) ON SOR.StockLineId = SL.StockLineId --im.ItemMasterId = sl.ItemMasterId
			LEFT JOIN Condition cond WITH (NOLOCK) ON sop.ConditionId = cond.ConditionId
			WHERE so.IsDeleted = 0 AND sop.IsDeleted = 0 AND so.ExchangeSalesOrderId = @ExchangeId AND (CASE WHEN ISNULL(SOR.ExchangeSalesOrderReservePartId,0) > 0 THEN 
																																 CASE WHEN SOR.TotalReserved > 0 THEN 1 ELSE 0 END
																																 ELSE 1 END) = 1		
		END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetReserveStockPartsListByExchangeSOId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ExchangeId, '') + ''
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