

/*************************************************************           
 ** File:   [DeleteCreditMemoDetailsById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to delete Credit Memo Details
 ** Purpose:         
 ** Date:   18/04/2022      
          
 ** PARAMETERS: @CreditMemoDetailId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/04/2022  Moin Bloch     Created
     
-- EXEC DeleteCreditMemoDetailsById 3
************************************************************************/
CREATE PROCEDURE [dbo].[DeleteCreditMemoDetailsById]
@CreditMemoDetailId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		DELETE FROM [dbo].[CreditMemoApproval] WHERE CreditMemoDetailId = @CreditMemoDetailId;
		DELETE FROM [dbo].[CreditMemoDetails]  WHERE CreditMemoDetailId = @CreditMemoDetailId;
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'DeleteCreditMemoDetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoDetailId, '') + ''
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