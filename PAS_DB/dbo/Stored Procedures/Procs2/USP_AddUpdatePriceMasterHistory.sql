/*************************************************************           
 ** File:   [USP_AddUpdatePriceMasterHistory]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used USP_AddUpdatePriceMasterHistory
 ** Purpose:         
 ** Date:   08/10/2024      
          
 ** PARAMETERS: @ItemMasterPurchaseSaleId BIGINT, @ModuleId BIGINT , @MasterCompanyId BIGINT, @RefferenceId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/10/2024  Ekta Chandegra     Created
     

-- exec [dbo].[USP_AddUpdatePriceMasterHistory] @ItemMasterPurchaseSaleId=716,@ModuleId=20,@MasterCompanyId=1,@RefferenceId=716
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdatePriceMasterHistory]
(
	@ItemMasterPurchaseSaleId BIGINT = NULL,
	@ModuleId BIGINT = NULL,
	@MasterCompanyId BIGINT = NULL,
	@RefferenceId BIGINT = NULL
)
AS 
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	
		BEGIN TRY  
			BEGIN TRANSACTION  
				BEGIN
					DECLARE @ModuleName VARCHAR(100) = '';
					DECLARE @ReferenceNumber VARCHAR(100) = '';

						SELECT @ModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;
						SELECT @ReferenceNumber = [dbo].[udfGetModuleReferenceByModuleId] (@ModuleId, @RefferenceId, 1);

						INSERT INTO [dbo].[PriceMasterHistory] ( [ModuleId], [ModuleName],[RefferenceId] ,[RefferenceNumber] ,[ItemMasterId] ,
								[PartNumber] ,[PNDescription] ,[Manufacturer] ,[ItemMasterPurchaseSaleId] ,[ConditionId] ,
								[ConditionName] ,[PP_UOMId] ,[PP_UOMName] ,[PP_CurrencyId] ,[PP_CurrencyName] ,[PP_VendorListPrice] ,
								[PP_PurchaseDiscPerc] ,[PP_PurchaseDiscAmount] ,[PP_UnitPurchasePrice] ,[SalePriceSelectId] ,[SalePriceSelectName] ,
								[SP_FSP_UOMId] ,[SP_FSP_UOMName] ,[SP_FSP_CurrencyId] ,[SP_FSP_CurrencyName] ,[SP_FSP_FlatPriceAmount] ,
								[SP_CalSPByPP_MarkUpPercOnListPrice] ,[SP_CalSPByPP_MarkUpAmount] ,[SP_CalSPByPP_UnitSalePrice] ,[CreatedBy] ,
								[CreatedDate],[UpdatedBy],[UpdatedDate],[IsActive] , [IsDeleted])
						
						SELECT @ModuleId, @ModuleName, @RefferenceId, @ReferenceNumber , IMPS.ItemMasterId,
						IMPS.PartNumber,IM.PartDescription ,IM.ManufacturerName ,IMPS.ItemMasterPurchaseSaleId, IMPS.ConditionId,
						IMPS.ConditionName, IMPS.PP_UOMId, IMPS.PP_UOMName, IMPS.PP_CurrencyId, IMPS.PP_CurrencyName, IMPS.PP_VendorListPrice,
						IMPS.PP_PurchaseDiscPerc , IMPS.PP_PurchaseDiscAmount , IMPS.PP_UnitPurchasePrice , IMPS.SalePriceSelectId , IMPS.SalePriceSelectName ,
						IMPS.SP_FSP_UOMId , IMPS.SP_FSP_UOMName , IMPS.SP_FSP_CurrencyId , IMPS.SP_FSP_CurrencyName , IMPS.SP_FSP_FlatPriceAmount,
						IMPS.SP_CalSPByPP_MarkUpPercOnListPrice , IMPS.SP_CalSPByPP_MarkUpAmount, IMPS.SP_CalSPByPP_UnitSalePrice , IMPS.CreatedBy ,
						GETUTCDATE(),IMPS.UpdatedBy, GETUTCDATE(),IMPS.IsActive , IMPS.IsDeleted
						FROM [dbo].[ItemMasterPurchaseSale] IMPS WITH (NOLOCK) 
						LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IMPS.ItemMasterId = IM.ItemMasterId
						WHERE IMPS.ItemMasterPurchaseSaleId = @ItemMasterPurchaseSaleId 
						AND IMPS.MasterCompanyId = @MasterCompanyId

				END
			COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
			DECLARE @ErrorLogID int , @DatabaseName varchar(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		  ,@AdhocComments varchar(150) = 'USP_AddUpdatePriceMasterHistory'  
		  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterPurchaseSaleId, '') AS VARCHAR(100))  
		  ,@ApplicationName varchar(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
		  EXEC spLogException @DatabaseName = @DatabaseName,
				@AdhocComments = @AdhocComments,  
				@ProcedureParameters = @ProcedureParameters,  
				@ApplicationName = @ApplicationName,  
					@ErrorLogID = @ErrorLogID OUTPUT;  
		  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
		  RETURN (1);  
	END CATCH
END