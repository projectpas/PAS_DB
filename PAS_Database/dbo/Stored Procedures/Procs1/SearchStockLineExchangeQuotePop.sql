
/*************************************************************           
 ** File:   [SearchStockLineExchangeQuotePop]           
 ** Author:  Unknown
 ** Description: Get Search Data for Exchange Quote  search for from part list tab
 ** Purpose:         
 ** Date:             
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1                 Unknown        Created
	2	 19-04-2024   Moin Bloch     Allow IsCustomerStock in Vendor Exchange PN-7409
	3    05-30-2025	  ABHISHEK JIRAWLA	Adding Traceability Changes
 	4    07/APR/2026  Rajesh Gami				Added UOM Changes [PN-15903]  
	5    15/APR/2026	  Rajesh Gami				Remove UOM Conversion for QUOTE: Need to display stock QTY [PN-15903]
-- EXEC [dbo].[SearchStockLineExchangeQuotePop] '240', 1, 401
************************************************************************/
CREATE   PROCEDURE [dbo].[SearchStockLineExchangeQuotePop]
@ItemMasterIdlist VARCHAR(max) = '', 
@ConditionId BIGINT,
@CustomerId BIGINT ,
@MappingType INT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				DECLARE @StockType int = 1;	
				SELECT DISTINCT
					im.PartNumber
					,sl.StockLineId
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,ig.Description AS ItemGroup
					,mf.Name AS Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,ic.ItemClassificationCode
					,ic.Description AS ItemClassification
					,ic.ItemClassificationId
					,c.Description ConditionDescription
					,c.ConditionId
					,'' AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS StockType
					,@MappingType AS MappingType
					,sl.StockLineNumber 
					,sl.SerialNumber
					,sl.ControlNumber
					,sl.IdNumber
					,uomConsume.ShortName AS UomDescription
					--, dbo.fn_ConvertUOM(ISNULL(sl.QuantityAvailable,0), uomStock.ShortName, uomConsume.ShortName,0,im.[MasterCompanyId]) QtyAvailable
					--, dbo.fn_ConvertUOM(ISNULL(sl.QuantityOnHand,0), uomStock.ShortName, uomConsume.ShortName,0,im.[MasterCompanyId]) QtyOnHand
					--, dbo.fn_ConvertUOM(ISNULL(sl.UnitCost,0), uomStock.ShortName, uomConsume.ShortName,1, im.[MasterCompanyId]) unitCost 
					, ISNULL(sl.QuantityAvailable,0) QtyAvailable
					, ISNULL(sl.QuantityOnHand,0) QtyOnHand
					, ISNULL(sl.UnitCost,0) unitCost 
					,sl.TraceableToName AS TracableToName
					,sl.OwnerName AS OwnerName
					,sl.ObtainFromName AS ObtainFromName
					
						 ,sl.TagDate
						 ,sl.TagType
						 ,sl.CertifiedBy
						 ,sl.CertifiedDate
						 ,sl.Memo
						 ,'Stock Line' AS Method
						 ,'S' AS MethodType
						 ,CONVERT(BIT,0) AS PMA
						 ,mf.Name as StkLineManufacturer
						 ,imel.ItemMasterLoanExchId
						 ,imel.IsLoan
						 ,imel.IsExchange
						 ,imel.ExchangeCurrencyId
						 ,imel.LoanCurrencyId
						 ,imel.ExchangeListPrice
						 ,imel.ExchangeCorePrice
						 ,imel.ExchangeOverhaulPrice
						 ,imel.ExchangeOutrightPrice
						 ,imel.ExchangeCoreCost
						 ,imel.LoanCorePrice
						 ,imel.LoanOutrightPrice
						 ,imel.LoanFees
						 ,imel.ExchangeOverhaulCost
						 ,imel.EFcogs as cogs
				FROM DBO.ItemMaster im WITH(NOLOCK)
				JOIN DBO.StockLine sl WITH(NOLOCK)ON im.ItemMasterId = sl.ItemMasterId 
					AND sl.isActive = 1 AND sl.IsDeleted = 0 
					--AND sl.ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
					AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL 
											THEN @ConditionId ELSE sl.ConditionId 
											END
				LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId
				LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId 
					AND sl.IsDeleted = 0
				LEFT JOIN DBO.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId 
					AND pop.ItemMasterId = im.ItemMasterId 
					AND pop.IsDeleted = 0 AND pop.isActive = 1
					AND pop.ItemTypeId = @StockType
				LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				--LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
				LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
				LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
				LEFT JOIN DBO.Customer cusObtain WITH(NOLOCK) ON sl.ObtainFrom = cusObtain.CustomerId
				LEFT JOIN DBO.Vendor vObtain WITH(NOLOCK) ON sl.ObtainFrom = vObtain.VendorId
				LEFT JOIN DBO.LegalEntity leObtain WITH(NOLOCK) ON sl.ObtainFrom = leObtain.LegalEntityId
				LEFT JOIN DBO.Customer cusOwner WITH(NOLOCK) ON sl.ObtainFrom = cusOwner.CustomerId
				LEFT JOIN DBO.Vendor vOwner WITH(NOLOCK) ON sl.ObtainFrom = vOwner.VendorId
				LEFT JOIN DBO.LegalEntity leOwner WITH(NOLOCK) ON sl.ObtainFrom = leOwner.LegalEntityId
				LEFT JOIN DBO.ItemMasterExchangeLoan imel WITH(NOLOCK) on imel.ItemMasterId = sl.ItemMasterId
				LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = sl.StockUnitOfMeasureId
				LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = sl.ConsumeUnitOfMeasureId
				WHERE 
				im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
				AND ISNULL(sl.QuantityAvailable, 0) > 0
				AND sl.IsParent = 1
		END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchStockLineExchangeQuotePop' 
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',
														@Parameter2 = ' + ISNULL(@ConditionId,'') + ', 
														@Parameter3 = ' + ISNULL(@CustomerId,'') + ', 
			                                            @Parameter4 = ' + ISNULL(@MappingType,'') +''
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