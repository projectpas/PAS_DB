/*********************             
 ** File:   USP_GetPriceDetailsByCondId
 ** Author:  Priyansh Patel  
 ** Description: This SP Is Used to Get Purchase and Sales Details for Part by condition ID
 ** Purpose:           
 ** Date:  03/03/2026
    
 ************************************************************             
  ** Change History             
 ************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    03/03/2026   Priyansh Patel      Created 
    2    12/03/2026   Priyansh Patel      Changed uom conversion for units sale price PN-15711 
    3    20/03/2026   Priyansh Patel      Added change to handle the item master detail without purchase records [PN-15730]
    4	 19/06/2026	  Ayushi		      [PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
exec USP_GetPriceDetailsByCondId  97659, 79, 1 

*************************************************************/   
  
CREATE   PROCEDURE [dbo].[USP_GetPriceDetailsByCondId]
 @ItemMasterId BIGINT,
 @ConditionId BIGINT,
 @MasterCompanyId INT = NULL
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY
        
        DECLARE @IsCost BIT = 1;

        SELECT  ISNULL(IPS.[PP_UnitPurchasePrice], 0) AS PP_UnitPurchasePrice,
                ISNULL( CASE WHEN IPS.[SalePriceSelectId] = 1 THEN IPS.[SP_FSP_FlatPriceAmount] ELSE IPS.[SP_CalSPByPP_UnitSalePrice] END, 0) AS SP_FSP_FlatPriceAmount,
                ISNULL(IPS.[SP_CalSPByPP_MarkUpPercOnListPrice], 0) AS SP_CalSPByPP_MarkUpPercOnListPrice,
                ISNULL(IPS.[SP_CalSPByPP_MarkUpAmount], 0) AS SP_CalSPByPP_MarkUpAmount,
                ISNULL(IPS.[PP_CurrencyId], 0) AS PP_CurrencyId,
                ISNULL(CUR.[Code], '') AS Currency,
                ISNULL(IPS.[SP_CalSPByPP_UnitSalePrice], 0) AS SalePrice,
                CASE  WHEN IPS.[ItemMasterId] IS NULL THEN '' ELSE CAST('T&M' AS VARCHAR(10)) END AS PriceType,
                CAST(
                CASE
                    WHEN ISNULL(IM.[IsPma], 0) = 1 AND ISNULL(IM.[IsDER], 0) = 1 THEN 'PMA&DER'
                    WHEN ISNULL(IM.[IsPma], 0) = 1 AND ISNULL(IM.[IsDER], 0) = 0 THEN 'PMA'
                    WHEN ISNULL(IM.[IsPma], 0) = 0 AND ISNULL(IM.[IsDER], 0) = 1 THEN 'DER'
                    ELSE 'OEM'
                END 
                AS VARCHAR(20)) AS StockType,
                ISNULL(IPS.PP_VendorListPrice, 0) AS vendorListPrice,
                ISNULL(IPS.PP_PurchaseDiscPerc, 0) AS discountPercent,
                ISNULL(IPS.PP_PurchaseDiscAmount, 0) AS discountPerUnit,
                ISNULL(IPS.PP_UnitPurchasePrice, 0) AS unitCost,
                ISNULL(IPS.PP_FXRatePerc, 0) AS PP_FXRatePerc,
                ISNULL(IMXL.ExchangeCoreCost, 0) AS CoreUnitCost,
                IM.PurchaseUnitOfMeasure,
                IM.StockUnitOfMeasure,
                IM.ConsumeUnitOfMeasure,
                CASE WHEN ISNULL(IM.PurchaseUnitOfMeasure,'') = ISNULL(IM.StockUnitOfMeasure,'') THEN ISNULL(IPS.PP_UnitPurchasePrice,0) ELSE [dbo].[fn_ConvertUOM](ISNULL(IPS.PP_UnitPurchasePrice,0),IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure,@IsCost,ISNULL(@MasterCompanyId,1)) END AS unitCostUOM,
                ISNULL(IPS.SP_CalSPByPP_UnitSalePrice, 0) AS unitSalesPriceUOM

        FROM [dbo].[ItemMaster] IM WITH (NOLOCK)
             LEFT JOIN [dbo].[ItemMasterPurchaseSale] IPS WITH (NOLOCK) ON IPS.[ItemMasterId] = IM.[ItemMasterId] AND IPS.[ConditionId] = @ConditionId AND ISNULL(IPS.IsDeleted, 0) = 0 AND ISNULL(IPS.IsActive, 0) = 1
             LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON IPS.[PP_CurrencyId] = cur.[CurrencyId]
             LEFT JOIN [dbo].[ItemMasterExchangeLoan] imxl WITH(NOLOCK) ON IM.[ItemMasterId] = imxl.[ItemMasterId]
        WHERE IM.[ItemMasterId] = @ItemMasterId AND (@MasterCompanyId IS NULL OR IM.MasterCompanyId = @MasterCompanyId);

   END TRY      
BEGIN CATCH  
DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
    ,@AdhocComments     VARCHAR(150)    = 'USP_GetPriceDetailsByCondId'   
    ,@ProcedureParameters varchar(3000) = '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)),
     @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    exec spLogException   
            @DatabaseName           = @DatabaseName  
            , @AdhocComments          = @AdhocComments  
            , @ProcedureParameters = @ProcedureParameters  
            , @ApplicationName        =  @ApplicationName  
            , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
    RETURN(1);  
 END CATCH  
END