/*************************************************************           
** File:  [USP_GetItemMasterPurchaseSale]
** Author:   Bhargav Saliya
** Description: this Store Procedural used to get Purchase Sale Data
** Purpose:  
** Date:   27-Oct-2025 
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     27-Oct-2025   Bhargav Saliya      Created  

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetItemMasterPurchaseSale]
    @ItemMasterId BIGINT,
    @SuggestedPriceTVP dbo.SuggestedPriceTableType READONLY 
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY

    SELECT 
        iM.ConditionId,
        iM.ItemMasterId,
        iM.ItemMasterPurchaseSaleId,
        iM.PartNumber,
        iM.PP_CurrencyId,
        iM.PP_FXRatePerc,
        iM.PP_LastListPriceDate,
        iM.PP_LastPurchaseDiscDate,
        iM.PP_PurchaseDiscAmount,
        iM.PP_PurchaseDiscPerc,
        iM.PP_UnitPurchasePrice,
        iM.PP_UOMId,
        iM.PP_VendorListPrice,
        iM.SP_CalSPByPP_BaseSalePrice,
        iM.SP_CalSPByPP_LastMarkUpDate,
        iM.SP_CalSPByPP_LastSalesDiscDate,
        iM.SP_CalSPByPP_MarkUpAmount,
        iM.SP_CalSPByPP_MarkUpPercOnListPrice,
        iM.SP_CalSPByPP_SaleDiscAmount,
        iM.SP_CalSPByPP_SaleDiscPerc,
        iM.SP_CalSPByPP_UnitSalePrice,
        iM.SP_FSP_CurrencyId,
        iM.SP_FSP_FlatPriceAmount,
        iM.SP_FSP_FXRatePerc,
        iM.SP_FSP_LastFlatPriceDate,
        iM.SP_FSP_UOMId,
        iM.UpdatedBy,
        iM.UpdatedDate,
        ISNULL(iM.IsActive,1) as IsActive,
        ISNULL(iM.IsDeleted,0) as IsDeleted,
        iM.CreatedBy,
        iM.CreatedDate,
        ISNULL(iM.ConditionName, '') AS ConditionName,
        ISNULL(iM.PP_UOMName, '') AS PP_UOMName,
        ISNULL(iM.PP_CurrencyName, '') AS PP_CurrencyName,
        ISNULL(iM.SP_FSP_UOMName, '') AS SP_FSP_UOMName,
        ISNULL(iM.SP_FSP_CurrencyName, '') AS SP_FSP_CurrencyName,
        ISNULL(iM.PP_PurchaseDiscPercValue, 0) AS PP_PurchaseDiscPercValue,
        ISNULL(per.PercentValue, 0) AS SP_CalSPByPP_MarkUpPercOnListPriceValue,
        ISNULL(iM.SP_CalSPByPP_SaleDiscPercValue, 0) AS SP_CalSPByPP_SaleDiscPercValue,
        iM.SalePriceSelectId,
        ISNULL(iM.SalePriceSelectName, '') AS SalePriceSelectName,
        ISNULL(sp.RecommendedPrice, 0) AS SuggestedPrice

    FROM dbo.ItemMasterPurchaseSale iM WITH(NOLOCK)
    LEFT JOIN dbo.[ItemMasterPurchaseSaleMaster] spdrp WITH(NOLOCK) ON iM.SalePriceSelectId = spdrp.ItemMasterPurchaseSaleMasterId
    LEFT JOIN dbo.[Percent] per WITH(NOLOCK) ON iM.SP_CalSPByPP_MarkUpPercOnListPriceValue = per.PercentId
    LEFT JOIN @SuggestedPriceTVP sp ON sp.PartNumber = iM.PartNumber AND sp.Condition = iM.ConditionName
    WHERE iM.ItemMasterId = @ItemMasterId;
  END TRY
  BEGIN CATCH
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_GetItemMasterPurchaseSale]',
            @ProcedureParameters varchar(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END