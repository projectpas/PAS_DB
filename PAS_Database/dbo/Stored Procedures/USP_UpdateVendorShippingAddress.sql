/*************************************************************           
** File:     USP_UpdateVendorShippingAddress
** Author:   Ayushi Patel  
** Description: Add/Update VendorShippingAddress & audit history
** Date:     14-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      15-07-2025   Ayushi Patel   Created  
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_UpdateVendorShippingAddress]
    @VendorShippingAddressId BIGINT = NULL,
    @VendorId BIGINT,
    @SiteName VARCHAR(100),
    @ContactTagId BIGINT = NULL,
    @Attention VARCHAR(250),
    @MasterCompanyId INT,
    @IsActive BIT,
    @AddressId BIGINT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    @CreatedDate DATETIME2,
    @UpdatedDate DATETIME2,
    @IsPrimary BIT,
    @OutputVendorShippingAddressId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
		DECLARE @ShippingAddressId INT = 2;
        IF @IsPrimary = 1
        BEGIN
            -- Mass update existing VendorShippingAddress to IsPrimary = 0
            UPDATE dbo.VendorShippingAddress
            SET IsPrimary = 0,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = SYSDATETIME()
            WHERE VendorId = @VendorId AND IsPrimary = 1

            DECLARE @ShippingAudit TABLE (VendorShippingAddressId BIGINT)

            INSERT INTO @ShippingAudit (VendorShippingAddressId)
            SELECT VendorShippingAddressId
            FROM dbo.VendorShippingAddress WITH (NOLOCK)
            WHERE VendorId = @VendorId

            DECLARE @RowIndex INT = 1, @RowCount INT = (SELECT COUNT(*) FROM @ShippingAudit)
            WHILE @RowIndex <= @RowCount
            BEGIN
                DECLARE @CurrentVSId BIGINT
                SELECT @CurrentVSId = VendorShippingAddressId FROM (
                    SELECT VendorShippingAddressId, ROW_NUMBER() OVER (ORDER BY VendorShippingAddressId) AS RN
                    FROM @ShippingAudit
                ) AS temp
                WHERE RN = @RowIndex

                EXEC dbo.USP_ShippingBillingAddressHistory
                    @ReferenceId = @VendorId,
                    @ModuleId = @VendorModuleId, -- Vendor
                    @BillingShippingId = @CurrentVSId,
                    @AddressType = @ShippingAddressId, -- Shipping
                    @UpdatedBy = @UpdatedBy

                SET @RowIndex += 1
            END
        END

        IF @VendorShippingAddressId IS NOT NULL AND @VendorShippingAddressId > 0
        BEGIN
            UPDATE dbo.VendorShippingAddress
            SET
                VendorId = @VendorId,
                SiteName = @SiteName,
                ContactTagId = @ContactTagId,
                Attention = @Attention,
                MasterCompanyId = @MasterCompanyId,
                IsActive = @IsActive,
                AddressId = @AddressId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = @UpdatedDate,
                CreatedBy = @CreatedBy,
                CreatedDate = @CreatedDate,
                IsPrimary = ISNULL(@IsPrimary, 0)
            WHERE VendorShippingAddressId = @VendorShippingAddressId

            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @VendorShippingAddressId,
                @AddressType = @ShippingAddressId,
                @UpdatedBy = @UpdatedBy

            SET @OutputVendorShippingAddressId = @VendorShippingAddressId
        END
        ELSE
        BEGIN
            DECLARE @NewPrimary BIT = @IsPrimary
            IF NOT EXISTS (SELECT 1 FROM dbo.VendorShippingAddress WITH (NOLOCK) WHERE VendorId = @VendorId)
                SET @NewPrimary = 1  -- First address is always primary

            INSERT INTO dbo.VendorShippingAddress
            (
                VendorId, SiteName, ContactTagId, Attention,
                MasterCompanyId, IsActive, AddressId,
                CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsPrimary
            )
            VALUES
            (
                @VendorId, @SiteName, @ContactTagId, @Attention,
                @MasterCompanyId, @IsActive, @AddressId,
                @CreatedBy, GETUTCDATE(), @UpdatedBy, GETUTCDATE(), @NewPrimary
            )

            SET @OutputVendorShippingAddressId = SCOPE_IDENTITY()

            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @OutputVendorShippingAddressId,
                @AddressType = @ShippingAddressId,
                @UpdatedBy = @UpdatedBy
        END

        COMMIT;
    END TRY
    BEGIN CATCH
          SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_UpdateVendorFinance]',
            @ProcedureParameters varchar(3000) = '',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END