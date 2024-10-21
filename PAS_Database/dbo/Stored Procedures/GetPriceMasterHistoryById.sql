/*************************************************************           
 ** File:   [GetPriceMasterHistoryById]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used GetPriceMasterHistoryById
 ** Purpose:         
 ** Date:   08/10/2024      
          
 ** PARAMETERS: @ItemMasterPurchaseSaleId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2024  Ekta Chandegra     Created
     
-- exec [dbo].[GetPriceMasterHistoryById] @ItemMasterPurchaseSaleId=716
************************************************************************/


CREATE    PROCEDURE [dbo].[GetPriceMasterHistoryById]
@ItemMasterPurchaseSaleId BIGINT = NULL

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN
			SELECT ModuleName,RefferenceNumber,PartNumber,PNDescription,Manufacturer,
			ConditionName,PP_UOMName,PP_CurrencyName,PP_VendorListPrice,PP_PurchaseDiscPerc,
			PP_PurchaseDiscAmount,PP_UnitPurchasePrice,SalePriceSelectName,SP_FSP_UOMName,
			SP_FSP_CurrencyName,SP_FSP_FlatPriceAmount,SP_CalSPByPP_MarkUpPercOnListPrice,
			SP_CalSPByPP_MarkUpAmount,SP_CalSPByPP_UnitSalePrice, CreatedBy, CreatedDate,
			UpdatedDate,UpdatedBy, IsActive, IsDeleted
			FROM [dbo].[PriceMasterHistory] WITH (NOLOCK)
			WHERE ItemMasterPurchaseSaleId = @ItemMasterPurchaseSaleId
			ORDER BY UpdatedDate DESC
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPriceMasterHistoryById' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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