/*************************************************************           
** File:     USP_CreateOrUpdateVendorShippingFull
** Author:   Ayushi Patel  
** Description: Replicates EF logic for address + vendor shipping creation/update.
** Date:     05-08-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1     05-08-2025   Ayushi Patel   Created  

declare @p26 bigint
set @p26=7971
exec USP_CreateOrUpdateVendorShippingFull @AddressId=0,@Line1=N'asd',@Line2=NULL,@Line3=NULL,@City=N'sdf',@StateOrProvince=N'sd',@PostalCode=N'23',@CountryId=2,@AddressMasterCompanyId=1,@AddressCreatedBy=N'VICTOR ADMAS',@AddressUpdatedBy=N'VICTOR ADMAS',@AddressCreatedDate='2025-08-05 09:49:06.493',@AddressUpdatedDate='2025-08-05 09:49:06.493',@VendorShippingAddressId=0,@VendorId=4865,@SiteName=N'aws',@ContactTagId=NULL,@Attention=NULL,@VendorMasterCompanyId=1,@IsActive=1,@IsPrimary=0,@VendorCreatedBy=N'VICTOR ADMAS',@VendorUpdatedBy=N'VICTOR ADMAS',@VendorCreatedDate='2025-08-05 09:49:06.493',@VendorUpdatedDate='2025-08-05 09:49:06.493',@OutputVendorShippingAddressId=@p26 output
select @p26

select * from VendorShippingAddress
select * from address where addressid = 32548
******************************************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreateOrUpdateVendorShippingFull]
    -- Address fields
    @AddressId BIGINT = NULL,
    @Line1 VARCHAR(100),
    @Line2 VARCHAR(100) = NULL,
    @Line3 VARCHAR(100) = NULL,
    @City VARCHAR(100),
    @StateOrProvince VARCHAR(100),
    @PostalCode VARCHAR(20),
    @CountryId BIGINT,
    @AddressMasterCompanyId INT,
    @AddressCreatedBy VARCHAR(100),
    @AddressUpdatedBy VARCHAR(100),
    @AddressCreatedDate DATETIME2,
    @AddressUpdatedDate DATETIME2,

    -- Vendor Shipping Address fields
    @VendorShippingAddressId BIGINT = NULL,
    @VendorId BIGINT,
    @SiteName VARCHAR(100),
    @ContactTagId BIGINT = NULL,
    @Attention VARCHAR(250) = NULL,
    @VendorMasterCompanyId INT,
    @IsActive BIT,
    @IsPrimary BIT,
    @VendorCreatedBy VARCHAR(100),
    @VendorUpdatedBy VARCHAR(100),
    @VendorCreatedDate DATETIME2,
    @VendorUpdatedDate DATETIME2,

    -- OUTPUT
    @OutputVendorShippingAddressId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. UPSERT Address
      
        IF @AddressId IS NOT NULL AND @AddressId > 0
        BEGIN
            UPDATE dbo.Address
            SET
                Line1 = @Line1,
                Line2 = @Line2,
                Line3 = @Line3,
                City = @City,
                StateOrProvince = @StateOrProvince,
                PostalCode = @PostalCode,
                CountryId = @CountryId,
                MasterCompanyId = @AddressMasterCompanyId,
                IsActive = 1,
                UpdatedBy = @AddressUpdatedBy,
                UpdatedDate = GETUTCDATE(),
                CreatedBy = @AddressCreatedBy,
                CreatedDate = @AddressCreatedDate
            WHERE AddressId = @AddressId;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.Address (
                Line1, Line2, Line3, City, StateOrProvince, PostalCode,
                CountryId, MasterCompanyId, IsActive,
                CreatedBy, CreatedDate, UpdatedBy, UpdatedDate
            )
            VALUES (
                @Line1, @Line2, @Line3, @City, @StateOrProvince, @PostalCode,
                @CountryId, @AddressMasterCompanyId, 1,
                @AddressCreatedBy, GETUTCDATE(), @AddressUpdatedBy, GETUTCDATE()
            );

            SET @AddressId = SCOPE_IDENTITY();
        END

        -- 2. Handle IsPrimary Flag
        
        DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        DECLARE @ShippingAddressTypeId INT = 2;

        IF @IsPrimary = 1
        BEGIN
            -- Mark all existing vendor shipping addresses as non-primary
            UPDATE dbo.VendorShippingAddress
            SET IsPrimary = 0,
                UpdatedBy = @VendorUpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE VendorId = @VendorId AND IsPrimary = 1;

            -- Audit old addresses
            DECLARE @ShippingAudit TABLE (VendorShippingAddressId BIGINT);
            INSERT INTO @ShippingAudit (VendorShippingAddressId)
            SELECT VendorShippingAddressId
            FROM dbo.VendorShippingAddress WITH (NOLOCK)
            WHERE VendorId = @VendorId;

            DECLARE @RowIndex INT = 1, @RowCount INT = (SELECT COUNT(*) FROM @ShippingAudit);

            WHILE @RowIndex <= @RowCount
            BEGIN
                DECLARE @CurrentVSId BIGINT;

                SELECT @CurrentVSId = VendorShippingAddressId
                FROM (
                    SELECT VendorShippingAddressId, ROW_NUMBER() OVER (ORDER BY VendorShippingAddressId) AS RN
                    FROM @ShippingAudit
                ) AS temp
                WHERE RN = @RowIndex;

                EXEC dbo.USP_ShippingBillingAddressHistory
                    @ReferenceId = @VendorId,
                    @ModuleId = @VendorModuleId,
                    @BillingShippingId = @CurrentVSId,
                    @AddressType = @ShippingAddressTypeId,
                    @UpdatedBy = @VendorUpdatedBy;

                SET @RowIndex += 1;
            END
        END

        -- 3. UPSERT VendorShippingAddress
        
        IF @VendorShippingAddressId IS NOT NULL AND @VendorShippingAddressId > 0
        BEGIN
            UPDATE dbo.VendorShippingAddress
            SET
                VendorId = @VendorId,
                SiteName = @SiteName,
                ContactTagId = @ContactTagId,
                Attention = @Attention,
                MasterCompanyId = @VendorMasterCompanyId,
                IsActive = @IsActive,
                AddressId = @AddressId,
                UpdatedBy = @VendorUpdatedBy,
                UpdatedDate = @VendorUpdatedDate,
                CreatedBy = @VendorCreatedBy,
                CreatedDate = @VendorCreatedDate,
                IsPrimary = ISNULL(@IsPrimary, 0)
            WHERE VendorShippingAddressId = @VendorShippingAddressId;

            SET @OutputVendorShippingAddressId = @VendorShippingAddressId;

            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @VendorShippingAddressId,
                @AddressType = @ShippingAddressTypeId,
                @UpdatedBy = @VendorUpdatedBy;
        END
        ELSE
        BEGIN
            DECLARE @NewPrimary BIT = @IsPrimary;

            IF NOT EXISTS (SELECT 1 FROM dbo.VendorShippingAddress WHERE VendorId = @VendorId)
                SET @NewPrimary = 1;

            INSERT INTO dbo.VendorShippingAddress (
                VendorId, SiteName, ContactTagId, Attention,
                MasterCompanyId, IsActive, AddressId,
                CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsPrimary
            )
            VALUES (
                @VendorId, @SiteName, @ContactTagId, @Attention,
                @VendorMasterCompanyId, @IsActive, @AddressId,
                @VendorCreatedBy, GETUTCDATE(), @VendorUpdatedBy, GETUTCDATE(), @NewPrimary
            );

            SET @OutputVendorShippingAddressId = SCOPE_IDENTITY();

            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @OutputVendorShippingAddressId,
                @AddressType = @ShippingAddressTypeId,
                @UpdatedBy = @VendorUpdatedBy;
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
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_CreateOrUpdateVendorShippingFull]',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occurred. Support team reference number: %d',
            16, 1, @ErrorLogID
        );

        RETURN 1;
    END CATCH
END