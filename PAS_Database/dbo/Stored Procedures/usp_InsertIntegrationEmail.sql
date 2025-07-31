/*************************************************************           
 ** File:   [usp_InsertIntegrationEmail]           
 ** Author:   Hemant Saliya
 ** Description: This SP is used save email from user gmail account to PAS email
 ** Purpose:         
 ** Date:   07/30/2025     
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/30/2025   Hemant Saliya Created
	2    07/31/2025   Moin Bloch    Removed Attachment Fields
     
--EXEC [usp_InsertIntegrationEmail] 
**************************************************************/

CREATE   PROCEDURE [dbo].[usp_InsertIntegrationEmail]
@Subject           VARCHAR(500) = NULL,
@EmailBody         NVARCHAR(MAX) = NULL,
@ToEmail           NVARCHAR(320) = NULL,
@FromEmail         NVARCHAR(320) = NULL,
@CC                NVARCHAR(320) = NULL,
@BCC               NVARCHAR(320) = NULL,
@ReferenceId       BIGINT = NULL,
@ModuleId          INT = NULL,
@EmailStatus       INT = NULL,
@MasterCompanyId   INT,
@CreatedBy         VARCHAR(100) = NULL,
@UpdatedBy         VARCHAR(100) = NULL,
@CreatedDate       DATETIME2 = NULL,
@UpdatedDate       DATETIME2 = NULL,
@IsActive          BIT        = 1,   -- default: true
@IsDeleted         BIT        = 0,   -- default: false
@HasAttachments    BIT        = 0,
@EmailReadBy       NVARCHAR(320) = NULL,   
@EmailSection      INT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  
        INSERT INTO dbo.IntegrationEmail
        (
            [Subject],[EmailBody],[ToEmail],[FromEmail],
            [CC],[BCC],[ReferenceId],[ModuleId],[EmailStatus],
            [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],
            [UpdatedDate],[IsActive],[IsDeleted],[HasAttachments],
			[EmailReadBy],[EmailSection]
        )
        VALUES
        (
            @Subject,@EmailBody,@ToEmail,@FromEmail,
            @CC,@BCC,@ReferenceId,@ModuleId,@EmailStatus,
            @MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,
            @UpdatedDate,@IsActive,@IsDeleted,@HasAttachments,
			@EmailReadBy,@EmailSection
        );

   END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'usp_InsertIntegrationEmail'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Subject, '') as varchar(255))
			   + '@Parameter2 = ''' + CAST(ISNULL(@ToEmail, '') as varchar(255)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@FromEmail, '') as varchar(255))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@EmailReadBy, '') as varchar(255))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END