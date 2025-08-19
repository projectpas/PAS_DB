/*************************************************************           
 ** File:   [USP_UpdateTokenDetailsForReadEmailOAuth]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to update Token Details For Email OAuth
 ** Purpose:         
 ** Date:  08/15/2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    08/15/2025   Vishal Suthar		Created
     
-- EXEC USP_UpdateTokenDetailsForEmailOAuth
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateTokenDetailsForReadEmailOAuth]
	@IntegrationEmailConfigId BIGINT = 0,
	@EmployeeId BIGINT = 0,
	@AccessToken VARCHAR(MAX) = NULL,
	@RefreshToken VARCHAR(MAX) = NULL,
	@ExpiresIn INT = NULL,
	@Provider VARCHAR(100) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION
	IF EXISTS (SELECT TOP 1 1 FROM DBO.IntegrationEmailSmtpConfigration WITH (NOLOCK) WHERE IntegrationEmailConfigId = @IntegrationEmailConfigId)
	BEGIN
		UPDATE DBO.IntegrationEmailSmtpConfigration 
		SET AccessToken = @AccessToken,
		RefreshToken = @RefreshToken,
		TokenExpiresIn = @ExpiresIn,
		TokenCreatedAt = GETUTCDATE(),
		UpdatedDate = GETDATE(),
		EmployeeId = @EmployeeId,
		AuthTypeId = CASE WHEN @Provider = 'google_read' THEN 2 ELSE 3 END
		WHERE IntegrationEmailConfigId = @IntegrationEmailConfigId;
	END

	SELECT @IntegrationEmailConfigId AS IntegrationEmailConfigId;
	
	COMMIT  TRANSACTION
END TRY    
BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments     VARCHAR(150)    = 'USP_UpdateTokenDetailsForReadEmailOAuth' 
        ,@ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@EmployeeID, '') as Varchar(100)) + 
										'@Parameter2 = '''+ CAST(ISNULL(@AccessToken, '') as Varchar(100))
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