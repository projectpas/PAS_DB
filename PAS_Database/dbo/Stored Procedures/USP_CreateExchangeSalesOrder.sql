/*************************************************************           
 ** File:   [USP_CreateExchangeSalesOrder]             
 ** Author:  Ekta Chandegra 
 ** Description: This stored procedure is used to CreateExchangeSalesOrder
 ** Purpose:           
 ** Date:  08/04/2025       
            
 ** PARAMETERS: @TypeId INT, @OpenDate DATETIME, @CustomerId BIGINT, @CustomerReference VARCHAR(100),
				@SalesPersonId BIGINT,@CustomerSeviceRepId BIGINT,@EmployeeId BIGINT,@Memo NVARCHAR(MAX),
				@StatusId INT,@StatusChangeDate DATETIME,@Notes NVARCHAR(MAX),@ManagementStructureId BIGINT,
				@CreatedBy varchar(256),@MasterCompanyId INT,@ContractReference VARCHAR(100),@FunctionalCurrencyId INT,
				@ReportCurrencyId INT,@ForeignExchangeRate DECIMAL(18, 2)
           
 ***************************************************************************************         
 ** Change History             
 ***************************************************************************************
 
 ** PR     Date              Author              Change Description              
 ** --    --------         -------              --------------------------------            
    1     08/04/2025      Ekta Chandegra        Created  

exec [dbo].[USP_CreateExchangeSalesOrder] @TypeId=1,@OpenDate='2025-08-04 00:00:00',@CustomerId=44,
@CustomerReference=N'test',@SalesPersonId=0,@CustomerSeviceRepId=0,@EmployeeId=237,@Memo=N'',@StatusId=1,
@StatusChangeDate='2025-08-04 14:06:11.010',@Notes=N'',@ManagementStructureId=1,@CreatedBy=N'roza diaz',
@MasterCompanyId=1,@ContractReference=N'',@PercentId=0,@Days=0,@NetDays=0,@FunctionalCurrencyId=1,
@ReportCurrencyId=1,@ForeignExchangeRate=1.000000
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateExchangeSalesOrder]
@TypeId INT,
@OpenDate DATETIME,
@CustomerId BIGINT,
@CustomerReference VARCHAR(100),
@SalesPersonId BIGINT,
@CustomerSeviceRepId BIGINT,
@EmployeeId BIGINT,
@Memo NVARCHAR(MAX),
@StatusId INT,
@StatusChangeDate DATETIME,
@Notes NVARCHAR(MAX),
@ManagementStructureId BIGINT,
@CreatedBy varchar(256),
@MasterCompanyId INT,
@ContractReference VARCHAR(100),
@FunctionalCurrencyId INT,
@ReportCurrencyId INT,
@ForeignExchangeRate DECIMAL(18, 2)
AS
BEGIN 
	SET NOCOUNT ON;
	BEGIN TRY
        BEGIN TRANSACTION;
			DECLARE @Version INT;
			DECLARE @ExchangeSalesOrderId BIGINT;
	
			SET @Version = 1;

			IF @SalesPersonId = 0 
			BEGIN
				SET @SalesPersonId = NULL
			END

			IF @CustomerSeviceRepId = 0 
			BEGIN
				SET @CustomerSeviceRepId = NULL
			END


			DECLARE @VersionNumber VARCHAR(50);
			SET @VersionNumber = [dbo].[GenearteVersionNumber] (@Version);

			DECLARE @ExchangeSalesOrderPrefix INT, @CurrentNumber BIGINT; 

			SELECT TOP 1 @ExchangeSalesOrderPrefix = CodeTypeId FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'ExchangeSalesOrder';
			PRINT @ExchangeSalesOrderPrefix;

			-- Fetch esoCodeData
			SELECT TOP 1 * INTO #esoCodeData FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @ExchangeSalesOrderPrefix AND [MasterCompanyId] = @MasterCompanyId

			-- Determine the current number
			IF EXISTS (SELECT 1 FROM #esoCodeData)
			BEGIN
			IF (SELECT CurrentNummber FROM #esoCodeData) > 0
				BEGIN
					SET @CurrentNumber = (SELECT CurrentNummber FROM #esoCodeData) + 1;
			END
			ELSE
				BEGIN
					SET @CurrentNumber = (SELECT StartsFrom FROM #esoCodeData) + 1;
			END

			-- Update soCodeData with new current number
			UPDATE CodePrefixes
			SET CurrentNummber = @CurrentNumber
			WHERE CodePrefixId = (SELECT CodePrefixId FROM #esoCodeData);

				-- Generate ExchangeSalesOrderNumber
				DECLARE @ExchangeSalesOrderNumber NVARCHAR(50);
				SET @ExchangeSalesOrderNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumber](@CurrentNumber, (SELECT CodePrefix FROM #esoCodeData), (SELECT CodeSufix FROM #esoCodeData)));
				PRINT @ExchangeSalesOrderNumber;
			END
			ELSE
			BEGIN
				-- Generate ExchangeSalesOrderNumber without prefix/suffix
					SET @ExchangeSalesOrderNumber = (SELECT * FROM [dbo].[udfGenerateCodeNumberWithOutDash](0, '', ''));
					PRINT @ExchangeSalesOrderNumber;
			END

			DECLARE @AccountTypeId INT,@RestrictPMA BIT, @RestrictDER BIT, @CustomerName varchar(100), @CustomerCode varchar(100), @AccountTypeName varchar(256);
			SELECT @AccountTypeId = C.[CustomerTypeId],
			@RestrictPMA = C.[RestrictPMA],
			@RestrictDER = C.[RestrictDER],
			@CustomerName = C.[Name],
			@CustomerCode = C.[CustomerCode],
			@AccountTypeName = CT.[CustomerTypeName]
			FROM [dbo].[Customer] C WITH(NOLOCK) 
			LEFT JOIN [dbo].[CustomerType] CT WITH(NOLOCK) ON CT.CustomerTypeId = C.CustomerTypeId
			WHERE CustomerId = @CustomerId;
			PRINT @AccountTypeId;			
			PRINT @RestrictPMA;			
			PRINT @RestrictDER;			
			PRINT @CustomerName;			
			PRINT @CustomerCode;			
			PRINT @AccountTypeName;

			DECLARE @CustomerContactId BIGINT;
			SELECT TOP 1 @CustomerContactId = CustomerContactId FROM [dbo].[CustomerContact] WITH(NOLOCK) 
			WHERE CustomerId = @CustomerId AND IsDefaultContact = 1;

			DECLARE @TypeName varchar(50);
			SELECT TOP 1 @TypeName = [Name]
			FROM [dbo].[ExchangeType] WITH(NOLOCK) WHERE [Id] = @TypeId; 

			DECLARE @SalesPersonName VARCHAR(80);
			SELECT TOP 1 @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@SalesPersonId,0);

			DECLARE @CustomerServiceRepName VARCHAR(80);
			SELECT TOP 1 @CustomerServiceRepName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@CustomerSeviceRepId,0);

			DECLARE @EmployeeName VARCHAR(80);
			SELECT TOP 1 @EmployeeName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE EmployeeId = ISNULL(@EmployeeId,0);

			DECLARE @ManagementStructureName VARCHAR(286);
			SELECT TOP 1 @ManagementStructureName  = Code + ' ' + Name FROM [dbo].[ManagementStructure] WITH(NOLOCK)
			WHERE ManagementStructureId = @ManagementStructureId;

			DECLARE @CreditLimit DECIMAL(18, 2),@CreditTermId INT, @CreditTermName VARCHAR(50),@BalanceDue DECIMAL(18, 2),@PercentId BIGINT,@Days INT,@NetDays INT;
			SELECT TOP 1  @CreditLimit = CF.[CreditLimit],
				@CreditTermId = CT.[CreditTermsId],
				@BalanceDue = CCTH.ARBalance,
				@CreditTermName = CT.[Name],
				@PercentId = CT.[PercentId],
				@Days = CT.[Days],
				@NetDays = CT.[NetDays]
			FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK)
			LEFT JOIN [dbo].[CustomerCreditTermsHistory] CCTH WITH(NOLOCK) ON CCTH.CustomerId = CF.CustomerId
			LEFT JOIN [dbo].[CreditTerms] CT WITH(NOLOCK) ON CT.CreditTermsId = CF.CreditTermsId
			WHERE CF.CustomerId = @CustomerId
			ORDER BY CCTH.UpdatedDate DESC;

		INSERT INTO [dbo].[ExchangeSalesOrder]
		(
			   [Version]
			  ,[TypeId]
			  ,[OpenDate]
			  ,[ShippedDate]
			  ,[NumberOfItems]
			  ,[AccountTypeId]
			  ,[CustomerId]
			  ,[CustomerContactId]
			  ,[CustomerReference]
			  ,[CurrencyId]
			  ,[TotalSalesAmount]
			  ,[CustomerHold]
			  ,[DepositAmount]
			  ,[BalanceDue]
			  ,[SalesPersonId]
			  ,[AgentId]
			  ,[CustomerSeviceRepId]
			  ,[EmployeeId]
			  ,[ApprovedById]
			  ,[ApprovedDate]
			  ,[Memo]
			  ,[StatusId]
			  ,[StatusChangeDate]
			  ,[Notes]
			  ,[RestrictPMA]
			  ,[RestrictDER]
			  ,[ManagementStructureId]
			  ,[CustomerWarningId]
			  ,[CreatedBy]
			  ,[CreatedDate]
			  ,[UpdatedBy]
			  ,[UpdatedDate]
			  ,[MasterCompanyId]
			  ,[IsDeleted]
			  ,[ExchangeQuoteId]
			  ,[QtyRequested]
			  ,[QtyToBeQuoted]
			  ,[ExchangeSalesOrderNumber]
			  ,[IsActive]
			  ,[ContractReference]
			  ,[TypeName]
			  ,[AccountTypeName]
			  ,[CustomerName]
			  ,[CustomerCode]
			  ,[SalesPersonName]
			  ,[CustomerServiceRepName]
			  ,[EmployeeName]
			  ,[CurrencyName]
			  ,[CustomerWarningName]
			  ,[ManagementStructureName]
			  ,[CreditLimit]
			  ,[CreditTermId]
			  ,[CreditLimitName]
			  ,[CreditTermName]
			  ,[VersionNumber]
			  ,[ExchangeQuoteNumber]
			  ,[IsApproved]
			  ,[CoreAccepted]
			  ,[IsVendor]
			  ,[IsFreightFlatRate]
			  ,[FreightFlatRate]
			  ,[IsChargeFlatRate]
			  ,[ChargeFlatRate]
			  ,[IsFreightFlatRateInsert]
			  ,[IsChargeFlatRateInsert]
			  ,[PercentId]
			  ,[Days]
			  ,[NetDays]
			  ,[FunctionalCurrencyId]
			  ,[ReportCurrencyId]
			  ,[ForeignExchangeRate]
		)
		VALUES
		(
			 @Version
			,@TypeId
			,@OpenDate
			,NULL
			,0
			,@AccountTypeId
			,@CustomerId
			,@CustomerContactId
			,@CustomerReference
			,NULL
			,0
			,0
			,0
			,@BalanceDue
			,@SalesPersonId
			,NULL
			,@CustomerSeviceRepId
			,@EmployeeId
			,NULL
			,NULL
			,@Memo
			,@StatusId
			,@StatusChangeDate
			,@Notes
			,@RestrictPMA
			,@RestrictDER
			,@ManagementStructureId
			,NULL
			,@CreatedBy
			,GETUTCDATE()
			,@CreatedBy
			,GETUTCDATE()
			,@MasterCompanyId
			,0
			,NULL
			,0	
			,0
			,@ExchangeSalesOrderNumber
			,1
			,@ContractReference
			,@TypeName
			,@AccountTypeName
			,@CustomerName
			,@CustomerCode
			,@SalesPersonName
			,@CustomerServiceRepName
			,@EmployeeName
			,NULL
			,NULL
			,@ManagementStructureName
			,@CreditLimit
			,@CreditTermId
			,NULL
			,@CreditTermName
			,@VersionNumber
			,NULL
			,0
			,0
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,NULL
			,@PercentId
			,@Days
			,@NetDays
			,@FunctionalCurrencyId
			,@ReportCurrencyId
			,@ForeignExchangeRate
		);

		SET @ExchangeSalesOrderId = SCOPE_IDENTITY();

		DECLARE @ModuleID INT;
		DECLARE @ReferenceID BIGINT;

		SELECT @ModuleID = ManagementStructureModuleId FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE ModuleName = 'ExchangeSOHeader'
		PRINT @ModuleID;

		SET @ReferenceID = @ExchangeSalesOrderId;

        EXEC [dbo].[PROCAddExchangeMSData] @ReferenceId,@ManagementStructureId,@MasterCompanyId, @CreatedBy, @CreatedBy, @ModuleID, 1;

		SELECT @ExchangeSalesOrderId AS ExchangeSalesOrderId;

	COMMIT TRANSACTION	
	END TRY
    BEGIN CATCH
	 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'USP_CreateExchangeSalesOrder'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@TypeId, '') AS varchar(100) ) + ''',

													@Parameter2 = '''+ CAST(ISNULL(@OpenDate, '') AS varchar(100) ) + ''',
													@Parameter3 = '''+ CAST(ISNULL(@CustomerId, '') AS varchar(100) ) + ''',
													@Parameter4 = '''+ CAST(ISNULL(@CustomerReference , '') AS varchar(100) ) + ''',
													@Parameter5 = '''+ CAST(ISNULL(@SalesPersonId, '') AS varchar(100) ) + ''',
													@Parameter6 = '''+ CAST(ISNULL(@CustomerSeviceRepId, '') AS varchar(100) ) + ''',
													@Parameter7 = '''+ CAST(ISNULL(@EmployeeId, '') AS varchar(100) ) + ''',
													@Parameter8 = '''+ CAST(ISNULL(@Memo, '') AS varchar(100) ) + ''',
													@Parameter9 = '''+ CAST(ISNULL(@StatusId, '') AS varchar(100) ) + ''',
													@Parameter10 = '''+ CAST(ISNULL(@StatusChangeDate, '') AS varchar(100) ) + ''',
													@Parameter11 = '''+ CAST(ISNULL(@Notes, '') AS varchar(100) ) + ''',
													@Parameter12 = '''+ CAST(ISNULL(@ManagementStructureId, '') AS varchar(100) ) + ''',
													@Parameter13 = '''+ CAST(ISNULL(@CreatedBy , '') AS varchar(100) ) + ''',
													@Parameter14 = '''+ CAST(ISNULL(@MasterCompanyId, '') AS varchar(100) ) + ''',
													@Parameter15 = '''+ CAST(ISNULL(@ContractReference, '') AS varchar(100) ) + ''',
													@Parameter16 = '''+ CAST(ISNULL(@FunctionalCurrencyId, '') AS varchar(100) ) + ''',
													@Parameter17 = '''+ CAST(ISNULL(@ReportCurrencyId, '') AS varchar(100) ) + ''',
													@Parameter18 = '''+ CAST(ISNULL(@ForeignExchangeRate , '') AS varchar(100) ) + ''



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
END