/*************************************************************           
** File:  [USP_DeleteSalesAndPurchase]
** Author:   Bhargav Saliya
** Description: Delete Sales And Purchase Record
** Purpose:  
** Date:   24-Oct-2025 
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     24-Oct-2025   Bhargav Saliya      Created  

**************************************************************/
CREATE     PROCEDURE [dbo].[USP_DeleteSalesAndPurchase]
    @ItemMasterPurchaseSaleId BIGINT,
	@UpdatedBy varchar(256),
    @MasterCompanyId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		IF(@ItemMasterPurchaseSaleId > 0)  
		BEGIN  
			UPDATE [dbo].[ItemMasterPurchaseSale]
			SET [IsDeleted] = 1,[UpdatedDate] = GETUTCDATE(),[UpdatedBy] = @UpdatedBy 
			WHERE ItemMasterPurchaseSaleId = @ItemMasterPurchaseSaleId AND MasterCompanyId = @MasterCompanyId
		END  
    BEGIN TRY
	BEGIN TRANSACTION
	
	COMMIT  TRANSACTION
    END TRY
    BEGIN CATCH      
			IF @@trancount > 0
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteSalesAndPurchase' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterPurchaseSaleId, '') + ''
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