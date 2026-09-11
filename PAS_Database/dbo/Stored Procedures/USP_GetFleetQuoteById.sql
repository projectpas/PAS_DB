/*************************************************************
** Author:  Kishor Makwana
** Create date: 11/09/2026
** Description: Get the Aircraft / Fleet Quote header (dbo.FleetQuote)
**              by id. Same convention as
**              dbo.USP_GetFleetQuoteShipToSiteInfo (see PN-17698) -
**              READ UNCOMMITTED, spLogException error handling.
**
**              Mirrors FleetQuoteRepository.GetFleetQuoteById()'s
**              previous EF LINQ logic exactly:
**                - dbo.FleetQuoteStatus.Description is returned as
**                  FleetQuoteStatusDescription.
**                - AccountsReceivableBalance is recomputed from the
**                  latest dbo.CustomerAging row for the quote's
**                  CustomerId (TOP 1 ... ORDER BY CustomerAgingId DESC,
**                  same pattern dbo.GetWorkOrderById already uses),
**                  defaulting to 0. Left untouched (the stored value)
**                  when the quote has no CustomerId.
**                - CustomerName falls back to dbo.Customer only when the
**                  FleetQuote row's own CustomerName column is blank.
**                  CustomerEmail/CustomerPhone are never persisted on
**                  dbo.FleetQuote at all ([NotMapped] - see FleetQuote.cs),
**                  so they always resolve from dbo.Customer by CustomerId,
**                  same as dbo.GetWorkOrderById's own unconditional
**                  @Email/@CustomerPhone lookup.
**
**              AircraftTailNumber is persisted as a comma-separated
**              list of dbo.AircraftRegistryHeader.AircraftRegistryId
**              values (the Angular multi-select's own ids - see
**              fleet-quote.component.ts) - resolved here to the
**              matching comma-separated TailNum list for display,
**              same source table dbo.USP_GetAircraftTailNumberList uses.
**
**              EmployeeName/SalesPersonName are resolved from
**              dbo.Employee.FirstName + ' ' + LastName via
**              FleetQuote.EmployeeId/SalesPersonId - same convention as
**              dbo.GetWorkOrderById's own @EmployeeName/@SalesPersonName
**              lookups.
**
** EXEC [USP_GetFleetQuoteById] 14
**************************************************************
** Change History
**************************************************************
** PR   Date        Author            Change Description
** --   --------    -------           --------------------------------
** 1    11/09/2026   Kishor Makwana    Created [PN-17698]
** 2    11/09/2026   Kishor Makwana    Added QuoteScope/PromisedTatDays [PN-17698]
** 3    11/09/2026   Kishor Makwana    Resolved EmployeeName/SalesPersonName [PN-17698]
** 4    11/09/2026   Kishor Makwana    Fixed CustomerEmail/CustomerPhone - was only
                                       resolving when CustomerName was blank, which
                                       is effectively never, so they always came
                                       back NULL; now always resolved by CustomerId
                                       [PN-17698]
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetFleetQuoteById]
    @FleetQuoteId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        SELECT
            fq.[FleetQuoteId],
            fq.[WorkOrderId],
            fq.[FleetQuoteNumber],
            fq.[OpenDate],
            fq.[QuoteDueDate],
            fq.[ValidForDays],
            fq.[ExpirationDate],
            fq.[FleetQuoteStatusId],
            fq.[CustomerId],
            fq.[CurrencyId],
            fq.[DSO],
            CASE WHEN fq.[CustomerId] > 0 THEN ISNULL(ca.[TotalOutstanding], 0) ELSE fq.[AccountsReceivableBalance] END AS [AccountsReceivableBalance],
            fq.[SalesPersonId],
            fq.[EmployeeId],
            fq.[MasterCompanyId],
            fq.[CreatedBy],
            fq.[CreatedDate],
            fq.[UpdatedBy],
            fq.[UpdatedDate],
            fq.[IsActive],
            fq.[IsDeleted],
            fq.[Memo],
            fq.[Warnings],
            fq.[SentDate],
            fq.[ApprovedDate],
            fq.[VersionNo],
            fq.[IsApprovalBypass],
            fq.[QuoteParentId],
            fq.[IsVersionIncrease],
            fq.[Notes],
            CASE WHEN ISNULL(fq.[CustomerName], '') = '' THEN c.[Name] ELSE fq.[CustomerName] END AS [CustomerName],
            fq.[CustomerContact],
            fq.[CustomerContactId],
            CASE WHEN ISNULL(fq.[AircraftTailNumber], '') = '' THEN fq.[AircraftTailNumber] ELSE tn.[TailNumberList] END AS [AircraftTailNumber],
            fq.[FleetName],
            fq.[CreditLimit],
            fq.[CreditTerms],
            fq.[ReportCurrencyId],
            fq.[ForeignExchangeRate],
            fq.[IsPrintCorrectiveAction],
            fq.[ShipToSiteId],
            fq.[ShipToSiteName],
            fq.[Line1],
            fq.[Line2],
            fq.[City],
            fq.[StateOrProvince],
            fq.[PostalCode],
            fq.[CountryId],
            fq.[ApprovalCode],
            fq.[QuoteScope],
            fq.[PromisedTatDays],
            fqs.[Description] AS [FleetQuoteStatusDescription],
            -- Unconditional - CustomerEmail/CustomerPhone have no column on
            -- dbo.FleetQuote to fall back to, so always resolve by CustomerId
            -- (same as dbo.GetWorkOrderById's @Email/@CustomerPhone).
            c.[Email] AS [CustomerEmail],
            c.[CustomerPhone] AS [CustomerPhone],
            emp.[FirstName] + ' ' + emp.[LastName] AS [EmployeeName],
            spEmp.[FirstName] + ' ' + spEmp.[LastName] AS [SalesPersonName]
        FROM [dbo].[FleetQuote] fq WITH (NOLOCK)
        LEFT JOIN [dbo].[FleetQuoteStatus] fqs WITH (NOLOCK) ON fqs.[FleetQuoteStatusId] = fq.[FleetQuoteStatusId]
        LEFT JOIN [dbo].[Employee] emp WITH (NOLOCK) ON emp.[EmployeeId] = fq.[EmployeeId]
        LEFT JOIN [dbo].[Employee] spEmp WITH (NOLOCK) ON spEmp.[EmployeeId] = fq.[SalesPersonId]
        OUTER APPLY (
            SELECT TOP 1 [TotalOutstanding]
            FROM [dbo].[CustomerAging] WITH (NOLOCK)
            WHERE [CustomerId] = fq.[CustomerId]
            ORDER BY [CustomerAgingId] DESC
        ) ca
        LEFT JOIN [dbo].[Customer] c WITH (NOLOCK) ON c.[CustomerId] = fq.[CustomerId] AND fq.[CustomerId] > 0
        OUTER APPLY (
            SELECT STRING_AGG(ah.[TailNum], ',') AS [TailNumberList]
            FROM STRING_SPLIT(fq.[AircraftTailNumber], ',') s
            INNER JOIN [dbo].[AircraftRegistryHeader] ah WITH (NOLOCK)
                ON ah.[AircraftRegistryId] = TRY_CAST(s.[value] AS BIGINT)
            WHERE ISNULL(fq.[AircraftTailNumber], '') <> ''
        ) tn
        WHERE fq.[FleetQuoteId] = @FleetQuoteId
          AND (fq.[IsDeleted] = 0 OR fq.[IsDeleted] IS NULL);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetFleetQuoteById'
              , @ProcedureParameters VARCHAR(3000)  = '@FleetQuoteId = '+ ISNULL(CAST(@FleetQuoteId AS VARCHAR(20)), '')
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