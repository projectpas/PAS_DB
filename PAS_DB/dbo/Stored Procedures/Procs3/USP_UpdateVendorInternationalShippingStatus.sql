/*************************************************************           
 ** File:   [USP_UpdateVendorInternationalShippingStatus]        
 ** Author:   Ayushi Patel
 ** Description: Update Vendor International Shipping Status
 ** Purpose:         
 ** Date:  19/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 19-MAY-2025   AYUSHI PATEL 		Created
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_UpdateVendorInternationalShippingStatus]
    @VendorInternationalShippingId BIGINT,
    @IsActive BIT,
    @UpdatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        UPDATE dbo.VendorInternationalShipping
        SET 
            IsActive = @IsActive,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE VendorInternationalShippingId = @VendorInternationalShippingId;
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_UpdateVendorInternationalShippingStatus'
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
END;