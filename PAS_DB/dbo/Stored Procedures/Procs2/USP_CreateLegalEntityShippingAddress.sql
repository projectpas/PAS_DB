 /*************************************************************           
 ** File:		 [USP_CreateLegalEntityShippingAddress]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create Or Update LegalEntity Shipping Address.
 ** Purpose:         
 ** Date:   13-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    13-June-2025		Divyesh Kathiriya	Created
	2	 18-June-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity Shipping Address.
    
 -- EXEC [USP_CreateLegalEntityShippingAddress] @LegalEntityShippingAddressId=0,@LegalEntityId=41,@SiteName=N'Site Name',@Attention=N'Attention',@Address1=N'Address 1',@Address2=N'Address 2',@StateOrProvince=N'State',
												@City=N'City',@PostalCode=N'Zip Code',@CountryId=3,@MasterCompanyId=1,@CreatedBy=N'DANE PERK',@UpdatedBy=N'DANE PERK',@IsPrimary=1,@TagName=N'ACCOUNTS PAYABLES,@ContactTagId=9'
**************************************************************/
Create   PROCEDURE [DBO].[USP_CreateLegalEntityShippingAddress]
@LegalEntityShippingAddressId BIGINT,
@LegalEntityId BIGINT,
@SiteName VARCHAR(256),
@Attention VARCHAR(100),
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = NULL,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50),
@PostalCode VARCHAR(20),
@CountryId INT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@IsPrimary BIT,
@TagName VARCHAR(250) = NULL,
@ContactTagId BIGINT= NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

		-- Declare variables
		DECLARE @AddressId BIGINT;													
		DECLARE @ShippingAddressId BIGINT;													
		DECLARE @ShippingAddressType INT = 2;
		DECLARE @LegalEntityModuleId INT;
			
		SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';		

		-- Error Msg
		IF OBJECT_ID(N'tempdb..#tmpmsg') IS NOT NULL        
		BEGIN        
			DROP TABLE #tmpmsg    
		END   

		CREATE TABLE #tmpmsg
		(        
			msg VARCHAR(256) NULL    
		)

/***************Start Save LegalEntity Shipping Address Details.***************/
		IF(ISNULL(@LegalEntityShippingAddressId, 0) = 0)
		BEGIN
			-- Check For Duplicate SiteName.
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [SiteName] = @SiteName)
			BEGIN

				-- Insert LegalEntity Address Details
				INSERT INTO [DBO].[Address]( 
						[Line1], [Line2], [City], [StateOrProvince], [PostalCode],	[CountryId],
						[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate],	[UpdatedDate], [IsActive], [IsDeleted])
				VALUES(
						@Address1, @Address2, @City, @StateOrProvince, @PostalCode, @CountryId,
						@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0)
 					
				SET @AddressId = SCOPE_IDENTITY();

				--If New Default, Reset Old Default To No-Default.
				IF (ISNULL(@IsPrimary, 0) = 1)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId)
					BEGIN
						SELECT @ShippingAddressId = [LegalEntityShippingAddressId] FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId;

						UPDATE [DBO].[LegalEntityShippingAddress]
						SET [IsPrimary] = 0,
							[UpdatedDate] = GETUTCDATE(),
							[UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId;

						EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@ShippingAddressId,@ShippingAddressType,@UpdatedBy;
					END
				END
				ELSE
				BEGIN
					-- If No Other Primary Exists, Mark As Primary
					IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1)
					BEGIN
						SET @IsPrimary = 1;
					END
				END

				-- Insert LegalEntity Shipping Address Details
				INSERT INTO [DBO].[LegalEntityShippingAddress] (
					[LegalEntityId], [AddressId], [SiteName], [IsPrimary],
					[MasterCompanyId],[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [Attention], [TagName], [ContactTagId])
					VALUES (
					@LegalEntityId, @AddressId, @SiteName, @IsPrimary,
					@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @Attention, @TagName, @ContactTagId)

				SET @LegalEntityShippingAddressId = SCOPE_IDENTITY();

				EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@LegalEntityShippingAddressId,@ShippingAddressType,@UpdatedBy;
								
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Site name already exist with these details.!');					
			END
		END
/***************End Save LegalEntity Shipping Address Details***************/
/***************Start Update LegalEntity Shipping Address Details***************/
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [SiteName] = @SiteName AND [LegalEntityId] = @LegalEntityId AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId)
			BEGIN
				IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId)
				BEGIN
					SELECT @AddressId = [AddressId] FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId;

					IF EXISTS (SELECT 1 FROM [DBO].[Address] WITH(NOLOCK) WHERE [AddressId] = @AddressId)
					BEGIN
						UPDATE [DBO].[Address]
						SET 
							[Line1] = @Address1,
							[Line2] = @Address2,							
							[City] = @City,
							[StateOrProvince] = @StateOrProvince,
							[PostalCode] = @PostalCode,
							[CountryId] = @CountryId,							
							[UpdatedBy] = @UpdatedBy,
							[UpdatedDate] = GETUTCDATE()							
						WHERE [AddressId] = @AddressId;
					END

					--IF NEW PRIMARY, RESET OLD PRIMARY TO NO-PRIMARY
					IF (ISNULL(@IsPrimary, 0) = 1)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND @IsPrimary = 1 AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId)
						BEGIN
							
							SELECT @ShippingAddressId = [LegalEntityShippingAddressId] FROM [DBO].[LegalEntityShippingAddress] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1;

							UPDATE [DBO].[LegalEntityShippingAddress]
							SET [IsPrimary] = 0,
								[UpdatedBy] = @UpdatedBy,
								[UpdatedDate] = GETUTCDATE()
							WHERE [LegalEntityId] = @LegalEntityId
								AND [LegalEntityShippingAddressId] != @LegalEntityShippingAddressId
								AND [IsPrimary] = 1;

							EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@ShippingAddressId,@ShippingAddressType,@UpdatedBy;
						END
					END

					UPDATE [DBO].[LegalEntityShippingAddress]
					SET
						[SiteName] = @SiteName,						
						[IsPrimary] = @IsPrimary,						
						[UpdatedBy] = @UpdatedBy,
						[UpdatedDate] = GETUTCDATE(),
						[Attention] = @Attention,
						[TagName] = @TagName,
						[ContactTagId] = @ContactTagId
					WHERE [LegalEntityShippingAddressId] = @LegalEntityShippingAddressId;

					EXEC [DBO].[USP_ShippingBillingAddressHistory] @LegalEntityId,@LegalEntityModuleId,@LegalEntityShippingAddressId,@ShippingAddressType,@UpdatedBy;
				END
				ELSE
				BEGIN
					INSERT INTO #tmpmsg(msg) VALUES ('Entity Shipping Update failed');					
				END
			END
			ELSE
			BEGIN
				INSERT INTO #tmpmsg(msg) VALUES ('Site name already exist with these details.!');					
			END

		END
/***************End Update LegalEntity Shipping Address Details***************/

		IF EXISTS (SELECT 1 FROM #tmpmsg)
		BEGIN
			SELECT msg FROM #tmpmsg;			          
		END
		ELSE
		BEGIN			
			SELECT @LegalEntityShippingAddressId AS LegalEntityShippingAddressId, @AddressId AS AddressId;
		END		
	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateLegalEntityShippingAddress'
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