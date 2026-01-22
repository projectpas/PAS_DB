/*************************************************************           
 ** File:   [USP_UpdateCustomerRFQ]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to Update CustomerRFQ
 ** Purpose:         
 ** Date:   21-Aug-2025   
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date					Author					Change Description            
 ** --   --------				-------					--------------------------------          
    1    21-Aug-2025			Devendra Shekh			Created
     
-- EXEC USP_UpdateCustomerRFQ
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateCustomerRFQ]
	@CustomerRfqId BIGINT = NULL,
	@CustomerId BIGINT = NULL,
	@UserName VARCHAR(256) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN

		UPDATE CRFQ
		SET	
			CRFQ.UpdatedBy = @UserName,
			CRFQ.UpdatedDate = GETUTCDATE(),
			CRFQ.CustomerId = @CustomerId
		FROM [dbo].[CustomerRfq] CRFQ WITH(NOLOCK)
		WHERE CRFQ.CustomerRfqId = @CustomerRfqId;
		
	END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_UpdateCustomerRFQ' 
            , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@CustomerRfqId, '') as varchar(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END