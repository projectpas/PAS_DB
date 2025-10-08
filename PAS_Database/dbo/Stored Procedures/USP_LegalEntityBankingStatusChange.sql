/*************************************************************           
 ** File:		 [USP_LegalEntityBankingStatusChange]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update Legal Entity Banking Status.
 ** Purpose:         
 ** Date:   11-July-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    11-July-2025		Divyesh Kathiriya	Created
    2    09-Sept-2025		Rajesh Gami			Added Cheque Banking    
	3    08-Oct-2025		Rajesh Gami			Added Legal Entity InternationalWire Banking V2   
 -- EXEC [USP_LegalEntityBankingStatusChange] @BankingId=23, @Status=N'InActive', @UpdatedBy=N'DANE PERK', @BankingType=1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_LegalEntityBankingStatusChange]
@BankingId BIGINT = 0,
@Status VARCHAR(20),
@UpdatedBy VARCHAR(256),
@BankingType INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsActive BIT;	
	DECLARE @Lockbox INT = 1;       
    DECLARE @InternationalWire INT = 2;      
    DECLARE @ACH INT = 3;
	DECLARE @ChequeType INT = 4;
	DECLARE @InternationalWireV2 INT = 6;
    IF (LOWER(@Status) = LOWER('Active'))
	BEGIN
        SET @IsActive = 1;
	END
    ELSE
	BEGIN
        SET @IsActive = 0;
	END

	IF(ISNULL(@BankingId, 0) > 0)		
	BEGIN
		IF (@BankingType = @Lockbox)
		BEGIN			
			UPDATE [DBO].[LegalEntityBankingLockBox] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [LegalEntityBankingLockBoxId] = @BankingId;			
		END
		ELSE IF (@BankingType = @InternationalWire)
		BEGIN			
			UPDATE [DBO].[LegalEntityInternationalWireBanking] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [InternationalWirePaymentId] = @BankingId;			
		END
		ELSE IF (@BankingType = @InternationalWireV2)
		BEGIN			
			UPDATE [DBO].[LegalEntityInternationalWireBankingV2] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [InternationalWirePaymentId] = @BankingId;			
		END
		ELSE IF (@BankingType = @ACH)
		BEGIN			
			UPDATE [DBO].[ACH] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [ACHId] = @BankingId;			
		END
		ELSE IF (@BankingType = @ChequeType)
		BEGIN			
			UPDATE [DBO].[LegalEntityBankingCheque] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [LegalEntityBankingChequeId] = @BankingId;			
		END
	END

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_LegalEntityBankingStatusChange'
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