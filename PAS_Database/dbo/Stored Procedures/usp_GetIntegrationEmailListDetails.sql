/*************************************************************             
 ** File:   [usp_GetIntegrationEmailListDetails]             
 ** Author:   Devendra Shekh    
 ** Description: get Integration Email List with AttachMent Details
 ** Date:   08-Aug-2025 
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO	Date			Author				Change Description              
 ** --		--------		-------				--------------------------------            
 **	1		08-Aug-2025		Devendra Shekh		Created
 
EXECUTE [dbo].[usp_GetIntegrationEmailListDetails]
**************************************************************/  
CREATE   PROCEDURE [dbo].[usp_GetIntegrationEmailListDetails]
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON
	BEGIN TRY
		BEGIN
			SELECT	[IntegrationEmailID], [Subject], [EmailBody], [ToEmail], [FromEmail], [CC], [BCC], [EmailReadBy], [ReferenceId], [ModuleId], [EmailStatus], [HasAttachments],
					[EmailSection], [ReceivedDate], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [CustomerRfqId]
			FROM [dbo].[IntegrationEmail] WITH(NOLOCK) 
			WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND ISNULL(CustomerRfqId, 0) = 0
			ORDER BY [IntegrationEmailID] DESC;

			SELECT [IntegrationEmailAttachmentID], IEA.[IntegrationEmailID], [AttachmentName], [AttachmentPath]
			FROM [dbo].[IntegrationEmailAttachment] IEA WITH(NOLOCK) 
			INNER JOIN [dbo].[IntegrationEmail] IE WITH(NOLOCK) ON IE.IntegrationEmailID = IEA.IntegrationEmailID
			WHERE IE.[IsActive] = 1 AND IE.[IsDeleted] = 0 AND ISNULL(IE.CustomerRfqId, 0) = 0
			ORDER BY IEA.[IntegrationEmailID] DESC;
		END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)		= 'usp_GetIntegrationEmailListDetails' 
		, @ProcedureParameters VARCHAR(3000)	= ''
		, @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
				@DatabaseName           = @DatabaseName
				, @AdhocComments          = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName        =  @ApplicationName
				, @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END