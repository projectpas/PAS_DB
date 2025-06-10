/*************************************************************           
 ** File:		 [USP_LegalEntityInternationalWirePayment]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity International Wire Payment.
 ** Purpose:         
 ** Date:   30-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    30-May-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_LegalEntityInternationalWirePayment] 
**************************************************************/
Create   PROCEDURE [DBO].[USP_LegalEntityInternationalWirePayment]
@LegalEntityInternationalWireBankingId BIGINT,
@InternationalWirePaymentId BIGINT = NULL,
@LegalEntityId BIGINT,
@BankName VARCHAR(100),
@IntermediaryBank VARCHAR(100) = NULL,
@BeneficiaryBank VARCHAR(100) = NULL,
@BeneficiaryBankAccount VARCHAR(50),
@SwiftCode VARCHAR(50) = NULL,
@BankLocation1 VARCHAR(250) = NULL,
@BankLocation2 VARCHAR(250) = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@ABA VARCHAR(256),
@IsPrimay BIT = NULL,
@GLAccountId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION	
	
/***************Start Save LegalEntity International Wire Payment Details***************/
	IF(ISNULL(@LegalEntityInternationalWireBankingId, 0) = 0)
	BEGIN
		--INSERT INTERNATIONAL WIRE PAYMENT
		INSERT INTO [DBO].[InternationalWirePayment](
				 [SwiftCode], [BeneficiaryBankAccount], [BeneficiaryBank], [BankName], [IntermediaryBank],
				 [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
				 [ABA], [BankLocation1], [BankLocation2], [GLAccountId]) 
		VALUES(
				@SwiftCode, @BeneficiaryBankAccount, @BeneficiaryBank, @BankName, @IntermediaryBank,
				@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0,
				@ABA, @BankLocation1, @BankLocation2, @GLAccountId);

		SET @InternationalWirePaymentId = SCOPE_IDENTITY();

		--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
		IF (ISNULL(@IsPrimay, 0) = 1)
        BEGIN
			IF EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalWireBanking] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
			BEGIN
				UPDATE [DBO].[LegalEntityInternationalWireBanking]
				SET [IsPrimay] = 0,
					[UpdatedDate] = GETUTCDATE(),
					[UpdatedBy] = @UpdatedBy
				WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1;
			END
        END
        ELSE
        BEGIN
			-- IF NO OTHER PRIMARY EXISTS, MARK AS PRIMARY
            IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityInternationalWireBanking] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsPrimay] = 1)
            BEGIN
                SET @IsPrimay = 1;
            END
        END

		--INSERT LEGALENTITY INTERNATIONAL WIRE BANKING
		INSERT INTO [DBO].[LegalEntityInternationalWireBanking](
				[LegalEntityId], [InternationalWirePaymentId], [MasterCompanyId],
				[CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
				[IsActive], [IsDeleted], [IsPrimay])
        VALUES(
				@LegalEntityId, @InternationalWirePaymentId, @MasterCompanyId,
				@CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
				1, 0, @IsPrimay);

        SET @LegalEntityInternationalWireBankingId = SCOPE_IDENTITY();

		SELECT @InternationalWirePaymentId AS InternationalWirePaymentId,
			   @LegalEntityInternationalWireBankingId AS LegalEntityInternationalWireBankingId,
			   ISNULL(@IsPrimay, 0) AS isPrimay;
	END
/***************End Save LegalEntity International Wire Payment Details***************/
	
	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityInternationalWirePayment'
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