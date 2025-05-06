/*************************************************************
** File:   [USP_RestoreVendorShippingAddress]        
** Author:  Ayushi Patel
** Description: restoring Vendor shipping Address by setting IsDeleted = 0, and calls ShippingBillingAddressHistory.
** Purpose: 
** Date:   29/04/2025     
        
** PARAMETERS: 
    @VendorShippingAddressId BIGINT,
    @UpdatedBy NVARCHAR(255)

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date         Author		    Change Description            
** --   --------     -------		--------------------------------          
   1    29/04/2025   Ayushi Patel    Created

--exec [dbo].[USP_RestoreVendorShippingAddress]  7796, 'ADMIN User'
************************************************************************/

CREATE   PROCEDURE USP_RestoreVendorShippingAddress
    @VendorShippingAddressId BIGINT,
    @UpdatedBy NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        DECLARE @ShippingAddressTypeId INT = 2;
        DECLARE @VendorId BIGINT;

        UPDATE dbo.VendorShippingAddress
        SET 
            IsDeleted = 0,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE VendorShippingAddressId = @VendorShippingAddressId;

        SELECT @VendorId = VendorId
        FROM dbo.VendorShippingAddress WITH (NOLOCK)
        WHERE VendorShippingAddressId = @VendorShippingAddressId;

        IF @VendorId IS NOT NULL
        BEGIN
            EXEC dbo.USP_ShippingBillingAddressHistory 
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @VendorShippingAddressId,
                @AddressType = @ShippingAddressTypeId,
                @UpdatedBy = @UpdatedBy;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_RestoreVendorShippingAddress',
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