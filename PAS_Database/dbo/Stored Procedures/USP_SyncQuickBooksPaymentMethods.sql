/*************************************************************
 ** File:   [USP_SyncQuickBooksPaymentMethods]
 ** Author: Devendra Shekh
 ** Description: This stored procedure is used to sync QuickBooks Payment Methods to DB
 ** Date:   06-March-2025
 **************************************************************
  ** Change History               
 **************************************************************
 ** PR   Date					Author				Change Description
 ** --   --------				-------			--------------------------------
    1    06-March-2025		Devendra Shekh			Created

declare @p1 dbo.QuickBooksPaymentMethodType
insert into @p1 values(N'6',N'0','2024-04-14 03:12:05',N'American Express',1,N'CREDIT_CARD')
insert into @p1 values(N'1',N'0','2024-04-14 03:12:05',N'Cash',1,N'NON_CREDIT_CARD')
insert into @p1 values(N'2',N'0','2024-04-14 03:12:05',N'Check',1,N'NON_CREDIT_CARD')
insert into @p1 values(N'7',N'0','2024-04-14 03:12:05',N'Diners Club',1,N'CREDIT_CARD')
insert into @p1 values(N'5',N'0','2024-04-14 03:12:05',N'Discover',1,N'CREDIT_CARD')
insert into @p1 values(N'4',N'0','2024-04-14 03:12:05',N'MasterCard',1,N'CREDIT_CARD')
insert into @p1 values(N'3',N'0','2024-04-14 03:12:05',N'Visa',1,N'CREDIT_CARD')
insert into @p1 values(N'8',N'0','2025-02-26 20:20:36',N'Wire Transfer',1,N'NON_CREDIT_CARD')

exec dbo.USP_SyncQuickBooksPaymentMethods @tbl_QuickBooksPaymentMethodType=@p1,@MasterCompanyId=1,@SyncPaymentMethods=0
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_SyncQuickBooksPaymentMethods]
    @tbl_QuickBooksPaymentMethodType QuickBooksPaymentMethodType READONLY,
	@MasterCompanyId INT = NULL,
	@SyncPaymentMethods BIT = NULL
AS
BEGIN

	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @TotalRecord INT, @CurrentRecordId INT;
		DECLARE @QBId VARCHAR(MAX), @QBSyncToken VARCHAR(MAX), @QBLastUpdatedTime DATETIME2, @QBName VARCHAR(MAX), @QBActive BIT;

		IF OBJECT_ID('tempdb..#TempQuickBooksPaymentMethodType') IS NOT NULL
			DROP TABLE #TempQuickBooksPaymentMethodType

		CREATE TABLE #TempQuickBooksPaymentMethodType
		(
			[TempId] INT IDENTITY(1,1) PRIMARY KEY,
			[Id] VARCHAR(MAX) NULL,
			[SyncToken] VARCHAR(MAX) NULL,
			[LastUpdatedTime] DATETIME2 NULL,
			[Name] VARCHAR(MAX) NULL,
			[Active] BIT NULL
		);

		INSERT INTO #TempQuickBooksPaymentMethodType ([Id], [SyncToken], [LastUpdatedTime], [Name], [Active])
		SELECT [Id], [SyncToken], [LastUpdatedTime], [Name], [Active] FROM @tbl_QuickBooksPaymentMethodType;

		SELECT @TotalRecord = COUNT([TempId]), @CurrentRecordId = MIN([TempId]) FROM #TempQuickBooksPaymentMethodType;

		WHILE(ISNULL(@TotalRecord, 0) > ISNULL(@CurrentRecordId, 0))
		BEGIN

			SELECT @QBId = [Id], @QBSyncToken = [SyncToken], @QBLastUpdatedTime = [LastUpdatedTime], @QBName = [Name], @QBActive = [Active] FROM #TempQuickBooksPaymentMethodType WHERE [TempId] = @CurrentRecordId;

			IF EXISTS(SELECT [QuickBooksReferenceId] FROM [dbo].[PaymentMethod] WHERE ISNULL([QuickBooksReferenceId], '') = @QBId)
			BEGIN
				
				UPDATE PM
				SET	PM.[UpdatedDate] = GETUTCDATE(),
					PM.[Description] = @QBName,
					PM.[SyncToken] = @QBSyncToken,
					PM.[LastSyncDate] = GETUTCDATE()
				FROM [dbo].[PaymentMethod] PM WITH(NOLOCK)
				WHERE PM.[QuickBooksReferenceId] = @QBId

			END
			ELSE
			BEGIN

				IF NOT EXISTS(SELECT [PaymentMethodId] FROM [dbo].[PaymentMethod] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER(@QBName)) AND ISNULL(@SyncPaymentMethods, 0) = 1
				BEGIN
					INSERT INTO [dbo].[PaymentMethod] ([Description], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted], [QuickBooksReferenceId], [IsUpdated], [LastSyncDate], [SyncToken])
					VALUES(@QBName, 0, 'ADMIN', GETUTCDATE(), 'ADMIN', GETUTCDATE(), 1, 0, @QBId, 0, GETUTCDATE(), @QBSyncToken)
				END 
				ELSE IF EXISTS(SELECT [PaymentMethodId] FROM [dbo].[PaymentMethod] WITH(NOLOCK) WHERE UPPER([Description]) = UPPER(@QBName) AND ISNULL([QuickBooksReferenceId], '') = '') AND ISNULL(@SyncPaymentMethods, 0) = 1
				BEGIN
					UPDATE PM
					SET	PM.[UpdatedDate] = GETUTCDATE(),
						PM.[Description] = @QBName,
						PM.[SyncToken] = @QBSyncToken,
						PM.[LastSyncDate] = GETUTCDATE(),
						PM.[QuickBooksReferenceId] = @QBId
					FROM [dbo].[PaymentMethod] PM WITH(NOLOCK)
					WHERE PM.[Description] = @QBName
				END
			END

			SET @CurrentRecordId += 1;
		END

		--SELECT * FROM #TempQuickBooksPaymentMethodType;

		-- Cleanup
		DROP TABLE #TempQuickBooksPaymentMethodType;

	END TRY
	BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'USP_SyncQuickBooksPaymentMethods'
        , @ProcedureParameters VARCHAR(3000)  = ''
        , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException
                @DatabaseName           =  @DatabaseName
                , @AdhocComments          =  @AdhocComments
                , @ProcedureParameters    =  @ProcedureParameters
                , @ApplicationName        =  @ApplicationName
                , @ErrorLogID             =  @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
  END CATCH
END