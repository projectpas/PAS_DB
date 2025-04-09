/*****************************************************************************           
 ** File:   [USP_GetCustomerEmailContentNew]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to GET Customer Email Content Data
 ** Purpose:         
 ** Date:   08/04/2025      
 ** RETURN VALUE:           
 ******************************************************************************           
 ** Change History           
 ******************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/04/2025   Moin Bloch    Created
     
--   EXEC [dbo].[USP_GetCustomerEmailContentNew] '',6640,8301
********************************************************************************/
CREATE  PROCEDURE [dbo].[USP_GetCustomerEmailContentNew]
@emailContent NVARCHAR(MAX) = NULL,
@workorderQuoteId BIGINT = NULL,
@workOrderPartNoId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
	DECLARE @CustomerId BIGINT = 0 
	DECLARE @TaxRate DECIMAL(18,2) = 0
	DECLARE @SalesTax DECIMAL(18,2) = 0,@OtherTax DECIMAL(18,2) = 0
	
	DECLARE @WOQuote INT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WOQuote');

	IF OBJECT_ID(N'tempdb..#CustomerTaxAndRateType') IS NOT NULL
	BEGIN
		DROP TABLE #CustomerTaxAndRateType
	END

	CREATE TABLE #CustomerTaxAndRateType
	(	
		[ID] [BIGINT] NOT NULL IDENTITY, 
	    [TaxRate] [NUMERIC](18,2) NULL,
		[Code] [VARCHAR](100) NULL
	)

	SELECT @CustomerId = WOQ.[CustomerId], 
	       @TaxRate = ISNULL([TaxRate],0)
	FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
	LEFT JOIN [dbo].[CustomerTaxTypeRateMapping] TAX WITH(NOLOCK) ON WOQ.[CustomerId] = TAX.[CustomerId]
	WHERE WOQ.[IsDeleted] = 0 AND WOQ.[WorkOrderQuoteId] = @workorderQuoteId;

	SELECT DISTINCT TOP 1		
		WOQ.[QuoteNumber],		
		CONVERT(VARCHAR(10), WOQ.[OpenDate], 101) [OpenDate],
		CASE WHEN WOQ.[ExpirationDate] IS NULL THEN '' ELSE CONVERT(VARCHAR(10), WOQ.[ExpirationDate], 101) END [ExpirationDate],
		WO.[WorkOrderNum],
		CUST.[Name] [CustomerName],
		CUST.[CustomerId],
		CUST.[CustomerCode],
		ISNULL(CON.[FirstName] + ' ' + CON.[LastName], '') [CustomerContact],		
		ISNULL(CON.[WorkPhone], '') [Phone],
		ISNULL(CON.[Email], '') [Email],
		ISNULL(ADR.[Line1], '') [Address1],
		ISNULL(ADR.[Line2], '')  [Address2],
		ISNULL(ADR.[City], '')  [City],
		ISNULL(ADR.[StateOrProvince], '') [State],
		ISNULL(ADR.[PostalCode], '') [Zip],
		ISNULL(CO.[countries_name], '') [Country],
		ISNULL(CS.[ShipVia], '') [ShipVia],		
		ISNULL(CT.[Name], '')  [CreditTerms],
		ISNULL(SP.[FirstName] + ' ' + SP.[LastName], '') [SalesPerson],		
		WOQ.[VersionNo],
		WOQ.[CreatedBy],		
		CUR.[Code]  [Currency],		
		ISNULL(NULLIF(CUSTTAX.[TaxRate], ''), '0') [TaxRate],
		SA.[Attention]  [CustomerAttention],
		WOQ.[Notes]  [WONotes],
		wop.[CustomerReference] [WOCustomerRef],
		@TaxRate AS TaxRate
	FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
	INNER JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOQ.WorkOrderId = WO.WorkOrderId
	INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOQ.[WorkOrderId] = WOP.[WorkOrderId]
	INNER JOIN [dbo].[Customer] CUST WITH(NOLOCK) ON WOQ.[CustomerId] = CUST.[CustomerId]
	 LEFT JOIN [dbo].[CustomerFinancial] CF WITH(NOLOCK) ON CUST.[CustomerId] = CF.[CustomerId]
	INNER JOIN [dbo].[Currency] CUR WITH(NOLOCK) ON WOQ.[CurrencyId] = CUR.[CurrencyId]
	 LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CF.[CreditTermsId] = CT.[CreditTermsId]
	 LEFT JOIN [dbo].[Employee] SP WITH(NOLOCK) ON WO.[SalesPersonId] = SP.[EmployeeId]
	 LEFT JOIN [dbo].[CustomerContact] CC WITH(NOLOCK) ON WO.[CustomerContactId] = CC.[CustomerContactId]
	 LEFT JOIN [dbo].[Contact] CON WITH(NOLOCK) ON CC.[ContactId] = CON.[ContactId]
	 LEFT JOIN [dbo].[Address] ADR WITH(NOLOCK) ON CUST.[AddressId] = ADR.[AddressId]
	 LEFT JOIN [dbo].[Countries] CO WITH(NOLOCK) ON ADR.[CountryId] = CO.[countries_id]
	 LEFT JOIN [dbo].[CustomerDomensticShipping] SA WITH(NOLOCK)  ON CUST.[CustomerId] = SA.[CustomerId] AND SA.[IsPrimary] = 1
	 LEFT JOIN [dbo].[CustomerDomensticShippingShipVia] CS WITH(NOLOCK) ON CUST.[CustomerId] = CS.[CustomerId] AND CS.[IsPrimary] = 1	 
	 LEFT JOIN [dbo].[CustomerTaxTypeRateMapping] CUSTTAX WITH(NOLOCK) ON CUST.[CustomerId] = CUSTTAX.[CustomerId]
	WHERE WOQ.[IsDeleted] = 0 AND WOQ.[WorkOrderQuoteId] = @workorderQuoteId;

	SELECT DISTINCT TOP 1
		woq.[WorkOrderQuoteId],
		woq.[CustomerStatusId],
		ISNULL(ca.[Name], '') [custapproval],
		ISNULL(css.[Name], '') [custrejected],
		woq.[ApprovalActionId] [QuoteStatusId]
	FROM [dbo].[WorkOrderApproval] woq WITH(NOLOCK)
	LEFT JOIN [dbo].[CustomerContact] ccon WITH(NOLOCK) ON woq.[CustomerApprovedById] = ccon.[ContactId]
	LEFT JOIN [dbo].[Customer] ca WITH(NOLOCK) ON ccon.[CustomerId] = ca.[CustomerId]
	LEFT JOIN [dbo].[Customer] css WITH(NOLOCK) ON ccon.[CustomerId] = css.[CustomerId]
	WHERE woq.[IsDeleted] = 0 AND woq.[WorkOrderPartNoId] = @workOrderPartNoId;
	
	INSERT INTO #CustomerTaxAndRateType([TaxRate],[Code])
	SELECT tr.[TaxRate],
		    t.[Code]
	FROM [dbo].[CustomerTaxTypeRateMapping] ctt WITH(NOLOCK)
	JOIN [dbo].[TaxType] t WITH(NOLOCK) ON ctt.[TaxTypeId] = t.[TaxTypeId]
	JOIN [dbo].[TaxRate] tr WITH(NOLOCK) ON ctt.[TaxRateId] = tr.[TaxRateId]
	WHERE ctt.[CustomerId] = @CustomerId AND ctt.[IsActive] = 1 AND ctt.[IsDeleted] = 0;
	   	 
	SELECT @TotalRecord = COUNT(*), @MinId = MIN([ID]) FROM #CustomerTaxAndRateType 

	WHILE @MinId <= @TotalRecord
	BEGIN		
		DECLARE @TaxRates NUMERIC(18,2) = 0,@Code VARCHAR(100) = NULL

		SELECT @TaxRates = ISNULL([TaxRate],0),
		       @Code = [Code] 
		FROM #CustomerTaxAndRateType WHERE [ID] = @MinId

		IF(@Code IS NULL OR @Code = '')
		BEGIN
			SET @OtherTax += @TaxRates;
		END
		ELSE IF(@Code = 'SALES TAX')
		BEGIN
			SET @SalesTax += @TaxRates;
		END

		SET @MinId = @MinId + 1
	END

	SELECT @SalesTax [SalesTax],@OtherTax [OtherTax]		 


	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCustomerEmailContentNew' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@emailContent, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@workorderQuoteId, '') AS VARCHAR(100)) +
													 '@Parameter3 = ''' + CAST(ISNULL(@workOrderPartNoId, '') AS VARCHAR(100)) 
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