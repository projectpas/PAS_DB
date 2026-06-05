/*************************************************************           
 ** File:   [USP_SaveCustomerAging]           
 ** Author:   Moin Bloch
 ** Description: Get Customer List to Create Customer in Xero    
 ** Purpose:         
 ** Date:   05-06-2026      
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    05-06-2026     Moin Bloch   	Created

 EXECUTE [USP_SaveCustomerAging] 
**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_SaveCustomerAging]
@CustomerId        BIGINT,
@CustomerName      VARCHAR(100)    = NULL,
@CustomerCode      VARCHAR(100)    = NULL,
@AsOfDate          DATETIME2(7)    = NULL,
@TotalInvoices     INT             = NULL,
@TotalOutstanding  DECIMAL(18,6)   = 0,
@CurrentAmount     DECIMAL(18,6)   = 0,
@MasterCompanyId   INT,
@CreatedBy         VARCHAR(256),
@UpdatedBy         VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION

		DECLARE	@CreditTermsId INT = NULL,@CreditTermName VARCHAR(50) = NULL,@NetDays TINYINT = NULL,@CreditLimit DECIMAL(18,2) = NULL

		SELECT	@CreditTermsId = CF.[CreditTermsId],
                @CreditTermName = CT.[Name] ,
                @NetDays = CAST(CT.[NetDays] AS TINYINT),
                @CreditLimit = CF.[CreditLimit]
			FROM [dbo].[Customer] CST WITH(NOLOCK)
			LEFT JOIN [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CF.[CustomerId]   = CST.[CustomerId]
            LEFT JOIN [dbo].[CreditTerms]       CT WITH(NOLOCK) ON CT.[CreditTermsId] = CF.[CreditTermsId]
			WHERE CST.[CustomerId] = @CustomerId 
			  AND CST.[MasterCompanyId] = @MasterCompanyId
			  AND CST.[IsActive]        = 1
			  AND CST.[IsDeleted]       = 0;

        -- MERGE on unique key (CustomerId, AsOfDate, MasterCompanyId)
        -- INSERT if not exists, UPDATE if already exists
        MERGE [dbo].[CustomerAging] AS TARGET
        USING (
            SELECT
                @CustomerId       AS CustomerId,
                @AsOfDate         AS AsOfDate,
                @MasterCompanyId  AS MasterCompanyId,
				@CurrentAmount    AS CurrentAmount
        ) AS SOURCE
        ON (
            TARGET.[CustomerId]      = SOURCE.[CustomerId]
            AND TARGET.[AsOfDate]    = SOURCE.[AsOfDate]
            AND TARGET.[MasterCompanyId] = SOURCE.[MasterCompanyId]
			AND TARGET.[CurrentAmount] = SOURCE.[CurrentAmount]
        )


        -- UPDATE existing record
        WHEN MATCHED THEN
            UPDATE SET
                [CustomerName]     = @CustomerName,
                [CustomerCode]     = @CustomerCode,
                [CreditTermsId]    = @CreditTermsId,
                [CreditTermName]   = @CreditTermName,
                [NetDays]          = @NetDays,
                [CreditLimit]      = @CreditLimit,
                [TotalInvoices]    = @TotalInvoices,
                [TotalOutstanding] = @TotalOutstanding,
                [CurrentAmount]    = @CurrentAmount,
                [Days1_30]         = @CurrentAmount,
                [Days31_60]        = 0,
                [Days61_90]        = 0,
                [Days91_120]       = 0,
                [Days120Plus]      = 0,
                [UpdatedBy]        = @UpdatedBy,
                [UpdatedDate]      = GETUTCDATE(),
                [IsActive]         = 1,
                [IsDeleted]        = 0

        -- INSERT new record
        WHEN NOT MATCHED THEN
            INSERT (
                [CustomerId], [CustomerName], [CustomerCode],
                [CreditTermsId], [CreditTermName], [NetDays],
                [CreditLimit], [AsOfDate], [TotalInvoices],
                [TotalOutstanding], [CurrentAmount],
                [Days1_30], [Days31_60], [Days61_90],
                [Days91_120], [Days120Plus],
                [MasterCompanyId], [CreatedBy], [UpdatedBy],
                [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
            )
            VALUES (
                @CustomerId, @CustomerName, @CustomerCode,
                @CreditTermsId, @CreditTermName, @NetDays,
                @CreditLimit, @AsOfDate, @TotalInvoices,
                @TotalOutstanding, @CurrentAmount,
                @CurrentAmount, 0, 0,
                0, 0,
                @MasterCompanyId, @CreatedBy, @UpdatedBy,
                GETUTCDATE(), GETUTCDATE(), 1, 0
            );
			
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorLogID           INT,
                @DatabaseName         VARCHAR(100) = DB_NAME(),
                @AdhocComments        VARCHAR(150)  = 'USP_SaveCustomerAging',
                @ProcedureParameters  VARCHAR(3000) =
                    '@CustomerId = '       + CAST(ISNULL(@CustomerId, '')      AS VARCHAR(50)) +
                    ', @MasterCompanyId = '+ CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(50)) +
                    ', @AsOfDate = '       + CAST(ISNULL(@AsOfDate, '')        AS VARCHAR(50)),
                @ApplicationName      VARCHAR(100)  = 'PAS';

        EXEC spLogException
            @DatabaseName        = @DatabaseName,
            @AdhocComments       = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName     = @ApplicationName,
            @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN(1);
    END CATCH
END