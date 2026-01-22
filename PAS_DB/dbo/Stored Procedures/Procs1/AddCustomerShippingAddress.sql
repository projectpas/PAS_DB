/***************************************************************  
 ** File:  [AddCustomerShippingAddress]            
 ** Author:   Ayushi Patel
 ** Description: Add Customer Shipping Address
 ** Date:  01-Aug-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-Aug-2025		Ayushi Patel			Created

-- declare @CreatedDate DATETIME = GETUTCDATE(),
--			@UpdatedDate DATETIME = GETUTCDATE();
--EXEC [dbo].AddCustomerShippingAddress
--            @CustomerId = 4348,
--            @CustomerName = 'hong1',
--            @ShippingAddressId = 32459,
--            @MasterCompanyId = 1,
--            @IsActive = 1,
--            @CreatedBy = 'Ayushi',
--            @UpdatedBy = 'Ayushi',
--            @Address1 = 'Line1',
--            @Address2 = '',
--            @Address3 = '',
--            @PostalCode = '84161',
--            @StateOrProvince ='state1',
--            @City = 'city1',
--            @CountryId = 2,
--			@AddressMasterCompanyId =1,
--			@AddressCreatedBy = 'Ayushi',
--			@AddressCreatedDate = @CreatedDate,
--			@AddressUpdatedBy = @UpdatedDate,
--			@Flag = 1;
**************************************************************/
CREATE   PROCEDURE AddCustomerShippingAddress
    @CustomerId BIGINT,
    @CustomerName NVARCHAR(255),
    @ShippingAddressId BIGINT = 0, 
    @IsActive BIT,
    @MasterCompanyId BIGINT,
    @CreatedBy varchar(255),
    @UpdatedBy varchar(255),

    -- Address Details 
    @Address1 NVARCHAR(255),
    @Address2 NVARCHAR(255)=NULL,
    @Address3 NVARCHAR(255)=NULL,
    @PostalCode NVARCHAR(50)=NULL,
    @City NVARCHAR(255)=NULL,
    @StateOrProvince NVARCHAR(255)=NULL,
    @CountryId BIGINT=0,
    @AddressMasterCompanyId BIGINT,
    @AddressCreatedBy varchar(255),
    @AddressCreatedDate DATETIME,
    @AddressUpdatedBy varchar(255),

    @Flag BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    DECLARE @CurrentPrimaryId BIGINT;
    DECLARE @ExistingShippingId BIGINT;
    DECLARE @FinalShippingId BIGINT;
    DECLARE @NewAddressId BIGINT;
	DECLARE @CustomerModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Customer');
	DECLARE @ShippingAddressType INT = 2;
    BEGIN TRY
        IF @Flag = 1
        BEGIN
            BEGIN TRANSACTION;
			
            -- Step 1: Check for current primary shipping address
            SELECT TOP 1 @CurrentPrimaryId = CustomerDomensticShippingId
            FROM DBO.CustomerDomensticShipping WITH(NOLOCK)
            WHERE CustomerId = @CustomerId AND IsPrimary = 1;
			
            -- Step 2: Check if this address is already in use
            SELECT TOP 1 @ExistingShippingId = CustomerDomensticShippingId
            FROM DBO.CustomerDomensticShipping WITH(NOLOCK)
            WHERE CustomerId = @CustomerId AND AddressId = @ShippingAddressId;
			
            -- Step 3: Unset old primary if needed
            IF @ExistingShippingId IS NOT NULL AND @ExistingShippingId != @CurrentPrimaryId
            BEGIN
                UPDATE DBO.CustomerDomensticShipping
                SET IsPrimary = 0,
                    UpdatedBy = @UpdatedBy,
                    UpdatedDate = GETUTCDATE()
                WHERE CustomerDomensticShippingId = @CurrentPrimaryId;

				EXEC USP_ShippingBillingAddressHistory 
                @CustomerId,
                @CustomerModuleId, 
                @FinalShippingId,
                @ShippingAddressType,
                @UpdatedBy;
            END
			
            -- Step 4: Update existing shipping or insert new one
            IF @ExistingShippingId IS NOT NULL
            BEGIN
                -- Update shipping record
                UPDATE DBO.CustomerDomensticShipping
                SET
                    MasterCompanyId = @MasterCompanyId,
                    SiteName = @CustomerName,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy,
                    IsActive = @IsActive,
                    IsPrimary = 1,
                    IsDeleted = 0
                WHERE CustomerDomensticShippingId = @ExistingShippingId;
				
                -- Update address details
                EXEC UpdateAddressDetails 
                    @ShippingAddressId,
                    @Address1, @Address2, @Address3,
                    @PostalCode, @City, @StateOrProvince,
                    @CountryId, @AddressMasterCompanyId,
                    @AddressCreatedBy, @AddressCreatedDate,
                    @AddressUpdatedBy;

                SET @FinalShippingId = @ExistingShippingId;
            END
            ELSE
            BEGIN
			
                -- Unset old primary again if still set
                IF @CurrentPrimaryId IS NOT NULL
                BEGIN
                    UPDATE DBO.CustomerDomensticShipping
                    SET IsPrimary = 0,
                        UpdatedBy = @UpdatedBy,
                        UpdatedDate = GETUTCDATE()
                    WHERE CustomerDomensticShippingId = @CurrentPrimaryId;

					EXEC USP_ShippingBillingAddressHistory 
						@CustomerId,
						@CustomerModuleId, 
						@FinalShippingId,
						@ShippingAddressType, 
						@UpdatedBy;
                END
				
                -- Add new address
                EXEC USP_AddAddress
                    @Address1, @Address2, @Address3,
                    @PostalCode, @StateOrProvince,@City,
                    @CountryId, @AddressMasterCompanyId,
                    @AddressCreatedBy,
                    @AddressUpdatedBy,
                    @NewAddressId OUTPUT;
				
                -- Insert new shipping record
                INSERT INTO DBO.CustomerDomensticShipping (
                    CustomerId, AddressId, MasterCompanyId, SiteName,
                    CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
                    IsActive, IsPrimary, IsDeleted
                )
                VALUES (
                    @CustomerId, @NewAddressId, @MasterCompanyId, @CustomerName,
                    GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy,
                    @IsActive, 1, 0
                );

                SET @FinalShippingId = SCOPE_IDENTITY();
				
                -- Update Customer table with new address ID
                UPDATE DBO.Customer
                SET ShippingAddressId = @NewAddressId
                WHERE CustomerId = @CustomerId;
            END
			
            -- Log history
            EXEC USP_ShippingBillingAddressHistory 
                @CustomerId,
                @CustomerModuleId, 
                @FinalShippingId,
                @ShippingAddressType, 
                @UpdatedBy;

            COMMIT;
        END

        -- Return final shipping ID
        SELECT @FinalShippingId AS ShippingAddressId;
    END TRY
    BEGIN CATCH    
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE @ErrorLogID int,    
			@DatabaseName varchar(100) = DB_NAME()    
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
			,@AdhocComments varchar(150) = 'AddCustomerShippingAddress',    
			@ProcedureParameters varchar(3000) = '',    
			@ApplicationName varchar(100) = 'PAS'    
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
			EXEC spLogException @DatabaseName = @DatabaseName,    
				@AdhocComments = @AdhocComments,    
				@ProcedureParameters = @ProcedureParameters,    
				@ApplicationName = @ApplicationName,    
				@ErrorLogID = @ErrorLogID OUTPUT;    
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)    
	END CATCH    
END