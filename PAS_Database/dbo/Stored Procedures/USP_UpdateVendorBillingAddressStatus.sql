/*************************************************************
** File:   [USP_UpdateVendorBillingAddressStatus]        
** Author:  Ayushi Patel
** Description: update vendor billing address status and calls ShippingBillingAddressHistory.
** Purpose: 
** Date:   29/04/2025     
        
** PARAMETERS: 
    @BillingAddressId BIGINT,
    @Status BIT,
    @UpdatedBy NVARCHAR(255)

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    29/04/2025   Ayushi Patel    Created

--exec [dbo].[USP_UpdateVendorBillingAddressStatus]  7796, true,'ADMIN User'
************************************************************************/
CREATE   PROCEDURE USP_UpdateVendorBillingAddressStatus
    @BillingAddressId BIGINT,
    @Status BIT,
    @UpdatedBy NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        DECLARE @VendorId BIGINT;
		DECLARE @VendorModule INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
	    DECLARE @BillingAddress INT = 1;
        UPDATE dbo.VendorBillingAddress
        SET 
            IsActive = @Status,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE VendorBillingAddressId = @BillingAddressId;

        SELECT @VendorId = VendorId
        FROM dbo.VendorBillingAddress WITH (NOLOCK)
        WHERE VendorBillingAddressId = @BillingAddressId;

        EXEC dbo.USP_ShippingBillingAddressHistory 
            @ReferenceId = @VendorId,
            @ModuleId = @VendorModule, 
            @BillingShippingId = @BillingAddressId,
            @AddressType = @BillingAddress,
            @UpdatedBy = @UpdatedBy;

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
END;