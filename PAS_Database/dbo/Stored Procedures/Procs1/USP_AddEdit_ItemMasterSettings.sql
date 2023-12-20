Create   PROCEDURE [dbo].[USP_AddEdit_ItemMasterSettings]
@ItemMasterSettingsId bigint,
@GLAccountId bigint,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@IsDeleted bit,
@MasterCompanyId int 

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			DECLARE @GlAccount varchar(50)
			SELECT @GlAccount = [AccountCode] + '-' +  [AccountName] FROM GLAccount where GLAccount.GLAccountId = @GLAccountId


			IF(@ItemMasterSettingsId = 0)
			BEGIN
       			INSERT INTO [dbo].[ItemMasterSettings]
                  (
				   [GLAccountId]
                  ,[GLAccount]
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]
                  ,[IsDeleted])
            VALUES
                  (
                   @GLAccountId
                  ,@GlAccount
                  ,@MasterCompanyId
                  ,@CreatedBy
                  ,@CreatedBy
                  ,GETUTCDATE()
                  ,GETUTCDATE()
                  ,1
                  ,0)
			END
			ELSE
			BEGIN
				EXEC [USP_ItemMasterSettings_History] @ItemMasterSettingsId,@CreatedBy

			    UPDATE [dbo].[ItemMasterSettings]
                SET 
                    [GLAccountId] = @GLAccountId
                   ,[GLAccount] = @GlAccount
                   ,[UpdatedBy] = @CreatedBy
                   ,[UpdatedDate] = GETUTCDATE()
                   ,[IsDeleted] = @IsDeleted
              WHERE [ItemMasterSettingsId]= @ItemMasterSettingsId
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
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_ItemMasterSettings' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterSettingsId, '') + ''
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