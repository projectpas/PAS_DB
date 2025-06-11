/*************************************************************           
 ** File:		 [USP_LegalEntityBankingACH]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity ACH Payment Details.
 ** Purpose:         
 ** Date:   03-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    03-June-2025		Divyesh Kathiriya	Created
    2	 04-June-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity ACH Payment

 -- EXEC [USP_LegalEntityBankingACH] 
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityBankingACH]
@ACHId BIGINT,
@LegalEntityId BIGINT,
@BankName VARCHAR(100),
@IntermediateBankName VARCHAR(100) = NULL,
@BeneficiaryBankName VARCHAR(100) = NULL,
@AccountNumber VARCHAR(50),
@ABA VARCHAR(50),
@SwiftCode VARCHAR(100) = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@IsPrimay BIT = NULL,
@GLAccountId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION	
	
/***************Start Save LegalEntity ACH Payment Details.***************/
	IF(ISNULL(@ACHId, 0) = 0)
	BEGIN
		--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
		IF (ISNULL(@IsPrimay, 0) = 1)
        BEGIN
			IF EXISTS (SELECT 1 FROM [DBO].[ACH] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
			BEGIN
				UPDATE [DBO].[ACH]
				SET [IsPrimay] = 0,
					[UpdatedDate] = GETUTCDATE(),
					[UpdatedBy] = @UpdatedBy
				WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1;;
			END
        END
        ELSE
        BEGIN
			-- IF NO OTHER PRIMARY EXISTS, MARK AS PRIMARY
            IF NOT EXISTS (SELECT 1 FROM [DBO].[ACH] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
            BEGIN
                SET @IsPrimay = 1;
            END
        END

		--INSERT ACH PAYMENT
		INSERT INTO [DBO].[ACH](
				[ABA], [AccountNumber], [BankName], [BeneficiaryBankName], [IntermediateBankName], [SwiftCode], [LegalEntityId],
				[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [GLAccountId], [IsPrimay]) 
		VALUES(  
				@ABA, @AccountNumber, @BankName, @BeneficiaryBankName, @IntermediateBankName, @SwiftCode, @LegalEntityId, 
				@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, @GLAccountId, @IsPrimay			
			   );        

		SET @ACHId = SCOPE_IDENTITY();
		
		SELECT @ACHId AS ACHId,	ISNULL(@IsPrimay, 0) AS isPrimay;
	END
/***************End Save LegalEntity ACH Payment Details***************/
/***************Start Update LegalEntity ACH Payment Details***************/
	ELSE
	BEGIN		
		--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
		IF (ISNULL(@IsPrimay, 0) = 1)
        BEGIN
			IF EXISTS (SELECT 1 FROM [DBO].[ACH] WITH(NOLOCK) WHERE [ACHId] != @ACHId AND [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
			BEGIN
				UPDATE [DBO].[ACH]
				SET [IsPrimay] = 0,
					[UpdatedBy] = @UpdatedBy,
					[UpdatedDate] = GETUTCDATE()
				WHERE [ACHId] != @ACHId 
				AND [LegalEntityId] = @LegalEntityId				  
				AND [IsPrimay] = 1;
			END
        END

		--UPDATE LEGALENTITY ACH PAYMENT
        UPDATE [DBO].[ACH]
		SET	[ABA] = @ABA,
			[AccountNumber] = @AccountNumber,
			[BankName] = @BankName,
			[BeneficiaryBankName] = @BeneficiaryBankName,
			[IntermediateBankName] = @IntermediateBankName,
			[SwiftCode] = @SwiftCode,            
			[LegalEntityId] = @LegalEntityId,
			[UpdatedBy] = @UpdatedBy,
			[UpdatedDate] = GETUTCDATE(),
			[GLAccountId] = @GLAccountId,
			[IsPrimay] = @IsPrimay 			
        WHERE [ACHId] = @ACHId;
		
		SELECT @ACHId AS ACHId,	ISNULL(@IsPrimay, 0) AS isPrimay;
		
/***************End Update LegalEntity ACH Payment Details***************/
	END
	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityBankingACH'
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