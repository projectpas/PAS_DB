/*************************************************************             
  ** File:   [USP_EmailTrack]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used send email for customer approvals for Sales order quote 
 ** Purpose:           
 ** Date:  07/01/2025      
            
 ** PARAMETERS: @ReferenceId BIGINT, @MasterCompanyId INT,@ContactId BIGINT,@RecepientEmail VARCHAR(4000),@Subject VARCHAR(MAX),@EmailBody VARCHAR(MAX),@CreatedBy VARCHAR(256),@AttachmentId VARCHAR(256)           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    07/01/2025		EKTA CHANDEGRA	 Created  
    2    16/01/2025		EKTA CHANDEGRA	 Add Email Status  

EXEC dbo.USP_EmailTrack @ReferenceId=1012,@MasterCompanyId=1,@ContactId=208,@RecepientEmail=N'sx.alen@yopmail.com',@Subject=N'SOQ-000861',@EmailBody=N'<p>Dear Approver,</p><p><br></p><p>Sales Order Quote - SOQ-000861 requires your approval. For more details, please see the attached file.</p><p><br></p><p>Regards,</p><br><p><img src="##EmailSignatureLogo##" height="60px" width="150px"></p><br><p style="min-height:100px;margin:1px;float:left;font-size:12px!important;font-family:Tahoma,Arial,sans-serif;font-weight:400;line-height:20px;text-align:left">EKTA CHANDEGARA</p><br>',@CreatedBy=N'EKTA CHANDEGARA',@AttachmentId=17715

************************************************************************/ 

CREATE   PROCEDURE [dbo].[USP_EmailTrack]
    @ReferenceId BIGINT,
    @MasterCompanyId INT,
    @ContactId BIGINT,
    @RecepientEmail VARCHAR(4000),
    @Subject VARCHAR(MAX),
    @EmailBody VARCHAR(MAX),
    @CreatedBy VARCHAR(256),
    @AttachmentId VARCHAR(256)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	BEGIN TRY
		BEGIN
			DECLARE @EmailId BIGINT;
			DECLARE @CreatedByValue VARCHAR(256);
			DECLARE @EmailType INT = 1;
			DECLARE @EmailStatus BIT = 1;
			DECLARE @FromEmail VARCHAR(4000) = 'info.poweraerosuites@gmail.com';

			-- SELECT Module Id For SOQ
			DECLARE  @ModuleId INT = (SELECT ModuleId from [dbo].[Module] WITH(NOLOCK) where [ModuleName] = 'SalesQuote');

			SET @CreatedByValue = 
			CASE 
				WHEN @CreatedBy IS NULL OR @CreatedBy = ''
				THEN 'admin'
				ELSE @CreatedBy
			END 

			-- SELECT Email Type
			DECLARE @EmailTypeId INT = (SELECT EmailTypeID FROM [dbo].[EmailType] WITH(NOLOCK) WHERE [Name] = 'Background');

			-- Insert into Email table
			INSERT INTO [dbo].[Email] 
			(ReferenceId,ModuleId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,AttachmentId,FromEmail,
			 ToEmail,Subject,CC,BCC,EmailTypeId,ContactById,ContactDate,EmailBody,IsActive,IsDeleted,Type,EmailStatus)
			VALUES 
			(@ReferenceId,@ModuleId,@MasterCompanyId,@CreatedByValue,@CreatedByValue,GETDATE(),GETDATE(),@AttachmentId,@FromEmail,
			 @RecepientEmail,@Subject,'','',@EmailTypeId,@ContactId,GETDATE(),@EmailBody,1,0,@EmailType,@EmailStatus);

			-- Get the ID of the inserted Email record
			SET @EmailId = SCOPE_IDENTITY();

			SELECT @EmailId AS EmailId
		END
	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_EmailTrack'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReferenceId, '') + ''',
													 @Parameter2 = '''+ ISNULL(@MasterCompanyId, '') + ''',
													 @Parameter3 = '''+ ISNULL(@ContactId, '') + ''',
													 @Parameter4 = '''+ ISNULL(@RecepientEmail, '') + ''',
													 @Parameter5 = '''+ ISNULL(@Subject, '') + ''',
													 @Parameter6 = '''+ ISNULL(@EmailBody, '') + ''',
													 @Parameter7 = '''+ ISNULL(@CreatedBy, '') + ''',
													 @Parameter8 = '''+ ISNULL(@AttachmentId, '') + ''
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
END;