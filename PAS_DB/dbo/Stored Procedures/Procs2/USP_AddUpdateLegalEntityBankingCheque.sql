/*************************************************************           
 ** File:		 [USP_AddUpdateLegalEntityBankingCheque]           
 ** Author:		 Rajesh Gami
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity Banking Cheque.
 ** Purpose:         
 ** Date:   09-Sep-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    09-Sep-2025		Rajesh Gami			Created
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_AddUpdateLegalEntityBankingCheque]
@LegalEntityId BIGINT,
@LegalEntityBankingChequeId BIGINT,
@BankName VARCHAR(100) = NULL,
@LockboxNumber VARCHAR(50) = NULL,
@PayeeName VARCHAR(100) = NULL,
@PoBox VARCHAR(30) = NULL,
@Address1 VARCHAR(50) = NULL,
@Address2 VARCHAR(50) = NULL,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50) = NULL,
@PostalCode VARCHAR(20) = NULL,
@CountryId INT = NULL,
@GLAccountId BIGINT = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@IsPrimary BIT = NULL,
@AccountTypeId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
	-- Declare variables
	DECLARE @AddressId BIGINT;	
	DECLARE @LockboxType INT = 1;
	DECLARE @PrimaryType INT = 2;

	/*************** Update LegalEntity Banking Cheque Details***************/
		IF(ISNULL(@LegalEntityBankingChequeId, 0) > 0)
		BEGIN
			
			SELECT @AddressId = [AddressId] FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityBankingChequeId] = @LegalEntityBankingChequeId;
						
			UPDATE [DBO].[Address]
			SET Line1 = @Address1,
				Line2 = @Address2,
				City = @City,
				StateOrProvince = @StateOrProvince,
				PostalCode = @PostalCode,
				CountryId = @CountryId,
				PoBox =@PoBox,
				UpdatedBy = @UpdatedBy,
				UpdatedDate = GETUTCDATE()
			WHERE AddressId = @AddressId;
			
			--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
			IF (ISNULL(@IsPrimary, 0) = 1)
			BEGIN
				-- RESET EXISTING Lockbox/PrimaryType
				UPDATE [DBO].[LegalEntityBankingCheque]
						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingChequeId] != @LegalEntityBankingChequeId AND [IsPrimary] = 1
			END

			UPDATE [DBO].[LegalEntityBankingCheque]
			SET LegalEntityId = @LegalEntityId,
				UpdatedBy = @UpdatedBy,			
				UpdatedDate = GETUTCDATE(),				
				PayeeName = @PayeeName,
				GLAccountId = @GLAccountId,
				BankName = @BankName,
				LockboxNumber = @LockboxNumber,
				IsPrimary = @IsPrimary,				
				AccountTypeId = @AccountTypeId				
			WHERE LegalEntityBankingChequeId = @LegalEntityBankingChequeId;
			
			Select @LegalEntityBankingChequeId AS LegalEntityBankingChequeId, @AddressId AS addressId, ISNULL(@IsPrimary, 0) AS IsPrimary
		END 

		ELSE /***************Start Add LegalEntity Banking Cheque Details***************/
		BEGIN
			--INSERT ADDRESS
			INSERT INTO [DBO].[Address]( 
					[POBox], [Line1], [Line2], [City], [StateOrProvince], [PostalCode], [CountryId],
					[MasterCompanyId], [CreatedBy],	[UpdatedBy], [CreatedDate],	[UpdatedDate], [IsActive], [IsDeleted])
			VALUES(
					@PoBox, @Address1, @Address2, @City, @StateOrProvince, @PostalCode, @CountryId,
					@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
 					
				SET @AddressId = SCOPE_IDENTITY();

			--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
			IF (ISNULL(@IsPrimary, 0) = 1)
			BEGIN
				-- RESET EXISTING Lockbox/PrimaryType/		
				UPDATE [DBO].[LegalEntityBankingCheque]
						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1
			END
			ELSE
			BEGIN
				-- IF NO OTHER PRIMARY EXISTS, MARK AS PRIMARY
				
				IF NOT EXISTS (SELECT 1 FROM [DBO].LegalEntityBankingCheque WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
				BEGIN
					SET @IsPrimary = 1;
				END
			END

			-- INSERT LEGALENTITY BANKING LOCKBOX
			INSERT INTO [DBO].[LegalEntityBankingCheque](
				[LegalEntityId], [AddressId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
				[IsActive], [IsDeleted], [PayeeName], [GLAccountId], [BankName], [LockboxNumber],  [IsPrimary], [AccountTypeId])
			VALUES (
				@LegalEntityId, @AddressId, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
				1, 0, @PayeeName, @GLAccountId, @BankName, @LockboxNumber, @IsPrimary, @AccountTypeId);
				
				SET @LegalEntityBankingChequeId = SCOPE_IDENTITY();

				Select @LegalEntityBankingChequeId AS LegalEntityBankingChequeId, @AddressId AS addressId, ISNULL(@IsPrimary, 0) AS IsPrimary
		END


--/*************** Update LegalEntity Banking Cheque Details***************/
--		IF(ISNULL(@LegalEntityBankingChequeId, 0) > 0)
--		BEGIN
			
--			SELECT @AddressId = [AddressId] FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityBankingChequeId] = @LegalEntityBankingChequeId;
						
--			UPDATE [DBO].[Address]
--			SET Line1 = @Address1,
--				Line2 = @Address2,
--				City = @City,
--				StateOrProvince = @StateOrProvince,
--				PostalCode = @PostalCode,
--				CountryId = @CountryId,
--				PoBox =@PoBox,
--				UpdatedBy = @UpdatedBy,
--				UpdatedDate = GETUTCDATE()
--			WHERE AddressId = @AddressId;
			
--			--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
--			IF (ISNULL(@IsPrimary, 0) = 1)
--			BEGIN
--				-- RESET EXISTING Lockbox/PrimaryType		
--				IF(@AccountTypeId = @LockboxType)
--				BEGIN
					
--					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingChequeId] != @LegalEntityBankingChequeId AND [IsPrimary] = 1 AND [AccountTypeId] = @AccountTypeId)
--					BEGIN
--						UPDATE [DBO].[LegalEntityBankingCheque]
--						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
--						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingChequeId] != @LegalEntityBankingChequeId AND [IsPrimary] = 1 AND [AccountTypeId] = @AccountTypeId;
--					END
		
