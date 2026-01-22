/*************************************************************           
 ** File:   [UpdatePriceMasterDetails]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used UpdatePriceMasterDetails
 ** Purpose:         
 ** Date:   20/09/2024      
          
 ** PARAMETERS: @tbl_PriceMasterDataType PriceMasterType
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    20/09/2024  Ekta Chandegra     Created
     
************************************************************************/

CREATE   PROCEDURE [DBO].[UpdatePriceMasterDetails]
@tbl_PriceMasterDataType PriceMasterType READONLY
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF((SELECT COUNT([ItemMasterId]) FROM @tbl_PriceMasterDataType) > 0 )
				BEGIN
					MERGE [DBO].[ItemMasterPurchaseSale] AS TARGET
					USING @tbl_PriceMasterDataType AS SOURCE ON (SOURCE.[ItemMasterId] = TARGET.[ItemMasterId] AND SOURCE.[ItemMasterPurchaseSaleId] = TARGET.[ItemMasterPurchaseSaleId] )
					WHEN MATCHED
						THEN UPDATE
						SET
						TARGET.[PartNumber] = SOURCE.[PartNumber],
						TARGET.[ConditionId] = SOURCE.[ConditionId],
						TARGET.[ConditionName] = SOURCE.[ConditionName],
						TARGET.[PP_UOMId] = SOURCE.[PP_UOMId] ,
						TARGET.[PP_UOMName] = SOURCE.[PP_UOMName] ,
						TARGET.[PP_CurrencyId] = SOURCE.[PP_CurrencyId],
						TARGET.[PP_CurrencyName] = SOURCE.[PP_CurrencyName],
						TARGET.[PP_VendorListPrice] = SOURCE.[PP_VendorListPrice],
						TARGET.[PP_PurchaseDiscPerc] = SOURCE.[PP_PurchaseDiscPerc],
						TARGET.[PP_PurchaseDiscAmount] = SOURCE.[PP_PurchaseDiscAmount],
						TARGET.[PP_LastPurchaseDiscDate] = SOURCE.[PP_LastPurchaseDiscDate],
						TARGET.[PP_UnitPurchasePrice] = SOURCE.[PP_UnitPurchasePrice],
						TARGET.[SalePriceSelectId]  = SOURCE.[SalePriceSelectId],
						TARGET.[SalePriceSelectName]  = SOURCE.[SalePriceSelectName],
						TARGET.[SP_FSP_UOMId] = SOURCE.[SP_FSP_UOMId], 
						TARGET.[SP_FSP_UOMName] = SOURCE.[SP_FSP_UOMName], 
						TARGET.[SP_FSP_CurrencyId] = SOURCE.[SP_FSP_CurrencyId],
						TARGET.[SP_FSP_CurrencyName] = SOURCE.[SP_FSP_CurrencyName],
						TARGET.[SP_FSP_FlatPriceAmount] = SOURCE.[SP_FSP_FlatPriceAmount],
						TARGET.[SP_CalSPByPP_MarkUpPercOnListPrice] = SOURCE.[SP_CalSPByPP_MarkUpPercOnListPrice] ,
						TARGET.[SP_CalSPByPP_MarkUpAmount] = SOURCE.[SP_CalSPByPP_MarkUpAmount],
						TARGET.[SP_CalSPByPP_LastSalesDiscDate] = SOURCE.[SP_CalSPByPP_LastSalesDiscDate],	
						TARGET.[SP_CalSPByPP_UnitSalePrice] = SOURCE.[SP_CalSPByPP_UnitSalePrice],
						TARGET.[MasterCompanyId] = SOURCE.[MasterCompanyId],
						TARGET.[UpdatedBy] = SOURCE.[UpdatedBy],
						TARGET.[UpdatedDate] = GETUTCDATE(),
						TARGET.[IsActive] = SOURCE.[IsActive] ,
						TARGET.[IsDeleted] = SOURCE.[IsDeleted];
					END
			END
		COMMIT TRANSACTION

	END TRY
	BEGIN CATCH
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdatePriceMasterDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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