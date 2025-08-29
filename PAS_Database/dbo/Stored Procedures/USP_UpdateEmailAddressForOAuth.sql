/*************************************************************           
 ** File:   [USP_UpdateEmailAddressForOAuth]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to update email address For Email OAuth
 ** Purpose:         
 ** Date:  08/20/2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/20/2025   Vishal Suthar		Created
	2    29/08/2025   Devendra Shekh	added param @AuthTypeId, and Set SMPT details to null 
     
-- EXEC USP_UpdateEmailAddressForOAuth
************************************************************************/
CREATE   Procedure [dbo].[USP_UpdateEmailAddressForOAuth]
	@IntegrationEmailConfigId BIGINT = 0,
	@EmailId VARCHAR(100) = NULL,
	@AuthTypeId INT = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
	UPDATE DBO.IntegrationEmailSmtpConfigration 
	SET SmtpUserEmail = @EmailId,
		UpdatedDate = GETDATE(),
		AuthTypeId = @AuthTypeId,
		smtpserver = NULL,
		SmtpEmailPassword = NULL,
		SmtpPort = NULL,
		UseSsl = 0
	WHERE IntegrationEmailConfigId = @IntegrationEmailConfigId
END TRY    
BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments     VARCHAR(150)    = 'USP_UpdateEmailAddressForOAuth' 
        ,@ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@IntegrationEmailConfigId, '') as Varchar(100)) + 
										'@Parameter2 = '''+ CAST(ISNULL(@EmailId, '') as Varchar(100))
        ,@ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
            @DatabaseName           = @DatabaseName
            ,@AdhocComments          = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName        =  @ApplicationName
            ,@ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END