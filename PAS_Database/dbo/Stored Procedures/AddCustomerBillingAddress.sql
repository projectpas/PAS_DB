/***************************************************************  
 ** File:  [AddCustomerBillingAddress]            
 ** Author:   Ayushi Patel
 ** Description: Add Customer Shipping Address
 ** Date:  01-Aug-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    01-Aug-2025		Ayushi Patel			Created
	
**************************************************************/
CREATE   PROCEDURE AddCustomerBillingAddress
    @CustomerId BIGINT,
    @CustomerName NVARCHAR(255),
    @BillingAddressId BIGINT = 0,
    @IsActive BIT,
    @MasterCompanyId BIGINT,
    @CreatedBy varchar(255),
    @UpdatedBy varchar(255),

    -- Address details
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
    DECLARE @ExistingPrimaryId BIGINT;
    DECLARE @ExistingBillingId BIGINT;
    DECLARE @NewAddressId BIGINT;
    DECLARE @FinalBillingId BIGINT;
	DECLARE @CustomerModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Customer');
	DECLARE @BillingAddressType INT = 1;
    BEGIN TRY
        IF @Flag = 1
        BEGIN
            BEGIN TRANSACTION;

            -- Step 1: Load existing billing addresses
            SELECT TOP 1 @ExistingPrimaryId = CustomerBillingAddressId
            FROM DBO.CustomerBillingAddress WITH(NOLOCK)
            WHERE CustomerId = @CustomerId AND IsPrimary = 1;

            SELECT TOP 1 @ExistingBillingId = CustomerBillingAddressId
            FROM DBO.CustomerBillingAddress WITH(NOLOCK)
            WHERE CustomerId = @CustomerId AND AddressId = @BillingAddressId;

            -- Step 2: If existing billing found and it's not current primary, unset previous primary
            IF @ExistingBillingId IS NOT NULL AND @ExistingBillingId != @ExistingPrimaryId
            BEGIN
                UPDATE DBO.CustomerBillingAddress
                SET IsPrimary = 0,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy
                WHERE CustomerBillingAddressId = @ExistingPrimaryId;

                EXEC USP_ShippingBillingAddressHistory
                    @CustomerId, @CustomerModuleId, @ExistingPrimaryId, @BillingAddressType, @UpdatedBy; -- 2 = Billing
            END

            -- Step 3: If matching billing address exists, update it
            IF @ExistingBillingId IS NOT NULL
            BEGIN
                UPDATE DBO.CustomerBillingAddress
                SET
                    MasterCompanyId = @MasterCompanyId,
                    SiteName = @CustomerName,
                    CreatedDate = GETUTCDATE(),
                    UpdatedDate = GETUTCDATE(),
                    CreatedBy = @CreatedBy,
                    UpdatedBy = @UpdatedBy,
                    IsPrimary = 1,
                    IsActive = 1,
                    IsDeleted = 0
                WHERE CustomerBillingAddressId = @ExistingBillingId;

                -- Update address details
                EXEC DBO.UpdateAddressDetails 
                    @BillingAddressId,
                    @Address1, @Address2, @Address3,
                    @PostalCode, @City, @StateOrProvince,
                    @CountryId, @AddressMasterCompanyId,
                    @AddressCreatedBy, @AddressCreatedDate,
                    @AddressUpdatedBy;

                SET @FinalBillingId = @ExistingBillingId;
            END
            ELSE
            BEGIN
                -- Step 4: If no matching address found, unset previous primary (if any)
                IF @ExistingPrimaryId IS NOT NULL
                BEGIN
                    UPDATE DBO.CustomerBillingAddress
                    SET IsPrimary = 0,
                        UpdatedDate = GETUTCDATE(),
                        UpdatedBy = @UpdatedBy
                    WHERE CustomerBillingAddressId = @ExistingPrimaryId;

                    EXEC USP_ShippingBillingAddressHistory
                        @CustomerId, @CustomerModuleId, @ExistingPrimaryId, @BillingAddressType, @UpdatedBy;
                END

                -- Step 5: Add new address and billing record
                EXEC USP_AddAddress
                    @Address1, @Address2, @Address3,
                    @PostalCode, @StateOrProvince,@City, 
                    @CountryId, @AddressMasterCompanyId,
                    @AddressCreatedBy,
                    @AddressUpdatedBy,
                    @NewAddressId OUTPUT;

                INSERT INTO DBO.CustomerBillingAddress (
                    CustomerId, MasterCompanyId, AddressId, SiteName,
                    CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
                    IsPrimary, IsActive, IsDeleted
                )
                VALUES (
                    @CustomerId, @MasterCompanyId, @NewAddressId, @CustomerName,
                    GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy,
                    1, 1, 0
                );

                SET @FinalBillingId = SCOPE_IDENTITY();

                -- Update Customer table
                UPDATE DBO.Customer
                SET BillingAddressId = @NewAddressId
                WHERE CustomerId = @CustomerId;
            END

            -- Final: Log history for billing
            EXEC USP_ShippingBillingAddressHistory
                @CustomerId, @CustomerModuleId, @FinalBillingId, @BillingAddressType, @UpdatedBy;

            COMMIT;
        END

        SELECT @FinalBillingId AS BillingAddressId;
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
			,@AdhocComments varchar(150) = 'AddCustomerBillingAddress',    
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