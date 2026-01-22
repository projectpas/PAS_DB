/*****************************************************************************************************************
Author:        Rajesh Gami
Created Date:  2025-10-15
Description:   Migration script to loop through all LegalEntity records and insert data into 
               LegalEntityInternationalWirePaymentV2 using USP_GetEntityInternationalWireById.
------------------------------------------------------------------------------------------------------------------
Modification History:
Date        Author          Description
15-10-25    Rajesh Gami     Created

EXEC [dbo].[USP_Migrate_LegalEntityInternationalWireDataFromDomestic]
*****************************************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Migrate_LegalEntityInternationalWireDataFromDomestic]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @LegalEntityId BIGINT;
        DECLARE @MasterCompanyId BIGINT;
        DECLARE @EmployeeId BIGINT = 0;

        -- Create the global temp table once
        IF OBJECT_ID('tempdb..##TempEntityWireData') IS NOT NULL
            DROP TABLE ##TempEntityWireData;

        CREATE TABLE ##TempEntityWireData
        (
            Internationaldata BIT,
            SwiftCode NVARCHAR(50),
            BeneficiaryBankAccount NVARCHAR(50),
            BeneficiaryBank NVARCHAR(200),
            BeneficiaryCustomer NVARCHAR(200),
            BankName NVARCHAR(200),
            BankAddressId BIGINT,
            IntermediaryBank NVARCHAR(200),
            IsActive BIT,
            IsDeleted BIT,
            IsPrimay BIT,
            CreatedDate DATETIME,
            CreatedBy NVARCHAR(200),
            UpdatedBy NVARCHAR(200),
            UpdatedDate DATETIME,
            LegalEntityInternationalWireBankingId BIGINT,
            ABA NVARCHAR(50),
            InternationalWirePaymentId BIGINT,
            BankLocation1 NVARCHAR(200),
            BankLocation2 NVARCHAR(200),
            GLAccountId BIGINT,
            GLAccount NVARCHAR(500)
        );

        -- Cursor to loop through all LegalEntity
        DECLARE curLegalEntity CURSOR LOCAL FAST_FORWARD FOR
            SELECT LegalEntityId, MasterCompanyId
            FROM dbo.LegalEntity WITH(NOLOCK);

        OPEN curLegalEntity;
        FETCH NEXT FROM curLegalEntity INTO @LegalEntityId, @MasterCompanyId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Only proceed if no primary record exists in V2
            IF NOT EXISTS (
                SELECT 1
                FROM dbo.LegalEntityInternationalWireBankingV2
                WHERE LegalEntityId = @LegalEntityId
                  AND IsPrimay = 1
            )
            BEGIN
			PRINT 'INsert Data into ##TempEntityWireData '
                -- Call USP_GetEntityInternationalWireById which inserts data into global temp table
               INSERT INTO ##TempEntityWireData
					(
						Internationaldata, SwiftCode, BeneficiaryBankAccount, BeneficiaryBank, BeneficiaryCustomer,
						BankName, BankAddressId, IntermediaryBank, IsActive, IsDeleted, IsPrimay,
						CreatedDate, CreatedBy, UpdatedBy, UpdatedDate, LegalEntityInternationalWireBankingId,
						ABA, InternationalWirePaymentId, BankLocation1, BankLocation2, GLAccountId, GLAccount
					)
					SELECT 
						CASE WHEN t.[InternationalWirePaymentId] IS NOT NULL THEN 1 ELSE 0 END AS Internationaldata,
						t.[SwiftCode],
						t.[BeneficiaryBankAccount],
						t.[BeneficiaryBank],
						ISNULL(t.[BeneficiaryCustomer], '') AS BeneficiaryCustomer,
						t.[BankName],
						t.[BankAddressId],
						t.[IntermediaryBank],
						ISNULL(ad.[IsActive], 1) AS IsActive,
						ISNULL(ad.[IsDeleted], 0) AS IsDeleted,
						ISNULL(ad.[IsPrimay], 0) AS IsPrimay,
					CAST(ad.[CreatedDate] AS DATETIME) AS CreatedDate,
						ad.CreatedBy,
						ad.UpdatedBy,
						 CAST(ad.[UpdatedDate] AS DATETIME) AS UpdatedDate,
						ad.[LegalEntityInternationalWireBankingId],
						t.[ABA],
						t.[InternationalWirePaymentId],
						t.[BankLocation1],
						t.[BankLocation2],
						t.[GLAccountId],
						CASE WHEN glac.[GLAccountId] IS NOT NULL THEN CONCAT(glac.[AccountCode], ' - ', glac.[AccountName]) ELSE '' END AS GLAccount
					FROM [DBO].[InternationalWirePayment] t WITH(NOLOCK)
					INNER JOIN [DBO].[LegalEntityInternationalWireBanking] ad WITH(NOLOCK)
						ON t.[InternationalWirePaymentId] = ad.[InternationalWirePaymentId]
					LEFT JOIN [DBO].[GLAccount] glac WITH(NOLOCK) 
						ON t.[GLAccountId] = glac.[GLAccountId]
					WHERE ad.[LegalEntityId] = @LegalEntityId
					ORDER BY ad.[CreatedDate] DESC;

                -- Check if global temp table has any rows
				PRINT 'Table Data'
                IF EXISTS (SELECT 1 FROM ##TempEntityWireData)
                BEGIN
                    -- Loop through each row in temp table and call V2 SP
                    DECLARE @Id BIGINT, @BankName NVARCHAR(200), @IntermediaryBank NVARCHAR(200),
                            @BeneficiaryBank NVARCHAR(200), @BeneficiaryBankAccount NVARCHAR(50),
                            @SwiftCode NVARCHAR(50), @BankLocation1 NVARCHAR(200), @BankLocation2 NVARCHAR(200),
                            @CreatedBy NVARCHAR(200), @UpdatedBy NVARCHAR(200), @ABA NVARCHAR(50),
                            @IsPrimay BIT, @GLAccountId BIGINT;

                    DECLARE curWire CURSOR LOCAL FAST_FORWARD FOR
                        SELECT LegalEntityInternationalWireBankingId, BankName, IntermediaryBank, BeneficiaryBank,
                               BeneficiaryBankAccount, SwiftCode, BankLocation1, BankLocation2, CreatedBy,
                               UpdatedBy, ABA, IsPrimay, GLAccountId
                        FROM ##TempEntityWireData;

                    OPEN curWire;
                    FETCH NEXT FROM curWire INTO @Id, @BankName, @IntermediaryBank, @BeneficiaryBank, 
                                               @BeneficiaryBankAccount, @SwiftCode, @BankLocation1, @BankLocation2,
                                               @CreatedBy, @UpdatedBy, @ABA, @IsPrimay, @GLAccountId;

                    WHILE @@FETCH_STATUS = 0
                    BEGIN
					PRINT 'Call the SP'
                        EXEC dbo.USP_LegalEntityInternationalWirePaymentV2
                            @LegalEntityInternationalWireBankingId = 0,
                            @LegalEntityId = @LegalEntityId,
                            @BankName = @BankName,
                            @IntermediaryBank = @IntermediaryBank,
                            @BeneficiaryBank = @BeneficiaryBank,
                            @BeneficiaryBankAccount = @BeneficiaryBankAccount,
                            @SwiftCode = @SwiftCode,
                            @BankLocation1 = @BankLocation1,
                            @BankLocation2 = @BankLocation2,
                            @MasterCompanyId = @MasterCompanyId,
                            @CreatedBy = @CreatedBy,
                            @UpdatedBy = @UpdatedBy,
                            @ABA = @ABA,
                            @IsPrimay = @IsPrimay,
                            @GLAccountId = @GLAccountId;

                        FETCH NEXT FROM curWire INTO @Id, @BankName, @IntermediaryBank, @BeneficiaryBank, 
                                                   @BeneficiaryBankAccount, @SwiftCode, @BankLocation1, @BankLocation2,
                                                   @CreatedBy, @UpdatedBy, @ABA, @IsPrimay, @GLAccountId;
                    END

                    CLOSE curWire;
                    DEALLOCATE curWire;

                    -- Clear temp table for next LegalEntity
                    TRUNCATE TABLE ##TempEntityWireData;
                END
            END

            FETCH NEXT FROM curLegalEntity INTO @LegalEntityId, @MasterCompanyId;
        END

        CLOSE curLegalEntity;
        DEALLOCATE curLegalEntity;

        -- Drop global temp table after migration
        DROP TABLE ##TempEntityWireData;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name(),
                @AdhocComments VARCHAR(150) = 'USP_Migrate_LegalEntityInternationalWireDataFromDomestic',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException @DatabaseName = @DatabaseName,
                            @AdhocComments = @AdhocComments,
                            @ProcedureParameters = @ProcedureParameters,
                            @ApplicationName = @ApplicationName,
                            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred in the database. Error number: %d', 16, 1, @ErrorLogID);
        RETURN 1;
    END CATCH
END