/*************************************************************               
 ** File:   [USP_WO_Refresh_Customer]               
 ** Author: RAJESH GAMI 
 ** Description:  This Store Procedure use to WO Refresh customer
 ** Purpose:             
 ** Date:   15 April 2025      
              
 ** RETURN VALUE:               
 **********************************************************               
 ** Refresh CreditLimit and Terms               
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    15 April 2025	RAJESH GAMI		CREATED 
 
 EXEC [USP_WO_Refresh_Customer] 4291,8646
********************************************************************/ 

CREATE     PROCEDURE [dbo].[USP_WO_Refresh_Customer]
	@customerId BIGINT,
	@workorderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION

			DECLARE @CustomerName VARCHAR(100)

			SELECT @CustomerName = C.[Name]	FROM [dbo].[Customer] C    WHERE CustomerId = @customerId

			UPDATE [dbo].[Workorder] SET [CustomerName] = @CustomerName	FROM [dbo].[Workorder]  WHERE WorkorderId = @workorderId AND CustomerId = @customerId
			
			SELECT [CustomerName]	FROM [dbo].[Workorder] W WITH (NOLOCK) WHERE WorkorderId = @workorderId 

		COMMIT  TRANSACTION

	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_WO_Refresh_Customer' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@customerId, '') + ''
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