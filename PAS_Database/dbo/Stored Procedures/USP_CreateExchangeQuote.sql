/*************************************************************           
 ** File:   [USP_CreateExchangeQuote]             
 ** Author:  Ekta Chandegra 
 ** Description: This stored procedure is used to CreateExchangeQuote
 ** Purpose:           
 ** Date:  07/23/2025       
            
 ** PARAMETERS: @SalesOrderQuoteId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
    1     07/23/2025      Ekta Chandegra        Created  


exec [dbo].[USP_CreateExchangeQuote] @CustomerReference=N'',@OpenDate='2025-07-23 00:00:00',@QuoteExpireDate='2025-08-22 00:00:00',
@PriorityId=3,@StatusId=1,@StatusChangeDate='2025-07-23 16:50:33.567',@CustomerId=77,@SalesPersonId=5,@CreatedBy=N'roza diaz',
@MasterCompanyId=1,@ManagementStructureId=1,@EmployeeId=237,@ValidForDays=30,@CustomerServiceRepId=5,@Memo=N'',@Notes=N'',
@ContractReference=N'',@FunctionalCurrencyId=1,@ReportCurrencyId=1,@ForeignExchangeRate=1.000000
************************************************************************/

CREATE   PROCEDURE [dbo].[USP_CreateExchangeQuote]
	@CustomerReference VARCHAR(100),
    	@OpenDate DATETIME,
    	@QuoteExpireDate DATETIME,
	@PriorityId INT,
	@StatusId INT,
	@StatusChangeDate DATETIME,
	@CustomerId BIGINT,
	@SalesPersonId BIGINT,
    	@CreatedBy VARCHAR(256),
    	@MasterCompanyId INT,
    	@ManagementStructureId BIGINT,
	@EmployeeId BIGINT,
	@ValidForDays INT,
	@CustomerServiceRepId BIGINT,
	@Memo NVARCHAR(MAX),
	@Notes NVARCHAR(MAX),
	@ContractReference VARCHAR(100),
	@FunctionalCurrencyId INT,
	@ReportCurrencyId INT,
	@ForeignExchangeRate DECIMAL(18,2)
