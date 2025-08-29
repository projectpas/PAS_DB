/*************************************************************                 
 ** File:   [USP_CreateIntegrationEmailConfigration]    
 ** Author:   Moin Bloch
 ** Description: Get Integration Email Configration 
 ** Purpose:               
 ** Date:    04/08/2025      
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    04/08/2025   Moin Bloch   	    Created      
    2    29/08/2025   Devendra Shekh	added param @AuthTypeId      
    
-- EXEC [USP_CreateIntegrationEmailConfigration] 1,0,1
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_CreateIntegrationEmailConfigration] 
@IntegrationEmailConfigId BIGINT = NULL,
@SmtpUserEmail     NVARCHAR(MAX) = NULL,
@SmtpServer        NVARCHAR(500) = NULL,
@SmtpEmailPassword NVARCHAR(500) = NULL,
@SmtpPort          INT = NULL,
@UseSsl            BIT = NULL,
@MasterCompanyId   INT = NULL,
@CreatedBy         VARCHAR(256) = NULL,
@UpdatedBy         VARCHAR(256) = NULL,
@IsActive          BIT = NULL,
@IsDeleted         BIT = NULL,
@AuthTypeId		   INT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY 
	BEGIN TRANSACTION;

		IF(ISNULL(@IntegrationEmailConfigId,0) = 0)	
		BEGIN
			INSERT INTO [dbo].[IntegrationEmailSmtpConfigration]
			(
				[SmtpUserEmail], [smtpserver], [SmtpEmailPassword], [SmtpPort], [UseSsl],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
				[IsActive],[IsDeleted],[AuthTypeId]
			)
			VALUES
			(
				@SmtpUserEmail, @SmtpServer, @SmtpEmailPassword, @SmtpPort, @UseSsl,
				@MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(),
				1, 0, 1
			);

			SELECT SCOPE_IDENTITY() AS IntegrationEmailConfigId;
		END
		ELSE
		BEGIN
			UPDATE [dbo].[IntegrationEmailSmtpConfigration]
			   SET [SmtpUserEmail]     = @SmtpUserEmail,
                   [smtpserver]        = @SmtpServer,
                   [SmtpEmailPassword] = @SmtpEmailPassword,
                   [SmtpPort]          = @SmtpPort,
                   [UseSsl]            = @UseSsl,            
                   [UpdatedBy]         = @UpdatedBy,
                   [UpdatedDate]       = GETUTCDATE(),
                   [IsActive]          = 1,
                   [IsDeleted]         = 0,
                   [AuthTypeId]         = @AuthTypeId
             WHERE [IntegrationEmailConfigId] = @IntegrationEmailConfigId;	
			 
			 SELECT @IntegrationEmailConfigId AS IntegrationEmailConfigId;
		END  
		COMMIT TRANSACTION;
	 
 END TRY          
 BEGIN CATCH      
 ROLLBACK TRAN;
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_CreateIntegrationEmailConfigration'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationEmailConfigId, '') AS varchar(100))             
        + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))   
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