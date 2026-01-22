



/*************************************************************           
 ** File:   [UpdateItemMasterPurchaseSaleDetails]           
 ** Author:   Moin Bloch
 ** Description: Update Item Master Purchase and Sale Id Wise Names
 ** Purpose: Reducing Joins         
 ** Date:   06-Apr-2021  
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06-Apr-2021   Moin Bloch   Created

 EXEC UpdateItemMasterPurchaseSaleDetails 234
**************************************************************/ 

CREATE PROCEDURE [dbo].[UpdateItemMasterPurchaseSaleDetails]
@ItemMasterId  bigint
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
		BEGIN TRANSACTION
		
	---------  Item Master --------------------------------------------------------------
 
	   UPDATE IMPS SET 
	    ConditionName = CO.[Description],
	    PP_UOMName = PUM.ShortName,
	    SP_FSP_UOMName = SUMG.ShortName,
	    PP_CurrencyName =  PCU.Code,
	    SP_FSP_CurrencyName = SCU.Code,
	    PP_PurchaseDiscPercValue = PDS.DiscontValue,
	    SP_CalSPByPP_SaleDiscPercValue = SDS.DiscontValue,
	    SP_CalSPByPP_MarkUpPercOnListPriceValue = SP.DiscontValue,
	    SalePriceSelectName = IMP.[Name]
	  
	   FROM dbo.ItemMasterPurchaseSale IMPS WITH (NOLOCK)
	        --INNER JOIN dbo.ItemMaster IM  ON IMPS.ItemMasterId = IM.ItemMasterId
	  	  LEFT JOIN dbo.Condition CO WITH (NOLOCK) ON IMPS.ConditionId = CO.ConditionId 
	  	  LEFT JOIN dbo.UnitOfMeasure PUM WITH (NOLOCK) ON IMPS.PP_UOMId = PUM.UnitOfMeasureId 
	  	  LEFT JOIN dbo.UnitOfMeasure SUMG WITH (NOLOCK) ON IMPS.SP_FSP_UOMId = SUMG.UnitOfMeasureId 
	  	  LEFT JOIN dbo.Currency PCU WITH (NOLOCK) ON IMPS.PP_CurrencyId = PCU.CurrencyId 
	  	  LEFT JOIN dbo.Currency SCU WITH (NOLOCK) ON IMPS.SP_FSP_CurrencyId = SCU.CurrencyId 
	  	  LEFT JOIN dbo.Discount PDS WITH (NOLOCK) ON IMPS.PP_PurchaseDiscPerc = PDS.DiscountId 
	  	  LEFT JOIN dbo.Discount SDS WITH (NOLOCK) ON IMPS.SP_CalSPByPP_SaleDiscPerc = SDS.DiscountId 
	  	  LEFT JOIN dbo.Discount SP WITH (NOLOCK) ON IMPS.SP_CalSPByPP_MarkUpPercOnListPrice = SP.DiscountId 
	  	  LEFT JOIN dbo.ItemMasterPurchaseSaleMaster IMP WITH (NOLOCK) ON IMPS.SalePriceSelectId = IMP.ItemMasterPurchaseSaleMasterId 
	  	  
	  WHERE IMPS.ItemMasterId = @ItemMasterId;
	  
	  SELECT partnumber AS value FROM dbo.ItemMaster IM WITH (NOLOCK) WHERE IM.ItemMasterId  = @ItemMasterId;

	COMMIT TRANSACTION

    END  TRY
    BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'UpdateItemMasterPurchaseSaleDetails'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))			  			                                           
	   ,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);           
	END CATCH
END