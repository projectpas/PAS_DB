/*************************************************************
** Author:  Kishor Makwana
** Create date: 11/09/2026
** Description: Create or Update the Aircraft / Fleet Quote header
**              (dbo.FleetQuote). Same convention as
**              dbo.USP_GetFleetQuoteShipToSiteInfo (see PN-17698) -
**              spLogException error handling, READ UNCOMMITTED,
**              single procedure keyed off @FleetQuoteId, matching
**              the branching already used by
**              FleetQuoteRepository.CreateOrUpdateFleetQuote().
**
**              @FleetQuoteId = 0/NULL -> INSERT a new row. @VersionNo
**              and @FleetQuoteNumber are computed by the API side
**              (FleetQuoteRepository.GetVersionCodePrefix() /
**              GetNextFleetQuoteNumber()) and passed in here - this
**              procedure does not generate them itself.
**              @FleetQuoteId > 0 -> UPDATE the existing row. Only the
**              columns the front end actually edits are touched -
**              FleetQuoteNumber/VersionNo/CreatedBy/CreatedDate are
**              left alone on update, same as the C# Update branch.
**
** RETURN VALUE: a single row/column, FleetQuoteId - the row's PK
**               (existing id on update, the new identity on insert).
**
** EXEC [USP_CreateOrUpdateFleetQuote]
**************************************************************
** Change History
**************************************************************
** PR   Date        Author            Change Description
** --   --------    -------           --------------------------------
** 1    11/09/2026   Kishor Makwana    Created [PN-17698]
** 2    11/09/2026   Kishor Makwana    Added @QuoteScope/@PromisedTatDays [PN-17698]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateOrUpdateFleetQuote]
    @FleetQuoteId BIGINT = NULL,
    @WorkOrderId BIGINT = NULL,
    @OpenDate DATETIME2(7),
    @QuoteDueDate DATETIME2(7),
    @ValidForDays INT = NULL,
    @ExpirationDate DATETIME2(7) = NULL,
    @FleetQuoteStatusId BIGINT,
    @CustomerId BIGINT,
    @CurrencyId INT,
    @DSO VARCHAR(256) = NULL,
    @AccountsReceivableBalance DECIMAL(18, 6) = NULL,
    @SalesPersonId BIGINT = NULL,
    @EmployeeId BIGINT,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256),
    @Memo NVARCHAR(MAX) = NULL,
    @Warnings VARCHAR(256) = NULL,
    @SentDate DATETIME2(7) = NULL,
    @ApprovedDate DATETIME2(7) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @CustomerName VARCHAR(200) = NULL,
    @CustomerContact VARCHAR(200) = NULL,
    @CustomerContactId BIGINT = NULL,
    @AircraftTailNumber VARCHAR(100) = NULL,
    @FleetName VARCHAR(100) = NULL,
    @CreditLimit DECIMAL(18, 6) = NULL,
    @CreditTerms VARCHAR(200) = NULL,
    @ReportCurrencyId INT = NULL,
    @ForeignExchangeRate DECIMAL(18, 6) = NULL,
    @IsPrintCorrectiveAction BIT = NULL,
    @ShipToSiteId BIGINT = NULL,
    @ShipToSiteName VARCHAR(100) = NULL,
    @Line1 VARCHAR(50) = NULL,
    @Line2 VARCHAR(50) = NULL,
    @City VARCHAR(50) = NULL,
    @StateOrProvince VARCHAR(50) = NULL,
    @PostalCode VARCHAR(50) = NULL,
    @CountryId BIGINT = NULL,
    @ApprovalCode VARCHAR(200) = NULL,
    @VersionNo VARCHAR(20) = NULL,
    @FleetQuoteNumber VARCHAR(100) = NULL,
    @QuoteScope VARCHAR(50) = NULL,
    @PromisedTatDays INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    IF (ISNULL(@FleetQuoteId, 0) > 0) AND NOT EXISTS (SELECT 1 FROM [dbo].[FleetQuote] WITH (NOLOCK) WHERE [FleetQuoteId] = @FleetQuoteId)
    BEGIN
        RAISERROR('Aircraft / Fleet Quote %d was not found.', 16, 1, @FleetQuoteId);
        RETURN;
    END

    BEGIN TRY
    BEGIN TRANSACTION
    BEGIN
        DECLARE @Now DATETIME2(7) = GETDATE();

        IF (ISNULL(@FleetQuoteId, 0) > 0)
        BEGIN
            UPDATE [dbo].[FleetQuote]
            SET
                [WorkOrderId] = @WorkOrderId,
                [OpenDate] = @OpenDate,
                [QuoteDueDate] = @QuoteDueDate,
                [ValidForDays] = @ValidForDays,
                [ExpirationDate] = @ExpirationDate,
                [FleetQuoteStatusId] = @FleetQuoteStatusId,
                [CustomerId] = @CustomerId,
                [CurrencyId] = @CurrencyId,
                [DSO] = @DSO,
                [AccountsReceivableBalance] = @AccountsReceivableBalance,
                [SalesPersonId] = @SalesPersonId,
                [EmployeeId] = @EmployeeId,
                [Memo] = @Memo,
                [Warnings] = @Warnings,
                [SentDate] = @SentDate,
                [ApprovedDate] = @ApprovedDate,
                [Notes] = @Notes,
                [CustomerName] = @CustomerName,
                [CustomerContact] = @CustomerContact,
                [CustomerContactId] = @CustomerContactId,
                [AircraftTailNumber] = @AircraftTailNumber,
                [FleetName] = @FleetName,
                [CreditLimit] = @CreditLimit,
                [CreditTerms] = @CreditTerms,
                [ReportCurrencyId] = @ReportCurrencyId,
                [ForeignExchangeRate] = @ForeignExchangeRate,
                [IsPrintCorrectiveAction] = @IsPrintCorrectiveAction,
                [ShipToSiteId] = @ShipToSiteId,
                [ShipToSiteName] = @ShipToSiteName,
                [Line1] = @Line1,
                [Line2] = @Line2,
                [City] = @City,
                [StateOrProvince] = @StateOrProvince,
                [PostalCode] = @PostalCode,
                [CountryId] = @CountryId,
                [ApprovalCode] = @ApprovalCode,
                [QuoteScope] = @QuoteScope,
                [PromisedTatDays] = @PromisedTatDays,
                [UpdatedBy] = @UpdatedBy,
                [UpdatedDate] = @Now
            WHERE [FleetQuoteId] = @FleetQuoteId;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[FleetQuote]
            (
                [WorkOrderId], [FleetQuoteNumber], [OpenDate], [QuoteDueDate], [ValidForDays],
                [ExpirationDate], [FleetQuoteStatusId], [CustomerId], [CurrencyId], [DSO],
                [AccountsReceivableBalance], [SalesPersonId], [EmployeeId], [MasterCompanyId],
                [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted],
                [Memo], [Warnings], [SentDate], [ApprovedDate], [VersionNo], [Notes],
                [CustomerName], [CustomerContact], [CustomerContactId], [AircraftTailNumber],
                [FleetName], [CreditLimit], [CreditTerms], [ReportCurrencyId], [ForeignExchangeRate],
                [IsPrintCorrectiveAction], [ShipToSiteId], [ShipToSiteName], [Line1], [Line2],
                [City], [StateOrProvince], [PostalCode], [CountryId], [ApprovalCode],
                [QuoteScope], [PromisedTatDays]
            )
            VALUES
            (
                @WorkOrderId, @FleetQuoteNumber, @OpenDate, @QuoteDueDate, @ValidForDays,
                @ExpirationDate, @FleetQuoteStatusId, @CustomerId, @CurrencyId, @DSO,
                @AccountsReceivableBalance, @SalesPersonId, @EmployeeId, @MasterCompanyId,
                @CreatedBy, @UpdatedBy, @Now, @Now, 1, 0,
                @Memo, @Warnings, @SentDate, @ApprovedDate, @VersionNo, @Notes,
                @CustomerName, @CustomerContact, @CustomerContactId, @AircraftTailNumber,
                @FleetName, @CreditLimit, @CreditTerms, @ReportCurrencyId, @ForeignExchangeRate,
                @IsPrintCorrectiveAction, @ShipToSiteId, @ShipToSiteName, @Line1, @Line2,
                @City, @StateOrProvince, @PostalCode, @CountryId, @ApprovalCode,
                @QuoteScope, @PromisedTatDays
            );

            SET @FleetQuoteId = SCOPE_IDENTITY();
        END

        COMMIT TRANSACTION;

        SELECT @FleetQuoteId AS FleetQuoteId;
    END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateOrUpdateFleetQuote'
              , @ProcedureParameters VARCHAR(3000)  = '@FleetQuoteId = '+ ISNULL(CAST(@FleetQuoteId AS VARCHAR(20)), '') +
                                                       ', @MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(20)), '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END