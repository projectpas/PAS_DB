/*************************************************************           
 ** File:   [usp_validateCustomerCredit]           
 ** Author:  Devendra Shekh	
 ** Description: This stored procedure is used validate Customer Credit Limits
 ** Purpose:         
 ** Date:   02-Sep-2025 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    02-Sep-2025	Devendra Shekh			Created

-- EXEC usp_validateCustomerCredit 4441,1 
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_validateCustomerCredit]
@CustomerId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;

	BEGIN TRY

		IF OBJECT_ID(N'tempdb..#tmpResult') IS NOT NULL    
		BEGIN    
			DROP TABLE #tmpResult
		END

		CREATE TABLE #tmpResult (
			[CustomerWarningId] [bigint]  NULL,
			[CustomerId] [bigint] NULL,
			[Allow] [bit] NULL,
			[Warning] [bit] NULL,
			[Restrict] [bit] NULL,
			[RestrictMessage] [varchar](300) NULL,
			[WarningMessage] [varchar](300) NULL,
			[MasterCompanyId] [int] NULL,
			[CreditLimit] [decimal](18, 2) NULL,
			[ByPassCreditTerm] [bit] NULL,
		)

		DECLARE @CODCreditTermCode VARCHAR(20) = 'COD';
		DECLARE @CIACreditTermCode VARCHAR(20) = 'CIA';
		DECLARE @CreditCardCreditTermCode VARCHAR(20) = 'CREDITCARD';
		DECLARE @PrepaidCreditTermCode VARCHAR(20) = 'PREPAID';
		DECLARE @CreditTermsId BIGINT = 0, @CreditTermName VARCHAR(50) = NULL, @CreditTermCode VARCHAR(20) = NULL, @ByPassCreditTerm BIT = 0;

		DECLARE @CreditLimit DECIMAL(18, 2) = 0;
		DECLARE @WarningTypeId INT = (SELECT [CustomerWarningTypeId] FROM dbo.[CustomerWarningType] WITH(NOLOCK) WHERE UPPER([Name]) = 'IF CREDIT LIMIT IS NEGATIVE');

		SELECT @CreditLimit = ISNULL(CF.CreditLimit, 0), @CreditTermsId = [CreditTermsId]
		FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK) WHERE CF.[CustomerId] = @CustomerId AND CF.[MasterCompanyId] = @MasterCompanyId;

		SELECT @CreditTermName = UPPER(TRIM([Name])), @CreditTermCode = UPPER(TRIM(ISNULL([Code], ''))) FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId] = @CreditTermsId;		

		-- Set ByPass CreditTerm Based On CreditTerm Name/Code
		SET @ByPassCreditTerm = CASE	WHEN (@CreditTermCode = @CODCreditTermCode OR @CreditTermName = @CODCreditTermCode) THEN 1
										WHEN (@CreditTermCode = @CIACreditTermCode OR @CreditTermName = @CIACreditTermCode) THEN 1
										WHEN (@CreditTermCode = @CreditCardCreditTermCode OR @CreditTermName = @CreditCardCreditTermCode) THEN 1
										WHEN (@CreditTermCode = @PrepaidCreditTermCode OR @CreditTermName = @PrepaidCreditTermCode) THEN 1
										ELSE 0 
										END
		
		-- Saving Customer Warning Details
		INSERT INTO #tmpResult ([CustomerWarningId], [CustomerId], [Allow], [Warning], [Restrict], [RestrictMessage], [WarningMessage], [MasterCompanyId], [CreditLimit], [ByPassCreditTerm])
		SELECT [CustomerWarningId], [CustomerId], [Allow], [Warning], [Restrict], [RestrictMessage], [WarningMessage], [MasterCompanyId], ISNULL(@CreditLimit, 0), @ByPassCreditTerm
		FROM [dbo].[CustomerWarning] CW WITH(NOLOCK)  
		WHERE CW.[CustomerId] = @CustomerId AND CW.[CustomerWarningTypeId] = @WarningTypeId AND CW.[MasterCompanyId] = @MasterCompanyId;
		
		-- Updating Customer Warning Details
		UPDATE TMP 
		SET
			TMP.[CustomerWarningId] = CASE WHEN @ByPassCreditTerm = 0 THEN CASE WHEN TMP.[CreditLimit] <= 0 THEN TMP.[CustomerWarningId] ELSE 0 END ELSE TMP.[CustomerWarningId]  END,
			TMP.[Warning] = CASE WHEN @ByPassCreditTerm = 0 THEN CASE WHEN TMP.[CreditLimit] <= 0 THEN TMP.[Warning] ELSE 0 END ELSE TMP.[Warning]  END,
			TMP.[Restrict] = CASE WHEN @ByPassCreditTerm = 0 THEN CASE WHEN TMP.[CreditLimit] <= 0 THEN TMP.[Restrict] ELSE 0 END ELSE TMP.[Restrict]  END,
			TMP.[RestrictMessage] = CASE WHEN @ByPassCreditTerm = 0 THEN CASE WHEN TMP.[CreditLimit] <= 0 THEN TMP.[RestrictMessage] ELSE '' END ELSE TMP.[RestrictMessage]  END,
			TMP.[WarningMessage] = CASE WHEN @ByPassCreditTerm = 0 THEN CASE WHEN TMP.[CreditLimit] <= 0 THEN TMP.[WarningMessage] ELSE '' END ELSE TMP.[WarningMessage]  END
		FROM #tmpResult TMP
		
		SELECT
			CW.[CustomerId] AS 'customerId',
			CW.[CustomerWarningId] AS 'customerWarningId',
			CW.[Allow] AS 'allow',
			CW.[Warning] AS 'warning',
			CW.[Restrict] AS 'restrict',
			CW.[RestrictMessage] AS 'restrictMessage',
			CW.[WarningMessage] AS 'warningMessage',
			CW.[CreditLimit] AS creditLimit,
			CW.[ByPassCreditTerm] AS byPassCreditTerm
		FROM #tmpResult CW
		
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'usp_validateCustomerCredit' 
        , @ProcedureParameters VARCHAR(3000) = '@CustomerRfqId = ''' + CAST(ISNULL(@CustomerId, '') as varchar(100))
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
                @DatabaseName           = @DatabaseName
                , @AdhocComments          = @AdhocComments
                , @ProcedureParameters = @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END