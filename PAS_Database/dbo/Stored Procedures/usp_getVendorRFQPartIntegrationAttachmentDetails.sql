/*************************************************************
 ** File:  [usp_getVendorRFQPartIntegrationAttachmentDetails] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get the vendor RFQ Attachment Details with IntegrationEmail Mapping
 ** Date:  09-Dec-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    09-Dec-2025		Devendra Shekh		  Created

EXEC [dbo].[usp_getVendorRFQPartIntegrationAttachmentDetails] '784'
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_getVendorRFQPartIntegrationAttachmentDetails] (
	@VendorRFQPartIds VARCHAR(MAX) = NULL
)
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   
	BEGIN TRY
	BEGIN

		SELECT 
			IEA.IntegrationEmailAttachmentID,
			IEA.IntegrationEmailID,
			IEA.AttachmentName,
			IEA.AttachmentPath
		FROM [dbo].[IntegrationEmailAttachment] IEA WITH(NOLOCK)
		INNER JOIN [dbo].[IntegrationEmail] IE WITH(NOLOCK) ON IE.IntegrationEmailID = IEA.IntegrationEmailID
		INNER JOIN [dbo].[VendorRFQPart] VRP WITH(NOLOCK) ON VRP.IntegrationEmailID = IE.IntegrationEmailID
		WHERE VRP.VendorRFQPartId IN (SELECT value FROM STRING_SPLIT(@VendorRFQPartIds, ','));

	END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_getVendorRFQPartIntegrationAttachmentDetails' 
			, @ProcedureParameters VARCHAR(3000)  = ''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName				= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
			, @ApplicationName			= @ApplicationName
			, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END