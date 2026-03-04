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

exec USP_GetPriceDetailsByCondId  97627, 9, 1 

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
		
        DECLARE @IsCost BIT = CAST(1 AS BIT);

		SELECT TOP (1)
        IPS.[PP_UnitPurchasePrice], CASE WHEN IPS.[SalePriceSelectId] = 1  THEN IPS.[SP_FSP_FlatPriceAmount] ELSE  IPS.[SP_CalSPByPP_UnitSalePrice] END AS SP_FSP_FlatPriceAmount, IPS.[SP_CalSPByPP_MarkUpPercOnListPrice], IPS.[SP_CalSPByPP_MarkUpAmount], IPS.[PP_CurrencyId],ISNULL(CUR.[Code], '') AS Currency, IPS.[SP_CalSPByPP_UnitSalePrice] AS SalePrice,
        CAST('T&M' AS VARCHAR(10))   AS PriceType,
        CAST(
                CASE
                    WHEN ISNULL(IM.[IsPma], 0) = 1 AND ISNULL(IM.[IsDER], 0) = 1 THEN 'PMA&DER'
                    WHEN ISNULL(IM.[IsPma], 0) = 1 AND ISNULL(IM.[IsDER], 0) = 0 THEN 'PMA'
                    WHEN ISNULL(IM.[IsPma], 0) = 0 AND ISNULL(IM.[IsDER], 0) = 1 THEN 'DER'
                    ELSE 'OEM'
                END 
        AS VARCHAR(20)) AS StockType,
        IPS.[PP_VendorListPrice] AS vendorListPrice,
        IPS.[PP_PurchaseDiscPerc] AS discountPercent,
        IPS.[PP_PurchaseDiscAmount] AS discountPerUnit,
        IPS.[PP_UnitPurchasePrice] AS unitCost,
        IPS.[PP_FXRatePerc],
        imxl.[ExchangeCoreCost] AS CoreUnitCost,
        --IM.PurchaseUnitOfMeasure,
        --IM.StockUnitOfMeasure,
        --IM.ConsumeUnitOfMeasure,
        [dbo].[fn_ConvertUOM](ISNULL(IPS.PP_UnitPurchasePrice, 0), IM.PurchaseUnitOfMeasure,IM.StockUnitOfMeasure, @IsCost, ISNULL(@MasterCompanyId,1)) AS unitCostUOM,
        [dbo].[fn_ConvertUOM](ISNULL(IPS.SP_CalSPByPP_UnitSalePrice, 0), IM.StockUnitOfMeasure, IM.ConsumeUnitOfMeasure, @IsCost,ISNULL(@MasterCompanyId,1)
        ) AS unitSalesPriceUOM

        FROM [dbo].[ItemMasterPurchaseSale] IPS WITH(NOLOCK) 
        INNER JOIN [dbo].[ItemMaster] IM  WITH(NOLOCK) ON IPS.[ItemMasterId] = IM.[ItemMasterId]
        LEFT JOIN [dbo].[Currency] cur WITH(NOLOCK) ON IPS.[PP_CurrencyId] = cur.[CurrencyId]
        LEFT JOIN [dbo].[ItemMasterExchangeLoan] imxl WITH(NOLOCK) ON IM.[ItemMasterId] = imxl.[ItemMasterId]
        WHERE IPS.[ItemMasterId] = @ItemMasterId AND ISNULL(IPS.[IsDeleted], 0) = 0 AND ISNULL(IPS.[IsActive], 0) = 1
        AND IPS.[ConditionId] = @ConditionId AND (@MasterCompanyId IS NULL OR IM.[MasterCompanyId] = @MasterCompanyId)
      

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