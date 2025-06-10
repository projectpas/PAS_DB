/*************************************************************           
 ** File:		 [USP_LegalEntityBankingLockBox]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity Banking LockBox.
 ** Purpose:         
 ** Date:   27-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    27-May-2025		Divyesh Kathiriya	Created
    2	 28-May-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity Banking LockBox.

 -- EXEC [USP_LegalEntityBankingLockBox] 
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityBankingLockBox]
@LegalEntityId BIGINT,
@LegalEntityBankingLockBoxId BIGINT,
@BankName VARCHAR(100),
@BankAccountNumber VARCHAR(50),
@PayeeName VARCHAR(100) = NULL,
@PoBox VARCHAR(30) = NULL,
@Address1 VARCHAR(50),
@Address2 VARCHAR(50) = NULL,
@StateOrProvince VARCHAR(50),
@City VARCHAR(50),
@PostalCode VARCHAR(20),
@CountryId INT,
@GLAccountId BIGINT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@IsPrimay BIT = NULL,
@AccountTypeId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
	-- Declare variables
	DECLARE @AddressId BIGINT;	
	DECLARE @Deposit INT = 1;
	DECLARE @Disbursement INT = 2;
	DECLARE @Both INT = 3;

/***************Start Save LegalEntity BankingLockBox Details***************/
		IF(ISNULL(@LegalEntityBankingLockBoxId, 0) = 0)
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
			IF (ISNULL(@IsPrimay, 0) = 1)
			BEGIN
				-- RESET EXISTING DEPOSIT/DISBURSEMENT/BOTH IF CONFLICTING				
				IF(@AccountTypeId = @Deposit OR @AccountTypeId = @Both)
				BEGIN
					
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit;
					END

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement)
						BEGIN
							UPDATE [DBO].[LegalEntityBankingLockBox]
							SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
							WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both;
						END
					END					
				END

				IF(@AccountTypeId = @Disbursement OR @AccountTypeId = @Both)
				BEGIN

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement;
					END

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit)
						BEGIN
							UPDATE [DBO].[LegalEntityBankingLockBox]
							SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
							WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both;
						END
					END
				END

				IF(@AccountTypeId = @Both)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both;
					END
				END
			END
			ELSE
			BEGIN
				-- IF NO OTHER PRIMARY EXISTS, MARK AS PRIMARY
				IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
				BEGIN
					SET @IsPrimay = 1;
				END
			END

			-- INSERT LEGALENTITY BANKING LOCKBOX
			INSERT INTO [DBO].[LegalEntityBankingLockBox](
				[LegalEntityId], [AddressId], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
				[IsActive], [IsDeleted], [PayeeName], [GLAccountId], [BankName], [BankAccountNumber],  [IsPrimay], [AccountTypeId])
			VALUES (
				@LegalEntityId, @AddressId, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
				1, 0, @PayeeName, @GLAccountId, @BankName, @BankAccountNumber, @IsPrimay, @AccountTypeId);
				
				SET @LegalEntityBankingLockBoxId = SCOPE_IDENTITY();

				Select @LegalEntityBankingLockBoxId AS legalEntityBankingLockBoxId, @AddressId AS addressId, ISNULL(@IsPrimay, 0) AS isPrimay
		END
/***************End Save LegalEntity BankingLockBox Details***************/
/***************Start Update LegalEntity BankingLockBox Details***************/
		ELSE
		BEGIN
			SELECT @AddressId = [AddressId] FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityBankingLockBoxId] = @LegalEntityBankingLockBoxId;
						
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
			IF (ISNULL(@IsPrimay, 0) = 1)
			BEGIN
				-- RESET EXISTING DEPOSIT/DISBURSEMENT/BOTH IF CONFLICTING				
				IF(@AccountTypeId = @Deposit OR @AccountTypeId = @Both)
				BEGIN
					
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId;
					END

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement)
						BEGIN
							UPDATE [DBO].[LegalEntityBankingLockBox]
							SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
							WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both;
						END
					END					
				END

				IF(@AccountTypeId = @Disbursement OR @AccountTypeId = @Both)
				BEGIN

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId;
					END

					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both)
					BEGIN
						IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit)
						BEGIN
							UPDATE [DBO].[LegalEntityBankingLockBox]
							SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
							WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Both;
						END
					END
				END

				IF(@AccountTypeId = @Both)
				BEGIN
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @AccountTypeId;
					END
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Disbursement;
					END
					IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityBankingLockBox] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit)
					BEGIN
						UPDATE [DBO].[LegalEntityBankingLockBox]
						SET [IsPrimay] = 0, [UpdatedDate] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
						WHERE [LegalEntityId] = @LegalEntityId AND [LegalEntityBankingLockBoxId] != @LegalEntityBankingLockBoxId AND [IsPrimay] = 1 AND [AccountTypeId] = @Deposit;
					END
				END
			END

			UPDATE [DBO].[LegalEntityBankingLockBox]
			SET LegalEntityId = @LegalEntityId,
				UpdatedBy = @UpdatedBy,			
				UpdatedDate = GETUTCDATE(),				
				PayeeName = @PayeeName,
				GLAccountId = @GLAccountId,
				BankName = @BankName,
				BankAccountNumber = @BankAccountNumber,
				IsPrimay = @IsPrimay,				
				AccountTypeId = @AccountTypeId				
			WHERE LegalEntityBankingLockBoxId = @LegalEntityBankingLockBoxId;
			
			Select @LegalEntityBankingLockBoxId AS legalEntityBankingLockBoxId, @AddressId AS addressId, ISNULL(@IsPrimay, 0) AS isPrimay

		END
/***************End Update LegalEntity BankingLockBox Details***************/
	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityBankingLockBox'
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