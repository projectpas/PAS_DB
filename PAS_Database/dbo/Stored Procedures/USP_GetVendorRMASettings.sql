/*************************************************************           
 ** File:		 [USP_GetVendorRMASettings]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Vendor RMA Settings.
 ** Purpose:         
 ** Date:   22-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    22-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetVendorRMASettings] @MasterCompanyId=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetVendorRMASettings]
@MasterCompanyId INT = null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY	

		SELECT 
			[VendorRMASettingId],
			[EnforcePickTicketConfirmation],		
			[MasterCompanyId],
			[CreatedBy],
			[CreatedDate],
			[UpdatedBy],
			[UpdatedDate],
			[IsActive],
			[IsDeleted]
		FROM [DBO].[VendorRMASettings] WITH(NOLOCK) 
		WHERE [MasterCompanyId] = @MasterCompanyId	
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetVendorRMASettings'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END