/*****************************************************************************************************************
Author:        Rajesh Gami
Created Date:  2025-10-15
Description:   Migration script to loop through all LegalEntity records and insert data into 
               LegalEntityBankingCheque using USP_GetEntityBankingLockBoxData.
------------------------------------------------------------------------------------------------------------------
Modification History:
Date        Author          Description
15-10-25    Rajesh Gami     Created

EXEC  [dbo].[USP_Migrate_LegalEntityBankingChequeData]
*****************************************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Migrate_LegalEntityBankingChequeData]
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        DECLARE @LegalEntityId BIGINT;

        IF CURSOR_STATUS('global', 'cur_LegalEntity_Migrate') >= -1
            DEALLOCATE cur_LegalEntity_Migrate;

        DECLARE cur_LegalEntity_Migrate CURSOR FAST_FORWARD FOR
        SELECT LegalEntityId FROM dbo.LegalEntity WITH (NOLOCK);

        OPEN cur_LegalEntity_Migrate;
        FETCH NEXT FROM cur_LegalEntity_Migrate INTO @LegalEntityId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT '-----------------------------------------------------------';
            PRINT 'Processing LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20));
            PRINT '-----------------------------------------------------------';

            IF OBJECT_ID('tempdb..#LockBoxData') IS NOT NULL
                DROP TABLE #LockBoxData;

            CREATE TABLE #LockBoxData
            (
                LocboxData BIT NULL,
                LegalEntityId BIGINT NULL,
                LegalEntityBankingLockBoxId BIGINT NULL,
                MasterCompanyId BIGINT NULL,
                IsActive BIT NULL,
                IsDeleted BIT NULL,
                CreatedBy NVARCHAR(256) NULL,
                CreatedDate DATETIME NULL,
                UpdatedBy NVARCHAR(256) NULL,
                UpdatedDate DATETIME NULL,
                IsPrimay BIT NULL,
                AddressId BIGINT NULL,
                Address1 NVARCHAR(256) NULL,
                Address2 NVARCHAR(256) NULL,
                City NVARCHAR(100) NULL,
                StateOrProvince NVARCHAR(100) NULL,
                PostalCode NVARCHAR(50) NULL,
                PoBox NVARCHAR(100) NULL,
                Country NVARCHAR(200) NULL,
                CountryId INT NULL,
                Domesticdata BIT NULL,
                PayeeName NVARCHAR(200) NULL,
                GLAccountId BIGINT NULL,
                GlAccount NVARCHAR(400) NULL,
                BankName NVARCHAR(200) NULL,
                AttachmentId BIGINT NULL,
                BankAccountNumber NVARCHAR(200) NULL,
                FileName NVARCHAR(500) NULL,
                Link NVARCHAR(1000) NULL,
                AccountTypeId INT NULL,
                AccountType NVARCHAR(50) NULL
            );

            -- Populate temp table from your existing SP
            INSERT INTO #LockBoxData
            (
                LocboxData, LegalEntityId, LegalEntityBankingLockBoxId, MasterCompanyId,
                IsActive, IsDeleted, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate,
                IsPrimay, AddressId, Address1, Address2, City, StateOrProvince, PostalCode,
                PoBox, Country, CountryId, Domesticdata, PayeeName, GLAccountId, GlAccount,
                BankName, AttachmentId, BankAccountNumber, FileName, Link, AccountTypeId, AccountType
            )
            EXEC DBO.USP_GetEntityBankingLockBoxData @LegalEntityId = @LegalEntityId, @EmployeeId = 0;

            -- If no rows returned, skip this entity
            IF NOT EXISTS (SELECT 1 FROM #LockBoxData)
            BEGIN
                PRINT 'No lockbox data returned for LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20));
                FETCH NEXT FROM cur_LegalEntity_Migrate INTO @LegalEntityId;
                CONTINUE;
            END

            -- Variables for inner cursor
            DECLARE 
                @LegalEntityBankingChequeId BIGINT = 0,
                @BankName NVARCHAR(200),
                @LockboxNumber NVARCHAR(100) = N'',
                @PayeeName NVARCHAR(200),
                @PoBox NVARCHAR(100),
                @Address1 NVARCHAR(256),
                @Address2 NVARCHAR(256),
                @StateOrProvince NVARCHAR(100),
                @City NVARCHAR(100),
                @PostalCode NVARCHAR(50),
                @CountryId INT,
                @GLAccountId BIGINT,
                @MasterCompanyId BIGINT,
                @CreatedBy NVARCHAR(256),
                @UpdatedBy NVARCHAR(256),
                @IsPrimary BIT,
                @AccountTypeId INT;

            -- Deallocate inner cursor if exists
            IF CURSOR_STATUS('global', 'cur_LockBox_Migrate') >= -1
                DEALLOCATE cur_LockBox_Migrate;

            -- Only process deposit records (AccountTypeId = 1)
            IF EXISTS (SELECT 1 FROM #LockBoxData WHERE AccountTypeId = 1)
            BEGIN
                PRINT 'Found deposit (AccountTypeId = 1) records for LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20));

                DECLARE cur_LockBox_Migrate CURSOR FAST_FORWARD FOR
                SELECT 
                    BankName,
                    PayeeName,
                    PoBox,
                    Address1,
                    Address2,
                    StateOrProvince,
                    City,
                    PostalCode,
                    CountryId,
                    GLAccountId,
                    MasterCompanyId,
                    CreatedBy,
                    UpdatedBy,
                    IsPrimay,
                    AccountTypeId
                FROM #LockBoxData
                WHERE AccountTypeId = 1;

                OPEN cur_LockBox_Migrate;
                FETCH NEXT FROM cur_LockBox_Migrate INTO 
                    @BankName, @PayeeName, @PoBox, @Address1, @Address2, @StateOrProvince, 
                    @City, @PostalCode, @CountryId, @GLAccountId, @MasterCompanyId, 
                    @CreatedBy, @UpdatedBy, @IsPrimary, @AccountTypeId;

                WHILE @@FETCH_STATUS = 0
                BEGIN
                    BEGIN TRY
                        PRINT ' Inserting cheque record for LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20)) 
                              + ' | Bank: ' + ISNULL(@BankName, '') + ' | Payee: ' + ISNULL(@PayeeName, '');
						IF NOT EXISTS (SELECT * FROM LegalEntityBankingCheque WHERE LegalEntityId = @LegalEntityId AND IsPrimary = 1)
						BEGIN
							  EXEC DBO.USP_AddUpdateLegalEntityBankingCheque
								@LegalEntityId = @LegalEntityId,
								@LegalEntityBankingChequeId = @LegalEntityBankingChequeId,
								@BankName = @BankName,
								@LockboxNumber = @LockboxNumber,
								@PayeeName = @PayeeName,
								@PoBox = @PoBox,
								@Address1 = @Address1,
								@Address2 = @Address2,
								@StateOrProvince = @StateOrProvince,
								@City = @City,
								@PostalCode = @PostalCode,
								@CountryId = @CountryId,
								@GLAccountId = @GLAccountId,
								@MasterCompanyId = @MasterCompanyId,
								@CreatedBy = @CreatedBy,
								@UpdatedBy = @UpdatedBy,
								@IsPrimary = 1,    
								@AccountTypeId = 2; 
						END
                        ELSE
						BEGIN
							PRINT 'Primary Entity Banking Check already exists for LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20)) + ', skipping insert.';
						END

                    END TRY
                    BEGIN CATCH
                        DECLARE @ErrorLogID_local INT,
                                @DatabaseName_local VARCHAR(100) = DB_NAME(),
                                @AdhocComments_local VARCHAR(150) = 'USP_Migrate_LegalEntityBankingChequeData - inner record',
                                @ProcedureParameters_local VARCHAR(3000) = '@LegalEntityId=' + CAST(@LegalEntityId AS VARCHAR(20)) 
                                                                         + ', @BankName=' + ISNULL(@BankName, ''),
                                @ApplicationName_local VARCHAR(100) = 'PAS';

                        EXEC spLogException 
                            @DatabaseName = @DatabaseName_local,
                            @AdhocComments = @AdhocComments_local,
                            @ProcedureParameters = @ProcedureParameters_local,
                            @ApplicationName = @ApplicationName_local,
                            @ErrorLogID = @ErrorLogID_local OUTPUT;

                        PRINT '  >> Error logged for this record. ErrorLogID = ' + CAST(ISNULL(@ErrorLogID_local, 0) AS VARCHAR(20));
                    END CATCH

                    FETCH NEXT FROM cur_LockBox_Migrate INTO 
                        @BankName, @PayeeName, @PoBox, @Address1, @Address2, @StateOrProvince, 
                        @City, @PostalCode, @CountryId, @GLAccountId, @MasterCompanyId, 
                        @CreatedBy, @UpdatedBy, @IsPrimary, @AccountTypeId;
                END

                CLOSE cur_LockBox_Migrate;
                DEALLOCATE cur_LockBox_Migrate;
            END
            ELSE
            BEGIN
                PRINT 'No deposit (AccountTypeId = 1) records for LegalEntityId = ' + CAST(@LegalEntityId AS VARCHAR(20));
            END

            -- Drop temp table
            IF OBJECT_ID('tempdb..#LockBoxData') IS NOT NULL
                DROP TABLE #LockBoxData;

            -- Next LegalEntity
            FETCH NEXT FROM cur_LegalEntity_Migrate INTO @LegalEntityId;
        END

        CLOSE cur_LegalEntity_Migrate;
        DEALLOCATE cur_LegalEntity_Migrate;

    END TRY
    BEGIN CATCH
	 SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_Migrate_LegalEntityBankingChequeData - outer',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occurred. Please provide error number: %d', 16, 1, @ErrorLogID);
        RETURN (1);
    END CATCH
END