--				END

--				IF(@AccountTypeId = @PrimaryType)
--				BEGIN

--					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingChequeId] != @LegalEntityBankingChequeId AND [IsPrimary] = 1 AND [AccountTypeId] = @AccountTypeId)
--					BEGIN
--						UPDATE [DBO].[LegalEntityBankingCheque]
--						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
--						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingChequeId] != @LegalEntityBankingChequeId AND [IsPrimary] = 1 AND [AccountTypeId] = @AccountTypeId;
--					END
--				END
--			END

--			UPDATE [DBO].[LegalEntityBankingCheque]
--			SET LegalEntityId = @LegalEntityId,
--				UpdatedBy = @UpdatedBy,			
--				UpdatedDate = GETUTCDATE(),				
--				PayeeName = @PayeeName,
--				GLAccountId = @GLAccountId,
--				BankName = @BankName,
--				LockboxNumber = @LockboxNumber,
--				IsPrimary = @IsPrimary,				
--				AccountTypeId = @AccountTypeId				
--			WHERE LegalEntityBankingChequeId = @LegalEntityBankingChequeId;
			
--			Select @LegalEntityBankingChequeId AS LegalEntityBankingChequeId, @AddressId AS addressId, ISNULL(@IsPrimary, 0) AS IsPrimary
--		END 

--		ELSE /***************Start Add LegalEntity Banking Cheque Details***************/
--		BEGIN
--			--INSERT ADDRESS
--			INSERT INTO [DBO].[Address]( 
--					[POBox], [Line1], [Line2], [City], [StateOrProvince], [PostalCode], [CountryId],
--					[MasterCompanyId], [CreatedBy],	[UpdatedBy], [CreatedDate],	[UpdatedDate], [IsActive], [IsDeleted])
--			VALUES(
--					@PoBox, @Address1, @Address2, @City, @StateOrProvince, @PostalCode, @CountryId,
--					@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0);
 					
--				SET @AddressId = SCOPE_IDENTITY();

--			--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
--			IF (ISNULL(@IsPrimary, 0) = 1)
--			BEGIN
--				-- RESET EXISTING Lockbox/PrimaryType/			
--				IF(@AccountTypeId = @LockboxType)
--				BEGIN
					
--					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [AccountTypeId] = @LockboxType)
--					BEGIN
--						UPDATE [DBO].[LegalEntityBankingCheque]
--						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
--						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [AccountTypeId] = @LockboxType;
--					END				
--				END

--				IF(@AccountTypeId = @PrimaryType)
--				BEGIN
--					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingCheque] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [AccountTypeId] = @PrimaryType)
--					BEGIN
--						UPDATE [DBO].[LegalEntityBankingCheque]
--						SET [IsPrimary] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
--						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [AccountTypeId] = @PrimaryType;
--					END					
--				END

--			END
--			ELSE
--			BEGIN
--				-- IF NO OTHER PRIMARY EXISTS, MARK AS PRIMARY
				
--				IF NOT EXISTS (SELECT 1 FROM [DBO].LegalEntityBankingCheque WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimary] = 1 AND [AccountTypeId] = @AccountTypeId AND ISNULL(IsActive,0) = 1 AND ISNULL(IsDeleted,0) = 0)
--				BEGIN
--					SET @IsPrimary = 1;
--				END
--			END

--			-- INSERT LEGALENTITY BANKING LOCKBOX
--			INSERT INTO [DBO].[LegalEntityBankingCheque](
--				[LegalEntityId], [AddressId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
--				[IsActive], [IsDeleted], [PayeeName], [GLAccountId], [BankName], [LockboxNumber],  [IsPrimary], [AccountTypeId])
--			VALUES (
--				@LegalEntityId, @AddressId, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
--				1, 0, @PayeeName, @GLAccountId, @BankName, @LockboxNumber, @IsPrimary, @AccountTypeId);
				
--				SET @LegalEntityBankingChequeId = SCOPE_IDENTITY();

--				Select @LegalEntityBankingChequeId AS LegalEntityBankingChequeId, @AddressId AS addressId, ISNULL(@IsPrimary, 0) AS IsPrimary
--		END

	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateLegalEntityBankingCheque'
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