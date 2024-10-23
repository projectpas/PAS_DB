/*************************************************************           
 ** File:   [ItemMasterPriceListForBulkUpdate]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used ItemMasterPriceListForBulkUpdate
 ** Purpose:         
 ** Date:   30/08/2024      
          
 ** PARAMETERS: @ItemMasterId BIGINT, @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    30/08/2024  Ekta Chandegra     Created
     
--exec dbo.ItemMasterPriceListForBulkUpdate @ItemMasterId=0,@MasterCompanyId=1

************************************************************************/

CREATE      PROCEDURE [dbo].[ItemMasterPriceListForBulkUpdate]
(
	@ItemMasterId BIGINT,
	@MasterCompanyId BIGINT
)
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED        
	  SET NOCOUNT ON          
		  IF @ItemMasterId = 0      
		  BEGIN      
			SET @ItemMasterId = NULL      
		  END 
	BEGIN TRY 
		SELECT DISTINCT 
		IM.ItemMasterId,
		IM.PartNumber,
		IM.PartDescription,
		IM.ManufacturerId,
		IM.ManufacturerName,
		IM.MasterCompanyId,
		IM.UpdatedBy,
		IM.UpdatedDate,
		IM.IsActive,
		IM.IsDeleted,
		IM.CreatedBy,
		IM.CreatedDate
		FROM [DBO].[ItemMaster] IM WITH (NOLOCK)
		LEFT JOIN [DBO].ItemMasterPurchaseSale IMPS  WITH (NOLOCK)  ON IMPS.ItemMasterId = IM.ItemMasterId
		WHERE IM.MasterCompanyId = @MasterCompanyId
		AND (@ItemMasterId IS NULL OR IM.ItemMasterId = @ItemMasterId)
		AND IM.IsActive = 1
		AND IM.IsDeleted = 0

		SELECT
		IMPS.ItemMasterId,
		IMPS.PartNumber,
		IMPS.ConditionId,
		IMPS.ConditionName,
		IMPS.ItemMasterPurchaseSaleId,
		IMPS.PP_CurrencyId,
		IMPS.PP_CurrencyName,
		ISNULL(IMPS.PP_FXRatePerc,0) AS PP_FXRatePerc,
		IMPS.PP_LastListPriceDate,
		IMPS.PP_LastPurchaseDiscDate,
		ISNULL(IMPS.PP_PurchaseDiscPerc,0) AS PP_PurchaseDiscPerc,
		ISNULL(IMPS.PP_PurchaseDiscAmount,0) AS PP_PurchaseDiscAmount,
		ISNULL(IMPS.PP_UnitPurchasePrice,0) AS PP_UnitPurchasePrice,
		IMPS.SalePriceSelectId,
		IMPS.SalePriceSelectName,
		IMPS.PP_UOMId,
		IMPS.PP_UOMName,
		ISNULL(IMPS.PP_VendorListPrice,0) AS PP_VendorListPrice,
		ISNULL(IMPS.SP_CalSPByPP_BaseSalePrice,0) AS SP_CalSPByPP_BaseSalePrice,
		IMPS.SP_CalSPByPP_LastMarkUpDate,
		IMPS.SP_CalSPByPP_LastSalesDiscDate,
		ISNULL(IMPS.SP_CalSPByPP_MarkUpAmount,0) AS SP_CalSPByPP_MarkUpAmount,
        ISNULL(IMPS.SP_CalSPByPP_MarkUpPercOnListPrice,0) AS SP_CalSPByPP_MarkUpPercOnListPrice,
		ISNULL(IMPS.SP_CalSPByPP_SaleDiscAmount,0) AS SP_CalSPByPP_SaleDiscAmount,
		ISNULL(IMPS.SP_CalSPByPP_SaleDiscPerc,0) AS SP_CalSPByPP_SaleDiscPerc,
		ISNULL(IMPS.SP_CalSPByPP_UnitSalePrice,0) AS SP_CalSPByPP_UnitSalePrice,
		IMPS.SP_FSP_CurrencyId,
		IMPS.SP_FSP_CurrencyName,
		ISNULL(IMPS.SP_FSP_FlatPriceAmount,0) AS SP_FSP_FlatPriceAmount,
		ISNULL(IMPS.SP_FSP_FXRatePerc,0) AS SP_FSP_FXRatePerc,
		IMPS.SP_FSP_LastFlatPriceDate,
		IMPS.SP_FSP_UOMId,
		IMPS.SP_FSP_UOMName,
		IMPS.IsActive,
		IMPS.IsDeleted
		FROM [DBO].ItemMasterPurchaseSale IMPS WITH (NOLOCK) 
		LEFT JOIN [DBO].ItemMaster IM  WITH (NOLOCK)  ON IMPS.ItemMasterId = IM.ItemMasterId 
		WHERE IMPS.MasterCompanyId = @MasterCompanyId
		AND IMPS.IsActive = 1
		AND IMPS.IsDeleted = 0
		
		END TRY
		BEGIN CATCH
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'ItemMasterPriceListForBulkUpdate' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException 
					  @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END