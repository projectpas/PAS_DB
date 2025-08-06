
/***************************************************************  
 ** File:  [USP_UpdateCustomerDetails]            
 ** Author:   Ayushi Patel
 ** Description: Update Customer with default values
 ** Date:  31-July-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    31-July-2025		Ayushi Patel			Created
	SELECT TOP 1 * FROM dbo.CodePrefixes WITH(NOLOCK) WHERE MasterCompanyId =1 AND CodeTypeId = 10 AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateCustomerDetails]
    @CustmerId BIGINT,
	@CustomerModuleId BIGINT,
    @CustomerClassificationVal VARCHAR(256) = NULL,
	@CustomerAffiliationVal VARCHAR(256) = NULL,
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
		DECLARE @CustomerCode varchar(50);
		DECLARE @CurrentIdNumber BIGINT =0
		DECLARE @CustomerCodeTypeId BIGINT = (SELECT [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE UPPER([CodeType]) = 'Customer')
		SELECT * INTO #TempCodePrefix FROM(SELECT TOP 1 * FROM dbo.CodePrefixes WITH(NOLOCK) WHERE MasterCompanyId =@MasterCompanyId AND CodeTypeId = @CustomerCodeTypeId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0) AS A
		SELECT @CurrentIdNumber = CASE WHEN CurrentNummber > 0 THEN CAST(CurrentNummber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END	FROM #TempCodePrefix WHERE CodeTypeId = @CustomerCodeTypeId
		SET @CustomerCode = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentIdNumber + 1, (SELECT CodePrefix FROM #TempCodePrefix WHERE CodeTypeId = @CustomerCodeTypeId), (SELECT CodeSufix FROM #TempCodePrefix WHERE CodeTypeId = @CustomerCodeTypeId)))
        
		DECLARE @CustomerClassificationId BIGINT;
		--DECLARE @CustomerAffiliationId BIGINT;
		SET @CustomerClassificationId = @CustomerClassificationVal
		INSERT INTO DBO.ClassificationMapping  ([ModuleId],[ReferenceId],[ClasificationId],[CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])VALUES (@CustomerModuleId,@CustmerId,@CustomerClassificationId,'AUTO SCRIPT', GETUTCDATE(), 'AUTO SCRIPT', GETUTCDATE(), 1, 0);
		--SET @CustomerAffiliationId = (Select CustomerAffiliationId from DBO.CustomerAffiliation WITH (NOLOCK) WHERE Description = @CustomerAffiliationVal);
		
        UPDATE c
        SET
			--c.CustomerAffiliationId = @CustomerAffiliationId,
			C.CustomerCode = @CustomerCode

        FROM dbo.Customer c WITH (NOLOCK)
        WHERE
            c.CustomerId = @CustmerId AND
            c.MasterCompanyId = @MasterCompanyId;
		
		Update dbo.CodePrefixes SET CurrentNummber = ISNULL(CurrentNummber,0) +1 WHERE CodePrefixId = (SELECT top 1 CodePrefixId FROM #TempCodePrefix)

		DECLARE 
			@CustomerName NVARCHAR(100),
			@CustomerEmail NVARCHAR(100),
			@CustomerPhone NVARCHAR(50),
			@CustomerPhoneExt NVARCHAR(50),
			@IsActive BIT,
			@CreatedBy NVARCHAR(100),
			@UpdatedBy NVARCHAR(100);

		SELECT
			@CustomerName = Name,
			@CustomerEmail = Email,
			@CustomerPhone = CustomerPhone,
			@CustomerPhoneExt = CustomerPhoneExt,
			@IsActive = IsActive,
			@CreatedBy = CreatedBy,
			@UpdatedBy = UpdatedBy
		FROM dbo.Customer WITH(NOLOCK)
		WHERE CustomerId = @CustmerId;

		EXEC USP_AddCustomerDefaultContact
			@CustomerId = @CustmerId,
			@CustomerName = @CustomerName,
			@CustomerEmail = @CustomerEmail,
			@CustomerPhone = @CustomerPhone,
			@CustomerPhoneExt = @CustomerPhoneExt,
			@MasterCompanyId = @MasterCompanyId,
			@IsActive = @IsActive,
			@CreatedBy = @CreatedBy,
			@UpdatedBy = @UpdatedBy;
	
	 
        -- Shipping Address Billing Address Starts --
      
        DECLARE 
            @ShippingAddressId BIGINT = 0,
			@BillingAddressId BIGINT = 0,
            @Address1 NVARCHAR(200),
            @Address2 NVARCHAR(200),
            @Address3 NVARCHAR(200),
            @PostalCode NVARCHAR(50),
            @StateOrProvince NVARCHAR(100),
            @City NVARCHAR(100),
            @CountryId BIGINT,
			@CreatedDate DATETIME = GETUTCDATE(),
			@UpdatedDate DATETIME = GETUTCDATE(),
            @ShippingAddressMappingId BIGINT;

        -- Try to fetch existing shipping address for customer
		declare @AddressId bigint=( SELECT AddressId from Customer where CustomerId = @CustmerId)
        SELECT TOP 1 
            @ShippingAddressId = A.AddressId,
			@BillingAddressId = A.AddressId,
            @Address1 = A.Line1,
            @Address2 = A.Line2,
            @Address3 = A.Line3,
            @PostalCode = A.PostalCode,
            @StateOrProvince = A.StateOrProvince,
            @City = A.City,
            @CountryId = A.CountryId
        FROM dbo.Address A WITH (NOLOCK)
        --INNER JOIN dbo.CustomerDomensticShipping DS WITH (NOLOCK)
        --    ON A.AddressId = DS.AddressId
        WHERE A.AddressId = @AddressId
        --ORDER BY DS.CustomerDomensticShippingId DESC;
		
        EXEC [dbo].AddCustomerShippingAddress
            @CustomerId = @CustmerId,
            @CustomerName = @CustomerName,
            @ShippingAddressId = @ShippingAddressId,
            @MasterCompanyId = @MasterCompanyId,
            @IsActive = @IsActive,
            @CreatedBy = @CreatedBy,
            @UpdatedBy = @UpdatedBy,
            @Address1 = @Address1,
            @Address2 = @Address2,
            @Address3 = @Address3,
            @PostalCode = @PostalCode,
            @StateOrProvince = @StateOrProvince,
            @City = @City,
            @CountryId = @CountryId,
			@AddressMasterCompanyId =@MasterCompanyId,
			@AddressCreatedBy = @CreatedBy,
			@AddressCreatedDate = @CreatedDate,
			@AddressUpdatedBy = @UpdatedDate,
			@Flag = 1;
       
	   EXEC [dbo].AddCustomerBillingAddress
			@CustomerId = @CustmerId,
			@CustomerName = @CustomerName,
			@BillingAddressId = @BillingAddressId,
			@IsActive= @IsActive,
			@MasterCompanyId = @MasterCompanyId,
			@CreatedBy = @CreatedBy,
			@UpdatedBy = @UpdatedBy,
			@Address1 = @Address1,
			@Address2 = @Address2,
			@Address3 = @Address3,
			@PostalCode = @PostalCode,
			@City = @City,
			@StateOrProvince  = @StateOrProvince,
			@CountryId = @CountryId,
			@AddressMasterCompanyId =@MasterCompanyId,
			@AddressCreatedBy = @CreatedBy,
			@AddressCreatedDate= @CreatedDate,
			@AddressUpdatedBy = @UpdatedDate,
			@Flag = 1
		
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_UpdateCustomerDetails]',
                @ProcedureParameters VARCHAR(3000) = 
                    '@ItemMasterId = ' + CAST(@CustmerId AS VARCHAR(10)) + 
                    ', @MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR(10)),
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC dbo.spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR ('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 16, 1, @ErrorLogID);
    END CATCH
END