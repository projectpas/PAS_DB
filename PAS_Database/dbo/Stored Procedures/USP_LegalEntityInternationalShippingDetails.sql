/*************************************************************           
 ** File:		 [USP_LegalEntityInternationalShippingDetails]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity International Shipping Details.
 ** Purpose:         
 ** Date:   27-June-2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    27-June-2025		Divyesh Kathiriya	Created	
	2	 30-June-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity International Shipping Details.
    
 -- EXEC [USP_LegalEntityInternationalShippingDetails] @LegalEntityShippingAddressId=0,@LegalEntityId=41,@SiteName=N'Site Name',@Attention=N'Attention',@Address1=N'Address 1',@Address2=N'Address 2',@StateOrProvince=N'State',
												@City=N'City',@PostalCode=N'Zip Code',@CountryId=3,@MasterCompanyId=1,@CreatedBy=N'DANE PERK',@UpdatedBy=N'DANE PERK',@IsPrimary=1,@TagName=N'ACCOUNTS PAYABLES'
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityInternationalShippingDetails]
@LegalEntityInternationalShippingId BIGINT,
@LegalEntityId BIGINT,
@ExportLicense VARCHAR(200) = NULL,
@StartDate DATETIME,
@Amount INT,
@IsPrimary BIT,
@Description VARCHAR(250) = NULL,
@ExpirationDate DATETIME,
@ShipToCountryId BIGINT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
/***************Start Save LegalEntity Shipping Address Details.***************/
		IF(ISNULL(@LegalEntityInternationalShippingId, 0) = 0)
		BEGIN
			--If New Default, Reset Old Default To No-Default.
			IF (ISNULL(@IsPrimary, 0) = 1)
			BEGIN
				IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalShipping] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1)
				BEGIN					
					UPDATE [DBO].[LegalEntityInternationalShipping]
					SET [IsPrimary] = 0,
						[UpdatedDate] = GETUTCDATE(),
						[UpdatedBy] = @UpdatedBy
					WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1;					
				END
			END
			ELSE
			BEGIN
				-- If No Other Primary Exists, Mark As Primary
				IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalShipping] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1)
				BEGIN
					SET @IsPrimary = 1;
				END
			END

			-- Insert LegalEntity Shipping Address Details
			INSERT INTO [DBO].[LegalEntityInternationalShipping] (
				[LegalEntityId], [ExportLicense], [StartDate], [Amount], [IsPrimary], [Description], [ExpirationDate], [ShipToCountryId],
				[MasterCompanyId],[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
				VALUES (
				@LegalEntityId, @ExportLicense, @StartDate, @Amount, @IsPrimary, @Description, @ExpirationDate, @ShipToCountryId,
				@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0)

			SET @LegalEntityInternationalShippingId = SCOPE_IDENTITY();

		END
/***************End Save LegalEntity Shipping Address Details***************/
/***************Start Update LegalEntity Shipping Address Details.***************/
		ELSE
		BEGIN
			IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalShipping] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityInternationalShippingId] = @LegalEntityInternationalShippingId)
			BEGIN

			--IF NEW PRIMARY, RESET OLD PRIMARY TO NO-PRIMARY
				IF (ISNULL(@IsPrimary, 0) = 1)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalShipping] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND @IsPrimary = 1 AND [LegalEntityInternationalShippingId] != @LegalEntityInternationalShippingId)
					BEGIN	
						UPDATE [DBO].[LegalEntityInternationalShipping]
						SET [IsPrimary] = 0,
							[UpdatedBy] = @UpdatedBy,
							[UpdatedDate] = GETUTCDATE()
						WHERE [LegalEntityId] = @LegalEntityId
						AND @IsPrimary = 1
						AND [LegalEntityInternationalShippingId] != @LegalEntityInternationalShippingId;
					END
				END

				UPDATE [DBO].[LegalEntityInternationalShipping]
				SET
					[ExportLicense] = @ExportLicense,						
					[StartDate] = @StartDate,						
					[Amount] = @Amount,
					[IsPrimary] = @IsPrimary,
					[Description] = @Description,
					[ExpirationDate] = @ExpirationDate,
					[ShipToCountryId] = @ShipToCountryId,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()					
				WHERE [LegalEntityInternationalShippingId] = @LegalEntityInternationalShippingId;
			END
		END
/***************End Update LegalEntity Shipping Address Details***************/
				
		SELECT @LegalEntityInternationalShippingId AS LegalEntityInternationalShippingId;	
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityInternationalShippingDetails'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END