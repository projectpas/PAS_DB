/*************************************************************           
 ** File:   [QuickBooks_GetCashReceiptDetailById]           
 ** Author:   Devendra Shekh
 ** Description: Get QuickBook Payment By QuickBooksReferenceId
 ** Purpose:         
 ** Date:   18-Nov-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author					Change Description            
 ** --   --------		-------					--------------------------------          
    1   18-Nov-2024		Devendra Shekh			Created
     
 exec dbo.QuickBooks_GetCashReceiptDetailById @QuickBooksReferenceId=N'185',@MasterCompanyId=1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[QuickBooks_GetCashReceiptDetailById]
	@QuickBooksReferenceId VARCHAR(256) = NULL,
	@MasterCompanyId INT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		SELECT	CPD.QuickBooksReferenceId,
				 CPD.SyncToken,
				 CPD.CustomerPaymentDetailsId
		FROM [dbo].[CustomerPaymentDetails] CPD WITH(NOLOCK) 
		WHERE	ISNULL(CPD.QuickBooksReferenceId, 0) = @QuickBooksReferenceId AND CPD.MasterCompanyId = @MasterCompanyId
		
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetCashReceiptDetailById'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@QuickBooksReferenceId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1);           
	END CATCH
END