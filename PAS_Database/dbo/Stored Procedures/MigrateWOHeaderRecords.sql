/*************************************************************             
 ** File:   [MigrateWOHeaderRecords]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to Migrate Work Order Header Records
 ** Purpose:           
 ** Date:   12/18/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    12/28/2023   Vishal Suthar		Created
  

declare @p5 int
set @p5=NULL
declare @p6 int
set @p6=NULL
declare @p7 int
set @p7=NULL
declare @p8 int
set @p8=NULL
exec sp_executesql N'EXEC MigrateWOHeaderRecords @FromMasterComanyID, @UserName, @Processed OUTPUT, @Migrated OUTPUT, @Failed OUTPUT, @Exists OUTPUT',N'@FromMasterComanyID int,@UserName nvarchar(12),@Processed int output,@Migrated int output,@Failed int output,@Exists int output',@FromMasterComanyID=12,@UserName=N'ROGER BENTLY',@Processed=@p5 output,@Migrated=@p6 output,@Failed=@p7 output,@Exists=@p8 output
select @p5, @p6, @p7, @p8
**************************************************************/
CREATE   PROCEDURE [dbo].[MigrateWOHeaderRecords]
(
	@FromMasterComanyID INT = NULL,
	@UserName VARCHAR(100) NULL,
	@Processed INT OUTPUT,
	@Migrated INT OUTPUT,
	@Failed INT OUTPUT,
	@Exists INT OUTPUT
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @LoopID AS INT;

		IF OBJECT_ID(N'tempdb..#TempWOHeader') IS NOT NULL
		BEGIN
			DROP TABLE #TempWOHeader
		END

		CREATE TABLE #TempWOHeader
		(
			ID bigint NOT NULL IDENTITY,
			[WorkOrderId] [bigint] NOT NULL,
			[WorkOrderNumber] [varchar](100) NULL,
			[StocklineId] [bigint] NULL,
			[ItemMasterId] [bigint] NULL,
			[CustomerId] [bigint] NULL,
			[WorkOrderMaterialId] [bigint] NULL,
			[SystemUserId] [bigint] NULL,
			[EntryDate] [datetime2](7) NULL,
			[OpenFlag] [varchar](10) NULL,
			[Notes] [varchar](max) NULL,
			[KitQty] [int] NULL,
			[WorkOrderStatusId] [bigint] NULL,
			[OPM_Id] [bigint] NULL,
			[DueDate] [datetime2](7) NULL,
			[CompanyRefNumber] [varchar](100) NULL,
			[PriorityId] [int] NULL,
			[TailNumber] [varchar](100) NULL,
			[EngineNumber] [varchar](100) NULL,
			[WarranteeFlag] [varchar](10) NULL,
			[PartConditionId] [bigint] NULL,
			[WoType] [varchar](10) NULL,
			[ShipViaCodeId] [bigint] NULL,
			[IsActive] [varchar](10) NULL,
			[Description] [varchar](max) NULL,
			[SalesOrderPartId] [bigint] NULL,
			[WorkOrderParentId] [bigint] NULL,
			[CurrencyId] [bigint] NULL,
			[CountryCodeId] [bigint] NULL,
			[BatchNumber] [varchar](100) NULL,
			[EstTotalCost] [decimal](18, 2) NULL,
			[UrlLink] [varchar](100) NULL,
			[ReleaseDate] [datetime2](7) NULL,
			[IsTearDown] [varchar](10) NULL,
			[WorkOrderLotId] [bigint] NULL,
			[IntegrationType] [varchar](100) NULL,
			[IsAutoInvoice] [varchar](10) NULL,
			[DateCreated] [datetime2](7) NULL,
			[MasterCompanyId] [bigint] NULL,
			[Migrated_Id] [bigint] NULL,
			[SuccessMsg] [varchar](500) NULL,
			[ErrorMsg] [varchar](500) NULL
		)

		INSERT INTO #TempWOHeader ([WorkOrderId],[WorkOrderNumber],[StocklineId],[ItemMasterId],[CustomerId],[WorkOrderMaterialId],[SystemUserId],[EntryDate],[OpenFlag],[Notes],[KitQty],[WorkOrderStatusId],[OPM_Id],
		[DueDate],[CompanyRefNumber],[PriorityId],[TailNumber],[EngineNumber],[WarranteeFlag],[PartConditionId],[WoType],[ShipViaCodeId],[IsActive],[Description],[SalesOrderPartId],[WorkOrderParentId],[CurrencyId],
		[CountryCodeId],[BatchNumber],[EstTotalCost],[UrlLink],[ReleaseDate],[IsTearDown],[WorkOrderLotId],[IntegrationType],[IsAutoInvoice],[DateCreated],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg])
		SELECT [WorkOrderId],[WorkOrderNumber],[StocklineId],[ItemMasterId],[CustomerId],[WorkOrderMaterialId],[SystemUserId],[EntryDate],[OpenFlag],[Notes],[KitQty],[WorkOrderStatusId],[OPM_Id],
		[DueDate],[CompanyRefNumber],[PriorityId],[TailNumber],[EngineNumber],[WarranteeFlag],[PartConditionId],[WoType],[ShipViaCodeId],[IsActive],[Description],[SalesOrderPartId],[WorkOrderParentId],[CurrencyId],
		[CountryCodeId],[BatchNumber],[EstTotalCost],[UrlLink],[ReleaseDate],[IsTearDown],[WorkOrderLotId],[IntegrationType],[IsAutoInvoice],[DateCreated],[MasterCompanyId],[Migrated_Id],[SuccessMsg],[ErrorMsg]
		FROM [Quantum_Staging].dbo.[WorkOrderHeaders] WOH WITH (NOLOCK) WHERE WOH.Migrated_Id IS NULL;

		DECLARE @ProcessedRecords INT = 0;
		DECLARE @MigratedRecords INT = 0;
		DECLARE @RecordsWithError INT = 0;
		DECLARE @RecordExits INT = 0;

		DECLARE @TotCount AS INT;
		SELECT @TotCount = COUNT(*), @LoopID = MIN(ID) FROM #TempWOHeader;

		WHILE (@LoopID <= @TotCount)
		BEGIN
			SET @ProcessedRecords = @ProcessedRecords + 1;
			
			DECLARE @PNM_AUTO_KEY BIGINT = NULL;
			DECLARE @CMP_AUTO_KEY BIGINT = NULL;   -------- Company		
			DECLARE @CUR_AUTO_KEY BIGINT = NULL;   -------- Currency		
			DECLARE @SVC_AUTO_KEY BIGINT = NULL;   -------- SHIP_VIA_CODES
			DECLARE @WOS_AUTO_KEY BIGINT = NULL;
			DECLARE @SI_NUMBER VARCHAR(200) = NULL;
			DECLARE @ENTRY_DATE DATETIME2 = NULL;
			DECLARE @DefaultUserId AS BIGINT = NULL;

			DECLARE @FoundError BIT = 0;
			DECLARE @ErrorMsg VARCHAR(MAX) = '';
			DECLARE @CurrentWorkOrderId BIGINT = 0;

			SELECT @CurrentWorkOrderId = WorkOrderId, @PNM_AUTO_KEY = ItemMasterId,
		       @CMP_AUTO_KEY = CustomerId,		      
			   @SVC_AUTO_KEY = ShipViaCodeId, 
			   @CUR_AUTO_KEY = CurrencyId,
			   @WOS_AUTO_KEY = WorkOrderStatusId,
			   @SI_NUMBER = WorkOrderNumber,
			   @ENTRY_DATE = CAST(EntryDate AS DATETIME2) FROM #TempWOHeader WHERE ID = @LoopID;

			SELECT @DefaultUserId = U.[EmployeeId] FROM [dbo].[AspNetUsers] U WITH(NOLOCK) WHERE [UserName] LIKE 'MIG-ADMIN' AND [MasterCompanyId] = @FromMasterComanyID;

			DECLARE @CustomerId BIGINT;
			DECLARE @CustomerName VARCHAR(200);
			DECLARE @CustomerAffiliationId BIGINT = NULL;
			DECLARE @StatusId BIGINT;
			DECLARE @SalesPersonId BIGINT = NULL;
			DECLARE @CsrId BIGINT = NULL;
			DECLARE @CustomerContactId BIGINT;
			DECLARE @CustomerType VARCHAR(10) = NULL;
			DECLARE @CreditLimit DECIMAL(18, 2);
			DECLARE @CreditTermsId BIGINT;
			DECLARE @TemrsName VARCHAR(200);
			DECLARE @TearDownTypes VARCHAR(500) = '';
			DECLARE @IsManualForm BIT = NULL;

			SELECT @CustomerId = C.[CustomerId], @CustomerName = C.[Name], @CustomerAffiliationId = c.[CustomerAffiliationId] FROM [dbo].[Customer] C WITH(NOLOCK) WHERE UPPER(C.[CustomerCode]) IN (SELECT UPPER(CMP.[COMPANY_CODE]) FROM [Quantum_Staging].dbo.Customers CMP WHERE CMP.CustomerId = @CMP_AUTO_KEY) AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @CustomerContactId = C.[CustomerContactId] FROM [dbo].[CustomerContact] C WITH(NOLOCK) WHERE C.[CustomerId] = @CustomerId AND C.[IsDefaultContact] = 1 AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @CreditLimit = CF.[CreditLimit], @CreditTermsId = CF.[CreditTermsId] FROM [dbo].[CustomerFinancial] CF WITH(NOLOCK) WHERE [CustomerId] = @CustomerId AND [MasterCompanyId] = @FromMasterComanyID; 
			SELECT @StatusId = WS.[Id] FROM [dbo].[WorkOrderStatus] WS WITH(NOLOCK) WHERE UPPER(WS.[Description]) = UPPER('Open');
			SELECT @SalesPersonId = [PrimarySalesPersonId], @CsrId = [CsrId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @CustomerType = CASE WHEN @CustomerAffiliationId = 1 THEN 'Internal' WHEN @CustomerAffiliationId = 2 THEN 'External' WHEN @CustomerAffiliationId = 3 THEN 'Affiliate' ELSE '' END;
			SELECT @TemrsName = CT.[Name] FROM dbo.[CreditTerms] CT WITH(NOLOCK) WHERE [CreditTermsId] = @CreditTermsId AND [MasterCompanyId] = @FromMasterComanyID;
			SELECT @TearDownTypes = [TearDownTypes], @IsManualForm = IsManualForm FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @FromMasterComanyID;

			IF (ISNULL(@CMP_AUTO_KEY, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Customer not found</p>'
			END
			IF (ISNULL(@CustomerContactId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Customer Contact not found</p>'
			END
			IF (ISNULL(@DefaultUserId, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Default User Id not found</p>'
			END
			IF (ISNULL(@CreditLimit, 0) = 0)
			BEGIN
				SET @FoundError = 1;
				SET @ErrorMsg = @ErrorMsg + '<p>Credit Limit is missing OR zero</p>'
			END
			
			IF (@FoundError = 1)
			BEGIN
				UPDATE WOH
				SET WOH.ErrorMsg = @ErrorMsg
				FROM [Quantum_Staging].DBO.WorkOrderHeaders WOH WHERE WOH.WorkOrderId = @CurrentWorkOrderId;

				SET @RecordsWithError = @RecordsWithError + 1;
			END

			DECLARE @InsertedWorkOrderId BIGINT;

			IF (@FoundError = 0)
			BEGIN
				IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderNum] = @SI_NUMBER AND MasterCompanyId = @FromMasterComanyID)
				BEGIN
					INSERT INTO [dbo].[WorkOrder] ([WorkOrderNum],[IsSinglePN],[WorkOrderTypeId],[OpenDate],[CustomerId],[WorkOrderStatusId]
						   ,[EmployeeId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[SalesPersonId]
						   ,[CSRId],[ReceivingCustomerWorkId],[Memo],[Notes],[CustomerContactId],[CustomerName],[CustomerType],[CreditLimit]
						   ,[CreditTerms],[TearDownTypes],[RMAHeaderId],[IsWarranty],[IsAccepted],[ReasonId],[Reason],[CreditTermId],[IsManualForm])
					 SELECT WO.WorkOrderNumber, 1, 1, CASE WHEN WO.EntryDate IS NOT NULL THEN CAST(WO.EntryDate AS datetime2) ELSE GETDATE() END, @CustomerId, @StatusId,
							@DefaultUserId, @FromMasterComanyID, @UserName, @UserName, CAST(WO.EntryDate AS DATETIME2), CAST(WO.EntryDate AS DATETIME2), 1, 0, @SalesPersonId,
							@CsrId, NULL, '', WO.[NOTES], @CustomerContactId, @CustomerName, @CustomerType, @CreditLimit,
							@TemrsName, @TearDownTypes, NULL, CASE WHEN WO.WarranteeFlag = 'T' THEN 1 ELSE 0 END, NULL, NULL, NULL, @CreditTermsId, @IsManualForm 
					   FROM #TempWOHeader AS WO WHERE ID = @LoopID;

					SELECT @InsertedWorkOrderId = SCOPE_IDENTITY();

					UPDATE WOH
					SET WOH.Migrated_Id = @InsertedWorkOrderId,
					WOH.SuccessMsg = 'Record migrated successfully'
					FROM [Quantum_Staging].DBO.WorkOrderHeaders WOH WHERE WOH.WorkOrderId = @CurrentWorkOrderId;

					SET @MigratedRecords = @MigratedRecords + 1;
				END
			END

			SET @LoopID = @LoopID + 1;
		END
	END

	COMMIT TRANSACTION

	SET @Processed = @ProcessedRecords;
	SET @Migrated = @MigratedRecords;
	SET @Failed = @RecordsWithError;
	SET @Exists = @RecordExits;

	SELECT @Processed, @Migrated, @Failed, @Exists;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
	  ROLLBACK TRAN;
	  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'MigrateWOHeaderRecords'
	  ,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(CAST(@FromMasterComanyID AS VARCHAR(10)), '') + ''
	  ,@ApplicationName varchar(100) = 'PAS'
	  -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
	  RETURN (1);  
	 END CATCH  
END