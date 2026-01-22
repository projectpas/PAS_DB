/*************************************************************               
 ** File:   [CheckCurForVendorCustomerFinancial]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check Customer/Vendor Currency exist in finalcial info or not.   
 ** Purpose:             
 ** Date:   09/09/2024          
              
 ** RETURN VALUE:               
 **********************************************************               
 **   
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    09/09/2024  	AMIT GHEDIYA	Created     
 
 EXEC [CheckCurForVendorCustomerFinancial] 'Customer',12,1 && 'Vendor',34,1
********************************************************************/ 
CREATE    PROCEDURE [dbo].[CheckCurForVendorCustomerFinancial]
	@ModuleName VARCHAR(100) = NULL, -- Module Is Customer OR Vendor
	@ModuleId BIGINT NULL = 0, -- Id is for CustomerId OR VendorId
	@LegalEntityId BIGINT NULL = 0,
	@MSLegalEntityId BIGINT NULL = 0 -- This from Management Structure LEID.
AS
BEGIN
		BEGIN TRY
			DECLARE @ReturnStatus INT = 0,
					@CustomerModule VARCHAR(100) = 'Customer',
					@VendorModule VARCHAR(100) = 'Vendor',
					@ReturnCurrencyId INT = 0;

			--Get Curr If Management Structure Change.
			IF(@MSLegalEntityId > 0)
			BEGIN
				SELECT @ReturnCurrencyId = CU.CurrencyId 
				FROM [dbo].[LegalEntity] LE WITH(NOLOCK)
				JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = LE.FunctionalCurrencyId
				WHERE LE.[LegalEntityId] = @MSLegalEntityId;

				IF(ISNULL(@ReturnCurrencyId,0) > 0)
				BEGIN
					SET @ReturnStatus = 1;
				END
			END
			ELSE
			BEGIN
				--This for Customer Currency
				IF(@ModuleName = @CustomerModule)
				BEGIN
					SET @ReturnStatus = 1;
					SELECT @ReturnCurrencyId = [CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @ModuleId;
				END
			
				--This for Vendor Currency
				IF(@ModuleName = @VendorModule)
				BEGIN
					SET @ReturnStatus = 1;
					SELECT @ReturnCurrencyId = [CurrencyId] FROM [dbo].[Vendor] WITH(NOLOCK) WHERE [VendorId] = @ModuleId;
				END

				IF(ISNULL(@ReturnCurrencyId,0) = 0)
				BEGIN
					 SELECT @ReturnCurrencyId = CU.CurrencyId 
					 FROM [dbo].[LegalEntity] LE WITH(NOLOCK)
					 JOIN [dbo].[Currency] CU WITH(NOLOCK) ON CU.CurrencyId = LE.FunctionalCurrencyId
					 WHERE LE.[LegalEntityId] = @LegalEntityId;

					 IF(ISNULL(@ReturnCurrencyId,0) > 0)
					 BEGIN
						 SET @ReturnStatus = 1;
					 END
				END
			END

			SELECT @ReturnCurrencyId AS CurrencyId,@ReturnStatus AS Status;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CheckCurForVendorCustomerFinancial' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ModuleName, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END