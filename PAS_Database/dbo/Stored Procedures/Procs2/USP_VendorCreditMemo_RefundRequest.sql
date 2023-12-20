/*************************************************************             
 ** File:   [USP_VendorCrediMemo_RefundRequest]             
 ** Author:   Amit Ghediya    
 ** Description: Updated status FULFILLING to Refund Request Sent. 
 ** Purpose:           
 ** Date:   07-17-2023         
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    07-17-2023      Amit Ghediya      Created  

**************************************************************/  
CREATE     PROCEDURE [dbo].[USP_VendorCreditMemo_RefundRequest]
@VendorCreditMemoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		DECLARE @StatusId BIGINT;

		SELECT @StatusId = Id FROM CreditMemoStatus WITH (NOLOCK) WHERE Name='Refund Request Sent';
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				-- Updated status FULFILLING to Refund Request Sent.
			    UPDATE [dbo].[VendorCreditMemo]
                SET 
                    [VendorCreditMemoStatusId] = @StatusId
				WHERE VendorCreditMemoId= @VendorCreditMemoId;

				SELECT @VendorCreditMemoId AS VendorCreditMemoId;                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_VendorCrediMemo_RefundRequest' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorCreditMemoId, '') + ''
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