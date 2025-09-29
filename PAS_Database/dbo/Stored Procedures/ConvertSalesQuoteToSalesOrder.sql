/*************************************************************           
 ** File:   [ConvertSalesQuoteToSalesOrder]          
 ** Author: EKTA CHANDEGRA
 ** Description: This stored procedure is used to ConvertSalesQuoteToSalesOrder
 ** Purpose:         
 ** Date:    09/24/2025  
 ** PARAMETERS: @ExchangeQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** -----------------------------------------------------------          
    1   09/24/2025   EKTA CHANDEGRA    Created
	     
exec [dbo].[ConvertSalesQuoteToSalesOrder] @TypeId=1,@AccountTypeId=1,@CustomerId=43,@CustomerName=N'POWER AERO',
@CustomerCode=N'C-000008',@CustomerContactId=52,@CustomerReference=N'',@CurrencyId=0,@SalesPersonId=5,@AgentId=0,
@CustomerSeviceRepId=4,@EmployeeId=237,@Memo=N'',@Notes=N'',@RestrictPMA=1,@RestrictDER=1,@ManagementStructureId=1,
@CustomerWarningId=0,@CreatedBy=N'roza diaz',@MasterCompanyId=1,@SalesOrderQuoteId=0,@TotalFreight=0,@TotalCharges=0,
@FreightBilingMethodId=0,@ChargesBilingMethodId=0,@EntityStructureId=0,@TransferMemos=0,@TransferNotes=0,
@StatusId=4

************************************************************************/ 
CREATE   PROCEDURE [dbo].[ConvertSalesQuoteToSalesOrder]
	@TypeId INT,
	@AccountTypeId INT,
    @CustomerId BIGINT,
    @CustomerName NVARCHAR(200),
    @CustomerCode NVARCHAR(100),
    @CustomerContactId BIGINT,
    @CustomerReference NVARCHAR(200),
    @CurrencyId INT,
    @SalesPersonId BIGINT,
    @AgentId BIGINT ,
    @CustomerSeviceRepId BIGINT,
    @EmployeeId BIGINT,
    @Memo NVARCHAR(MAX),
    @Notes NVARCHAR(MAX),
    @RestrictPMA BIT,
    @RestrictDER BIT,
    @ManagementStructureId BIGINT,
    @CustomerWarningId BIGINT,
    @CreatedBy NVARCHAR(100),
    @MasterCompanyId INT,
    @SalesOrderQuoteId BIGINT,
    @TotalFreight DECIMAL(18,2),
    @TotalCharges DECIMAL(18,2),
    @FreightBilingMethodId INT,
    @ChargesBilingMethodId INT,
    @EntityStructureId BIGINT,
    @TransferMemos BIT,
    @TransferNotes BIT,
	@StatusId INT
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		DECLARE 
			@CreditLimit DECIMAL(18, 2),
			@CreditTermId INT,
			@CreditTermName NVARCHAR(100)

		-- Get Customer Financial data
		SELECT TOP 1
			@CreditLimit = ISNULL(CF.CreditLimit, 0),
			@CreditTermId = ISNULL(CF.CreditTermsId, 0)
		FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK)
		WHERE CF.CustomerId = @CustomerId;

		-- Get Credit Term name
		SELECT TOP 1
			@CreditTermName = CT.Name
		FROM [dbo].[CreditTerms] CT WITH(NOLOCK)
		WHERE CT.CreditTermsId = @CreditTermId;

		-- Return the sales order view result
		SELECT
			NULL AS SalesOrderId,
			1 AS Version,
			@TypeId AS TypeId,
			CAST(GETUTCDATE() AS DATE) AS OpenDate,
			@AccountTypeId AS AccountTypeId,
			@CustomerId AS CustomerId,
			@CustomerName AS CustomerName,
			@CustomerCode AS CustomerCode,
			@CustomerContactId AS CustomerContactId,
			ISNULL(@CustomerReference, '') AS CustomerReference,
			@CurrencyId AS CurrencyId,
			0 AS TotalSalesAmount,
			0 AS CustomerHold,
			0 AS DepositAmount,
			0 AS BalanceDue,
			NULLIF(@SalesPersonId, 0) AS SalesPersonId,
			@AgentId AS AgentId,
			NULLIF(@CustomerSeviceRepId, 0) AS CustomerSeviceRepId,
			NULLIF(@EmployeeId, 0) AS EmployeeId,
			CASE WHEN @TransferMemos = 1 THEN @Memo ELSE '' END AS Memo,
			CASE WHEN @TransferNotes = 1 THEN @Notes ELSE '' END AS Notes,
			@RestrictPMA AS RestrictPMA,
			@RestrictDER AS RestrictDER,
			@ManagementStructureId AS ManagementStructureId,
			@CustomerWarningId AS CustomerWarningId,
			ISNULL(@CreatedBy, 'admin') AS CreatedBy,
			ISNULL(@CreatedBy, 'admin') AS UpdatedBy,
			GETUTCDATE() AS CreatedDate,
			GETUTCDATE() AS UpdatedDate,
			@MasterCompanyId AS MasterCompanyId,
			@SalesOrderQuoteId AS SalesOrderQuoteId,
			@StatusId AS StatusId, 
			@TotalFreight AS TotalFreight,
			@TotalCharges AS TotalCharges,
			@FreightBilingMethodId AS FreightBilingMethodId,
			@ChargesBilingMethodId AS ChargesBilingMethodId,
			@EntityStructureId AS EntityStructureId,
			@CreditLimit AS CreditLimit,
			@CreditTermId AS CreditTermId,
			@CreditTermName AS CreditTermName
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'ConvertSalesQuoteToSalesOrder'   
			, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@TypeId, '') AS varchar(100) ) + ''',
													 @Parameter2 = '''+ CAST(ISNULL(@AccountTypeId, '') AS varchar(100) ) + ''',
													 @Parameter3 = '''+ CAST(ISNULL(@CustomerId, '') AS varchar(100) ) + ''',
													 @Parameter4 = '''+ CAST(ISNULL(@CustomerName, '') AS varchar(100) ) + ''',
													 @Parameter5 = '''+ CAST(ISNULL(@CustomerCode, '') AS varchar(100) ) + ''',
													 @Parameter6 = '''+ CAST(ISNULL(@CustomerContactId, '') AS varchar(100) ) + ''',
													 @Parameter7 = '''+ CAST(ISNULL(@CustomerReference, '') AS varchar(100) ) + ''',
													 @Parameter8 = '''+ CAST(ISNULL(@CurrencyId, '') AS varchar(100) ) + ''',
													 @Parameter9 = '''+ CAST(ISNULL(@SalesPersonId, '') AS varchar(100) ) + ''',
													 @Parameter10 = '''+ CAST(ISNULL(@AgentId, '') AS varchar(100) ) + ''',
													 @Parameter11 = '''+ CAST(ISNULL(@CustomerSeviceRepId, '') AS varchar(100) ) + ''',
													 @Parameter12 = '''+ CAST(ISNULL(@EmployeeId, '') AS varchar(100) ) + ''',
													 @Parameter13 = '''+ CAST(ISNULL(@Memo, '') AS varchar(100) ) + ''',
													 @Parameter14 = '''+ CAST(ISNULL(@Notes, '') AS varchar(100) ) + ''',
													 @Parameter15 = '''+ CAST(ISNULL(@RestrictPMA, '') AS varchar(100) ) + ''',
													 @Parameter16 = '''+ CAST(ISNULL(@RestrictDER, '') AS varchar(100) ) + ''',
													 @Parameter17 = '''+ CAST(ISNULL(@ManagementStructureId, '') AS varchar(100) ) + ''',
													 @Parameter18 = '''+ CAST(ISNULL(@CustomerWarningId, '') AS varchar(100) ) + ''',
													 @Parameter19 = '''+ CAST(ISNULL(@CreatedBy, '') AS varchar(100) ) + ''',
													 @Parameter20 = '''+ CAST(ISNULL(@MasterCompanyId, '') AS varchar(100) ) + ''',
													 @Parameter21 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') AS varchar(100) ) + ''',
													 @Parameter22 = '''+ CAST(ISNULL(@TotalFreight, '') AS varchar(100) ) + ''',
													 @Parameter23 = '''+ CAST(ISNULL(@TotalCharges, '') AS varchar(100) ) + ''',
													 @Parameter24 = '''+ CAST(ISNULL(@FreightBilingMethodId , '') AS varchar(100) ) + ''',
													 @Parameter25 = '''+ CAST(ISNULL(@ChargesBilingMethodId , '') AS varchar(100) ) + ''',
													 @Parameter26 = '''+ CAST(ISNULL(@EntityStructureId , '') AS varchar(100) ) + ''',
													 @Parameter27 = '''+ CAST(ISNULL(@TransferMemos , '') AS varchar(100) ) + ''',
													 @Parameter28 = '''+ CAST(ISNULL(@TransferMemos , '') AS varchar(100) ) + ''
			,@ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------    
            exec spLogException     
                      @DatabaseName        = @DatabaseName    
                    , @AdhocComments       = @AdhocComments    
                    , @ProcedureParameters = @ProcedureParameters    
                    , @ApplicationName     =  @ApplicationName    
                    , @ErrorLogID          = @ErrorLogID OUTPUT ;    
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
            RETURN(1);
	END CATCH
END