/*************************************************************           
 ** File:   [USP_UpdateTokenDetailsForEmailOAuth]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to update Token Details For Email OAuth
 ** Purpose:         
 ** Date:  05/23/2025
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    05/23/2025   Vishal Suthar		Created
    2    07/14/2025   Vishal Suthar		Inserting Not Null fields with default values
     
-- EXEC USP_UpdateTokenDetailsForEmailOAuth
************************************************************************/
CREATE   Procedure [dbo].[USP_UpdateTokenDetailsForEmailOAuth]
	@EmployeeId BIGINT = 0,
	@AccessToken VARCHAR(MAX) = NULL,
	@RefreshToken VARCHAR(MAX) = NULL,
	@ExpiresIn INT = NULL,
	@Provider VARCHAR(100) = NULL,
	@ConfigureFrom VARCHAR(50) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

BEGIN TRY
BEGIN TRANSACTION

	DECLARE @EmailSettings VARCHAR(50) = 'EmailSettings'
	DECLARE @IntegrationEmailConfig VARCHAR(50) = 'IntegrationEmailConfig'

	If EXISTS (SELECT TOP 1 1 FROM DBO.Usersmtpsetting WITH (NOLOCK) WHERE EmployeeId = @EmployeeId)
	BEGIN
		INSERT INTO DBO.UsersmtpsettingAudit (EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate)
	    SELECT EmployeeId,smtpserver,emailpassword,portno,emailtype,verifyemail,CreatedDate,UpdatedDate 
		FROM DBO.Usersmtpsetting WITH (NOLOCK) WHERE EmployeeId = @EmployeeId;

		UPDATE DBO.Usersmtpsetting 
		SET AccessToken = @AccessToken,
		RefreshToken = @RefreshToken,
		TokenExpiresIn = @ExpiresIn,
		TokenCreatedAt = GETUTCDATE(),
		UpdatedDate = GETDATE(),
		emailtype = 3,
		EmailTypeId = CASE WHEN @Provider = 'google' THEN 4 ELSE 5 END
		WHERE EmployeeId = @EmployeeId
	END
	ELSE
	BEGIN
		INSERT INTO DBO.Usersmtpsetting (EmployeeId,smtpserver,emailpassword,portno,EmailTypeId,AccessToken,RefreshToken,TokenExpiresIn,TokenCreatedAt,UpdatedDate)
		VALUES (@EmployeeId,'','',0,CASE WHEN @Provider = 'google' THEN 4 ELSE 5 END,@AccessToken,@RefreshToken,@ExpiresIn,GETDATE(),GETDATE())
	END

	SELECT smtpsettingId from DBO.Usersmtpsetting WITH (NOLOCK) WHERE EmployeeId = @EmployeeId;
	
	COMMIT  TRANSACTION
END TRY    
BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		ROLLBACK TRAN;
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments     VARCHAR(150)    = 'USP_UpdateTokenDetailsForEmailOAuth' 
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