CREATE PROCEDURE [dbo].[SearchItemMasterExchangeQuotePop]
@ItemMasterIdlist VARCHAR(max) = '284', 
--@ConditionId BIGINT = NULL,
@ConditionIds VARCHAR(100) = '40',
@CustomerId BIGINT = 340,
@MappingType INT = -1

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT
				im.PartNumber
				,im.ItemMasterId As PartId
				,im.ItemMasterId As ItemMasterId
				,im.IsPma
				,im.IsDER
				,im.PartDescription AS Description
				,SUM(ISNULL(sl.QuantityAvailable, 0)) AS QtyAvailable
				,SUM(ISNULL(sl.QuantityOnHand, 0)) AS QtyOnHand
				,ig.Description AS ItemGroup
				,mf.Name Manufacturer
				,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
				,ic.ItemClassificationCode
				,ic.Description AS ItemClassification
				,ic.ItemClassificationId
				,c.ConditionId ConditionId
				,c.Description ConditionDescription
				,ISNULL(STUFF((
			    SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M INNER JOIN ItemMaster I ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
			    FOR XML PATH('')
			    )
			    ,1,1,''), '') AlternateFor
				,CASE 
					WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber --'PMA&DER'
					WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber --'PMA'
					WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
					END AS Oempmader
				,@MappingType AS MappingType
				,imps.PP_UnitPurchasePrice AS UnitCost
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
			FROM DBO.ItemMaster im WITH (NOLOCK)
			LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId in (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
			LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId 
				AND sl.IsDeleted = 0 AND sl.isActive = 1 AND sl.IsParent = 1 AND sl.IsCustomerStock = 0
			LEFT JOIN DBO.PurchaseOrder po WITH (NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId 
				AND sl.IsDeleted = 0
			--LEFT JOIN DBO.PurchaseOrderPart pop WITH (NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId 
			--	AND pop.ItemMasterId = im.ItemMasterId 
			--	AND pop.IsDeleted = 0
			LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
			LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
			LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
			LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster WITH (NOLOCK)) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
			LEFT JOIN DBO.ItemMasterPurchaseSale imps on imps.ItemMasterId = im.ItemMasterId
						and imps.ConditionId = c.ConditionId
			LEFT JOIN DBO.ItemMasterExchangeLoan imel WITH (NOLOCK) on imel.ItemMasterId = im.ItemMasterId
			WHERE 
				im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
			GROUP BY
				im.PartNumber
				,im.ItemMasterId 
				,im.PartDescription
				,ig.Description 
				,mf.Name 
				,im.ManufacturerId
				,ic.ItemClassificationCode
				,ic.Description
				,ic.ItemClassificationId
				,c.Description
				,c.ConditionId
				,im.IsPma
				,im.IsDER
				,OEMPMA.partnumber
				,sl.ItemMasterId
				,imps.PP_UnitPurchasePrice
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
				,imel.ExchangeOverhaulCost,
				imel.EFcogs
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchItemMasterExchangeQuotePop' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''', @Parameter2 = ' + ISNULL(@ConditionIds,'') + ', @Parameter3 = ' + ISNULL(@CustomerId ,'') +''
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