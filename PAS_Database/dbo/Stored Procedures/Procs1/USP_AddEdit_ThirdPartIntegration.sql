CREATE     PROCEDURE [dbo].[USP_AddEdit_ThirdPartIntegration]
@ThirdPartInegrationId bigint,
@LegalEntityId varchar(50),
@CageCode varchar(50),
@IntegrationIds varchar(100) = NULL,
@APIURL varchar(50),
@SecretKey varchar(50),
@AccessKey varchar(50),
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@IsDeleted bit,
@MasterCompanyId bigint 

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			If(@ThirdPartInegrationId = 0)
			BEGIN
       			INSERT INTO [dbo].[ThirdPartInegration]
                  (
                  [LegalEntityId]
                  ,[CageCode]
                  ,[IntegrationIds]
				  ,[APIURL]
                  ,[SecretKey]
				  ,[AccessKey]
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]
                  ,[IsDeleted])
            VALUES
                  (
                   @LegalEntityId
                  ,@CageCode
                  ,@IntegrationIds
				  ,@APIURL
                  ,@SecretKey
				  ,@AccessKey
                  ,@MasterCompanyId
                  ,@CreatedBy
                  ,@CreatedBy
                  ,GETUTCDATE()
                  ,GETUTCDATE()
                  ,1
                  ,0)
			END
			else
			Begin
				EXEC [USP_Integration_History] @ThirdPartInegrationId,@CreatedBy

			    UPDATE [dbo].[ThirdPartInegration]
                SET 
                    [LegalEntityId] = @LegalEntityId
                   ,[CageCode] = @CageCode
                   ,[IntegrationIds] = @IntegrationIds
				   ,[APIURL] = @APIURL
                   ,[SecretKey] = @SecretKey
                   ,[AccessKey] = @AccessKey
                   ,[UpdatedBy] = @CreatedBy
                   ,[UpdatedDate] = GETUTCDATE()
                   ,[IsDeleted] = @IsDeleted
              WHERE ThirdPartInegrationId= @ThirdPartInegrationId
			END			
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_ThirdPartIntegration' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ThirdPartInegrationId, '') + ''
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