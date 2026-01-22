/*************************************************************           
 ** File:   [GetCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Get Customer List to Create Customer in QuickBooks    
 ** Purpose:         
 ** Date:   04-July-2024        
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    04-July-2024   Hemant Saliya	Created
     
 EXECUTE [GetCustomerList] 1, 10, null, -1, 1, '', 'uday', 'CUS-00','','HYD'
**************************************************************/ 
CREATE PROCEDURE [dbo].[QuickBooks_GetNewCustomerList]
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY
	
		SELECT * FROM dbo.Customer C WITH(NOLOCK) 
		WHERE CustomerId = 1
		
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))  			                                           
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