/***************************************************************  
 ** File:  [USP_UpdateVendorDetails]            
 ** Author:   Bhargav Saliya
 ** Description: Updates Vendor Details after create through import functionality
 ** Date:  07-Aug-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    07-Aug-2025		Bhargav Saliya			Created
	exec [USP_UpdateVendorDetails] 4882,1 ,1
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateVendorDetails]
@VendorId BIGINT,
@MasterCompanyId INT,
@VendorClassificationId VARCHAR
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @VendorCode VARCHAR(50) = NULL,@VendorName VARCHAR(100) = NULL,@VendorEmail VARCHAR(200) = NULL,@VendorPhone VARCHAR(256) = NULL,
				@VendorPhoneExt VARCHAR(10) = NULL,@CreatedBy VARCHAR(256) = NULL,@UpdatedBy VARCHAR(256) = NULL,@Address1 VARCHAR(50) = NULL,
				@Address2 VARCHAR(50) = NULL,@PostalCode VARCHAR(20) = NULL,@StateOrProvince VARCHAR(50) = NULL,@City VARCHAR(50) = NULL,
				@CountryId SMALLINT,@IsAddressForShipping BIT,@AddressId BIGINT,@VendorShippingAddressId BIGINT,@IsAddressForBilling BIT,
				@VendorBillingAddressId BIGINT;

		DECLARE @BillingAddressId INT = 1;
		DECLARE @ShippingAddressId INT = 2;

		DECLARE @VendorModuleId BIGINT = (SELECT ModuleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Vendor');
		DECLARE @ModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM [dbo].AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');

		SELECT  @AddressId = AddressId
			   ,@VendorCode = VendorCode
			   ,@VendorName = VendorName
			   ,@VendorEmail = VendorEmail
			   ,@VendorPhone = VendorPhone
			   ,@VendorPhoneExt = VendorPhoneExt
			   ,@IsAddressForShipping = IsAddressForShipping
			   ,@IsAddressForBilling = IsAddressForBilling
			   ,@CreatedBy = CreatedBy
			   ,@UpdatedBy = UpdatedBy
		FROM [dbo].[Vendor] WITH(NOLOCK) WHERE VendorId = @VendorId and MasterCompanyId = @MasterCompanyId;

		SELECT @Address1 = Line1
			  ,@Address2 = Line2
			  ,@PostalCode = PostalCode
			  ,@StateOrProvince = StateOrProvince
			  ,@City = City
			  ,@CountryId = CountryId
		FROM [dbo].[Address] WITH(NOLOCK) WHERE AddressId = @AddressId and MasterCompanyId = @MasterCompanyId;
		IF @VendorCode IS NULL OR UPPER(@VendorCode) = 'CREATING'
        BEGIN
            DECLARE @Number BIGINT = 0;
			DECLARE @CodePrefixId BIGINT = 0;
			DECLARE @CodePrefix VARCHAR(50) = '', @CodeSufix VARCHAR(50) = '';

			SELECT 
				@Number = ISNULL(CP.CurrentNummber, CP.StartsFrom), 
				@CodePrefixId = CP.CodePrefixId,
				@CodePrefix = CP.CodePrefix,
				@CodeSufix = CP.CodeSufix
			FROM [dbo].CodeTypes CT WITH (NOLOCK)
			INNER JOIN dbo.CodePrefixes CP WITH (NOLOCK) ON CT.CodeTypeId = CP.CodeTypeId
			WHERE 
				CT.IsActive = 1 AND CT.IsDeleted = 0 AND
				CP.IsActive = 1 AND CP.IsDeleted = 0 AND
				CP.MasterCompanyId = @MasterCompanyId AND
				CT.CodeType = 'Vendor';

			SET @VendorCode = (SELECT * FROM [DBO].[udfGenerateCodeNumberWithOutDash](CAST(@Number AS BIGINT) + 1, @codePrefix,@codeSufix));
			UPDATE CodePrefixes
			SET CurrentNummber = @Number + 1
			WHERE CodePrefixId = @CodePrefixId;
        END

		UPDATE Vendor SET VendorCode = @VendorCode WHERE VendorId = @VendorId and MasterCompanyId = @MasterCompanyId; 

		EXEC USP_AddOrUpdateVendorDefaultContact @VendorId, @VendorName, @VendorEmail, @VendorPhone, @VendorPhoneExt, @MasterCompanyId, @CreatedBy, @UpdatedBy;
        EXEC USP_AddVendorPayment @VendorId, @VendorName, @Address1, @Address2, @PostalCode, @StateOrProvince, @City, @CountryId, @MasterCompanyId, @CreatedBy, @UpdatedBy;

		IF @VendorClassificationId IS NOT NULL
		BEGIN
			INSERT INTO dbo.ClassificationMapping(ClasificationId,ModuleId,ReferenceId,IsActive,IsDeleted,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy)
			Values(CAST(@VendorClassificationId AS BIGINT),@VendorModuleId,@VendorId,1,0,GETUTCDATE(),GETUTCDATE(),@CreatedBy,@CreatedBy)
		END

  --      --EXEC USP_CreateClassificationMappings @VendorClassificationId, 3, @VendorId, @CreatedBy;
  --      --EXEC USP_CreateIntegrationMappings @IntegrationPortalIds, 3, @VendorId, @CreatedBy;

        IF @IsAddressForShipping = 1
        BEGIN
            INSERT INTO VendorShippingAddress (
                VendorId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted
            )
            VALUES (
                @VendorId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0
            );
			
            SET @VendorShippingAddressId = SCOPE_IDENTITY();

            UPDATE Vendor SET ShippingAddressId = @AddressId WHERE VendorId = @VendorId;
			
            EXEC USP_ShippingBillingAddressHistory 
                @VendorId, @ModuleId, @VendorShippingAddressId, @ShippingAddressId, @UpdatedBy;
        END

        IF @IsAddressForBilling = 1
        BEGIN
            INSERT INTO VendorBillingAddress (
                VendorId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted
            )
            VALUES (
                @VendorId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0
            );

            SET @VendorBillingAddressId = SCOPE_IDENTITY();

            UPDATE Vendor SET BillingAddressId = @AddressId WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory 
                @VendorId, @ModuleId, @VendorBillingAddressId, @BillingAddressId, @UpdatedBy;
        END
	COMMIT TRANSACTION
	END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'            
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateVendorDetails'             
			   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorId, '') AS VARCHAR(100))
			                                       + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
												   + '@Parameter3 = ''' + CAST(ISNULL(@VendorClassificationId, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH    
END