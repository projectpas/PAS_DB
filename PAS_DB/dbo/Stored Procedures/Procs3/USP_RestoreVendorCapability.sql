/*************************************************************
** File: [USP_RestoreVendorCapability]
** Author:   Ayushi Patel
** Description: Restore Vendor Capability By Id
** Purpose:  
** Date:     03-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    03-07-2025   Ayushi Patel   Created

-- EXEC [USP_RestoreVendorCapability] 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_RestoreVendorCapability]
    @VendorCapabilityId BIGINT,
    @UpdatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE dbo.VendorCapability
        SET 
            IsDeleted = 0,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE VendorCapabilityId = @VendorCapabilityId;
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_RestoreVendorCapability'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END