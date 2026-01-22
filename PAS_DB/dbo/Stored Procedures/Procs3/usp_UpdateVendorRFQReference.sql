/*************************************************************             
 ** File:   [usp_UpdateVendorRFQReference]            
 ** Author:   Devendra Shekh    
 ** Description: this stored procedure is used to update VendorRFQ Refence
 ** Date:   28-Aug-2025   
 **************************************************************             
  ** Change History             
 **************************************************************             
 **	 S NO   Date			 Author				Change Description              
 **	 --   --------			-------				--------------------------------            
	1	 28-Aug-2025		Devendra Shekh		created  
       
*************************************************************/      
CREATE   PROCEDURE [dbo].[usp_UpdateVendorRFQReference]
	@ReferenceId BIGINT = NULL,
	@ModuleId INT = NULL,
	@vendorRFQPartId VARCHAR(100) = NULL,
	@UpdatedBy VARCHAR(100) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		UPDATE VRFQ	
		SET
			VRFQ.UpdatedBy = @UpdatedBy,
			VRFQ.UpdatedDate = GETUTCDATE(),
			VRFQ.ModuleId = @ModuleId,
			VRFQ.ReferenceId = @ReferenceId
		FROM [dbo].[VendorRFQPart] VRFQ WITH(NOLOCK)
		WHERE VRFQ.VendorRFQPartId IN (SELECT value FROM STRING_SPLIT(@vendorRFQPartId, ','));
	END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = '[usp_UpdateVendorRFQReference]'               
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

		EXEC spLogException 
			@DatabaseName			= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
            , @ApplicationName         = @ApplicationName
            , @ErrorLogID              = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END