AS	
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

		DECLARE @ExchangeTypeId INT,@ExchangeType VARCHAR(50);
		DECLARE @ExchangeQuotePrefix INT; 
		DECLARE @CurrentNumber BIGINT;
		DECLARE @ExchangeQuoteId BIGINT;

		SELECT @ExchangeTypeId = [Id], @ExchangeType = [Name]
		FROM [dbo].[ExchangeType] WITH(NOLOCK) WHERE [Name] = 'Exchange';

		SELECT TOP 1 @ExchangeQuotePrefix = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'Exchange Quote';
		PRINT @ExchangeQuotePrefix;

		-- Fetch soqCodeData
		SELECT TOP 1 * INTO #esoqCodeData FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE ISNULL([IsActive],0) = 1 AND ISNULL([IsDeleted],0) = 0 AND [CodeTypeId] = @ExchangeQuotePrefix AND [MasterCompanyId] = @MasterCompanyId

		-- Determine the current number
		IF EXISTS (SELECT 1 FROM #esoqCodeData)
		BEGIN
		IF (SELECT CurrentNummber FROM #esoqCodeData) > 0
			BEGIN
				SET @CurrentNumber = (SELECT CurrentNummber FROM #esoqCodeData) + 1;
		END
		ELSE
			BEGIN
				SET @CurrentNumber = (SELECT StartsFrom FROM #esoqCodeData) + 1;
		END

		-- Update soCodeData with new current number
		UPDATE CodePrefixes
		SET CurrentNummber = @CurrentNumber
		WHERE CodePrefixId = (SELECT CodePrefixId FROM #esoqCodeData);

			-- Generate ExchangeQuoteNumber
			DECLARE @ExchangeQuoteNumber NVARCHAR(50);
			SET @ExchangeQuoteNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@CurrentNumber, (SELECT CodePrefix FROM #esoqCodeData), (SELECT CodeSufix FROM #esoqCodeData)));
			PRINT @ExchangeQuoteNumber;
		END
		ELSE
		BEGIN
			-- Generate SalesOrderNumber without prefix/suffix
				SET @ExchangeQuoteNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](0, '', ''));
				PRINT @ExchangeQuoteNumber;
		END

		IF @SalesPersonId = 0 
		BEGIN
			SET @SalesPersonId = NULL
		END

		IF @CustomerServiceRepId = 0 
		BEGIN
			SET @CustomerServiceRepId = NULL
		END

		DECLARE @Vesrion INT;
		-- Generate Version
		SET @Vesrion = 1

		DECLARE @VersionNumber VARCHAR(50);
		SET @VersionNumber = [dbo].[GenearteVersionNumber] (@Vesrion);
		PRINT @VersionNumber

		DECLARE @StatusName VARCHAR(50);
		SELECT @StatusName = [Name] FROM [dbo].[ExchangeStatus] WITH(NOLOCK) WHERE ExchangeStatusId = @StatusId;

		DECLARE @CustomerName VARCHAR(100), @CustomerCode VARCHAR(100), @CustomerContactEmail VARCHAR(200), @AccountTypeId INT, @RestrictPMA BIT, @RestrictDER BIT;
		SELECT TOP 1 @CustomerName = [Name], 
			   @CustomerCode = [CustomerCode],
			   @CustomerContactEmail = [Email],
			   @AccountTypeId = [CustomerTypeId],
			   @RestrictPMA = RestrictPMA,
			   @RestrictDER = RestrictDER
		FROM [dbo].[Customer] WITH(NOLOCK) WHERE CustomerId = @CustomerId;


		DECLARE @CustomerContactId BIGINT, @CustomerContactName VARCHAR(200)
		SELECT TOP 1 @CustomerContactId = CustomerContactId, 
		       @CustomerContactName = C.FirstName + ' '+ C.LastName + '-' + C.WorkPhone
		FROM [dbo].[CustomerContact] CC WITH(NOLOCK)
		LEFT JOIN [dbo].[Contact] C WITH(NOLOCK) ON C.ContactId = CC.ContactId
		WHERE CustomerId = @CustomerId AND IsDefaultContact = 1;
		PRINT @CustomerContactId
		PRINT @CustomerContactName

		DECLARE @CreditTermName VARCHAR(50),@CreditLimit DECIMAL(18,2) ,@CreditTermId INT, @BalanceDue NUMERIC(9,2);
		SELECT TOP 1 @CreditTermName = CT.[Name],
			   @CreditLimit = CF.[CreditLimit],
			   @CreditTermId = CT.[CreditTermsId],
			   @BalanceDue = CCTH.ARBalance
		FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK) 
		LEFT JOIN [dbo].[CustomerCreditTermsHistory] CCTH WITH(NOLOCK) ON CCTH.CustomerId = CF.CustomerId
		LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = CF.CreditTermsId
		WHERE CF.CustomerId = @CustomerId
		ORDER BY CCTH.UpdatedDate DESC;
		PRINT @CreditTermName
		PRINT @CreditTermId
		PRINT @BalanceDue
		PRINT @CreditLimit

		DECLARE @SalesPersonName VARCHAR(80);
		SELECT TOP 1 @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@SalesPersonId,0);
		PRINT @SalesPersonName

		DECLARE @CustomerServiceRepName VARCHAR(80);
		SELECT TOP 1 @CustomerServiceRepName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@CustomerServiceRepId,0);
		PRINT @CustomerServiceRepName

		DECLARE @EmployeeName VARCHAR(80);
		SELECT TOP 1 @EmployeeName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@EmployeeId,0);
		PRINT @EmployeeName

		DECLARE @ManagementStructureName VARCHAR(286);
		SELECT TOP 1 @ManagementStructureName  = Code + ' ' + Name FROM [dbo].[ManagementStructure] WITH(NOLOCK)
		WHERE ManagementStructureId = @ManagementStructureId;

		DECLARE @EnforceApproval BIT, @EnforceEffectiveDate DATETIME
		SELECT TOP 1 @EnforceApproval = IsApprovalRule,
			         @EnforceEffectiveDate = EffectiveDate
		FROM [dbo].[ExchangeQuoteSetting] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ISNULL(IsActive,0) = 1;

        -- Step 3: Insert into ExchangeQuote
        INSERT INTO ExchangeQuote
        (
            [Type]
		  ,[TypeName]
		  ,[ExchangeQuoteNumber]
		  ,[CustomerReference]
		  ,[OpenDate]
		  ,[QuoteExpireDate]
		  ,[Version]
		  ,[VersionNumber]
		  ,[VersionDate]
		  ,[PriorityId]
		  ,[StatusId]
		  ,[StatusName]
		  ,[StatusChangeDate]
		  ,[CustomerId]
		  ,[CustomerName]
		  ,[CustomerCode]
		  ,[CustomerContactId]
		  ,[CreditLimit]
		  ,[CreditTermId]
		  ,[CreditLimitName]
		  ,[CreditTermName]
		  ,[BalanceDue]
		  ,[SalesPersonId]
		  ,[SalesPersonName]
		  ,[ApprovedById]
		  ,[ApprovedByName]
		  ,[ApprovedDate]
		  ,[CreatedBy]
		  ,[CreatedDate]
		  ,[UpdatedBy]
		  ,[UpdatedDate]
		  ,[IsDeleted]
		  ,[IsActive]
		  ,[MasterCompanyId]
		  ,[ManagementStructureId]
		  ,[EmployeeId]
		  ,[IsApproved]
		  ,[CustomerContactName]
		  ,[CustomerContactEmail]
		  ,[ValidForDays]
		  ,[CustomerSeviceRepId]
		  ,[CustomerServiceRepName]
		  ,[CustomerWarningId]
		  ,[CustomerWarningName]
		  ,[EmployeeName]
		  ,[ManagementStructureName1]
		  ,[ManagementStructureName2]
		  ,[ManagementStructureName3]
		  ,[ManagementStructureName4]
		  ,[Memo]
		  ,[Notes]
		  ,[AgentId]
		  ,[AgentName]
		  ,[ManagementStructureName]
		  ,[AccountTypeId]
		  ,[RestrictPMA]
		  ,[RestrictDER]
		  ,[ContractReference]
		  ,[EnforceEffectiveDate]
		  ,[IsEnforceApproval]
		  ,[IsNewVersionCreated]
		  ,[QuoteParentId]
		  ,[IsFreightFlatRate]
		  ,[FreightFlatRate]
		  ,[IsChargeFlatRate]
		  ,[ChargeFlatRate]
		  ,[FunctionalCurrencyId]
		  ,[ReportCurrencyId]
		  ,[ForeignExchangeRate]
        )
        VALUES
        (
			@ExchangeTypeId,
			@ExchangeType,
			@ExchangeQuoteNumber,
			@CustomerReference,
			@OpenDate,
			@QuoteExpireDate,
			@Vesrion,
			@VersionNumber,
			NULL,
			@PriorityId,
			@StatusId,
			@StatusName,
			@StatusChangeDate,
			@CustomerId,
			@CustomerName,
			@CustomerCode,
			@CustomerContactId,
			@CreditLimit,
			@CreditTermId,
			NULL,
			@CreditTermName,
			@BalanceDue,
			@SalesPersonId,
			@SalesPersonName,
			0,
			NULL,
			NULL,
			@CreatedBy,
			GETUTCDATE(),
			@CreatedBy,
			GETUTCDATE(),
			0,
			1,
			@MasterCompanyId,
			@ManagementStructureId,
			@EmployeeId,
			0,
			@CustomerContactName,
			@CustomerContactEmail,
			@ValidForDays,
			@CustomerServiceRepId,
			@CustomerServiceRepName,
			NULL,
			NULL,
			@EmployeeName,
			NULL,
			NULL,
			NULL,
			NULL,
			@Memo,
			@Notes,
			NULL,
			NULL,
			@ManagementStructureName,
			@AccountTypeId,
			@RestrictPMA,
			@RestrictDER,
			@ContractReference,
			@EnforceEffectiveDate,
			@EnforceApproval,
			0,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			@FunctionalCurrencyId,
			@ReportCurrencyId,
			@ForeignExchangeRate
		);

        SET @ExchangeQuoteId = SCOPE_IDENTITY();

		DECLARE @ModuleID INT;
		DECLARE @ReferenceID BIGINT;
		DECLARE @MSDetailsId BIGINT;


		-- Fetch Sales Order Quote ManagementStructureModule Id
		SELECT @ModuleID = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'ExchangeQuoteHeader'

		SET @ReferenceID = @ExchangeQuoteId


        -- Step 5: Save MSDetails (assuming SaveMSDetails is a procedure)
        EXEC [dbo].[PROCAddExchangeMSData] @ReferenceId,@ManagementStructureId,@MasterCompanyId, @CreatedBy, @CreatedBy, @ModuleID, 1;

		SELECT @ExchangeQuoteId AS ExchangeQuoteId;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'CreateSalesOrderQuote'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CustomerReference, '') AS varchar(100) ) + ''',
													@Parameter2 = '''+ CAST(ISNULL(@OpenDate, '') AS varchar(100) ) + ''',
													@Parameter3 = '''+ CAST(ISNULL(@QuoteExpireDate, '') AS varchar(100) ) + ''',
													@Parameter4 = '''+ CAST(ISNULL(@PriorityId, '') AS varchar(100) ) + ''',
													@Parameter5 = '''+ CAST(ISNULL(@StatusId , '') AS varchar(100) ) + ''',
													@Parameter6 = '''+ CAST(ISNULL(@StatusChangeDate , '') AS varchar(100) ) + ''',
													@Parameter7 = '''+ CAST(ISNULL(@CustomerId, '') AS varchar(100) ) + ''',
													@Parameter8 = '''+ CAST(ISNULL(@SalesPersonId, '') AS varchar(100) ) + ''',
													@Parameter9 = '''+ CAST(ISNULL(@CreatedBy, '') AS varchar(100) ) + ''',
													@Parameter10 = '''+ CAST(ISNULL(@MasterCompanyId, '') AS varchar(100) ) + ''',
													@Parameter11 = '''+ CAST(ISNULL(@ManagementStructureId, '') AS varchar(100) ) + ''',
													@Parameter12 = '''+ CAST(ISNULL(@EmployeeId, '') AS varchar(100) ) + ''',
													@Parameter13 = '''+ CAST(ISNULL(@ValidForDays, '') AS varchar(100) ) + ''',
													@Parameter14 = '''+ CAST(ISNULL(@CustomerServiceRepId, '') AS varchar(100) ) + ''',
													@Parameter15 = '''+ CAST(ISNULL(@Memo , '') AS varchar(100) ) + ''',
													@Parameter16 = '''+ CAST(ISNULL(@Notes, '') AS varchar(100) ) + ''',
													@Parameter17 = '''+ CAST(ISNULL(@ContractReference, '') AS varchar(100) ) + ''',
													@Parameter18 = '''+ CAST(ISNULL(@FunctionalCurrencyId, '') AS varchar(100) ) + ''',
													@Parameter19 = '''+ CAST(ISNULL(@ReportCurrencyId, '') AS varchar(100) ) + ''',
													@Parameter20 = '''+ CAST(ISNULL(@ForeignExchangeRate , '') AS varchar(100) ) + ''

			,@ApplicationName VARCHAR(100) = 'PAS'    
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
END;
