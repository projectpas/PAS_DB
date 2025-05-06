/*************************************************************
** File:   [VendorShippingStatus]        
** Author:  Ayushi Patel
** Description: update vendor billing shipvia status.
** Purpose: 
** Date:   29/04/2025     
        
** PARAMETERS: 
    @VendorShippingId BIGINT,
    @Status BIT,
    @UpdatedBy NVARCHAR(100)

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    29/04/2025   Ayushi Patel    Created

--exec [dbo].[VendorShippingStatus]  7796, true,'ADMIN User'
************************************************************************/         
CREATE   PROCEDURE dbo.VendorShippingStatus
    @VendorShippingId BIGINT,
    @Status BIT,
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
    UPDATE DBO.VendorShipping
    SET 
        IsActive = @Status,
        UpdatedDate = GETUTCDATE(),
        UpdatedBy = @UpdatedBy
    WHERE VendorShippingId = @VendorShippingId;
	END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, 
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_UpdateVendorBillingAddressStatus',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred. Inform Support with Error Number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END