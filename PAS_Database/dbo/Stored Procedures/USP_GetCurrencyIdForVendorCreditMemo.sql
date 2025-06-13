/*************************************************************           
 ** File:   [USP_GetCurrencyIdForVendorCreditMemo]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get CurrencyId For VendorCreditMemo List
 ** Purpose:         
 ** Date:   10-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    10-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE    PROCEDURE [dbo].[USP_GetCurrencyIdForVendorCreditMemo]
    @ModuleId BIGINT,
    @ReferenceId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		BEGIN TRY

			DECLARE @CurrencyId BIGINT = 0;

			IF @ModuleId = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'PurchaseOrder') 
			BEGIN
				(SELECT @CurrencyId = FunctionalCurrencyId FROM [dbo].PurchaseOrderPart WITH(NOLOCK) WHERE PurchaseOrderId = @ReferenceId);
			END
			ELSE IF @ModuleId = (SELECT ModuleId FROM [dbo].Module WITH(NOLOCK) WHERE ModuleName = 'RepairOrder') 
			BEGIN
				(SELECT @CurrencyId = FunctionalCurrencyId FROM [dbo].RepairOrderPart WITH(NOLOCK) WHERE RepairOrderId = @ReferenceId);
			END

			SELECT @CurrencyId AS CurrencyId;
		END TRY

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetCurrencyIdForVendorCreditMemo' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ModuleId, '') + ''',
				    @Parameter2 = ' + ISNULL(@ReferenceId ,'')

				  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

				  exec spLogException 
						   @DatabaseName			= @DatabaseName
						 , @AdhocComments			= @AdhocComments
						 , @ProcedureParameters		= @ProcedureParameters
						 , @ApplicationName			= @ApplicationName
						 , @ErrorLogID              = @ErrorLogID OUTPUT ;
				  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
				  RETURN
	END CATCH
END