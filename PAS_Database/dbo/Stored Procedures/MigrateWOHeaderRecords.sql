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
		FROM [Quantum_Staging].dbo.[WorkOrderHeaders] WOH WITH (NOLOCK) WHERE WOH.WorkOrderId = 7892; --WOH.Migrated_Id IS NULL;

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

					EXEC [dbo].[UpdateWorkOrderColumnsWithId] @InsertedWorkOrderId;

					DECLARE @WOS_DESCRIPTION VARCHAR(100) = NULL;
					DECLARE @WorkScopeId BIGINT = NULL, @WorkScopeName VARCHAR(50) = NULL;
					DECLARE @Part_NUMBER VARCHAR(50) = NULL, @Part_Desc NVARCHAR(MAX) = NULL;
					DECLARE @ItemMaster_Id BIGINT = NULL, @OverhaulHours INT = 0, @RpHours INT = 0, @TestHours INT = 0, @MfgHours INT = 0, @IsPma BIT,@IsDER BIT;
					DECLARE @TurnTimeOverhaulHours INT = 0, @TurnTimeRepairHours INT = 0, @turnTimeBenchTest INT = 0;
					DECLARE @NTE INT = 0, @CMMId BIGINT = NULL, @WorkflowId BIGINT = NULL, @StationId BIGINT = NULL;
					DECLARE @TATDaysStandard INT = 0;
					DECLARE @STM_AUTO_KEY BIGINT = NULL, @PCC_AUTO_KEY BIGINT = NULL;
					DECLARE @STOCK_LINE  VARCHAR(50) = '', @CTRL_ID VARCHAR(50) = '', @CTRL_NUMBER VARCHAR(50) = '';
					DECLARE @StockLineId BIGINT = NULL;
					DECLARE @ConditionCode VARCHAR(50), @ConditionId BIGINT = 0;
					DECLARE @IsTraveler BIT;
					DECLARE @WorkOrderStageId BIGINT = NULL;
					DECLARE @WorkOrderStatusId BIGINT = NULL;
					DECLARE @PriorityId BIGINT = NULL;
					DECLARE @ManagementStructureId BIGINT = 0, @PartId BIGINT = NULL, @WOPartModuleId INT = NULL;

					SELECT @WOS_DESCRIPTION = [DESCRIPTION] FROM [Quantum].QCTL_NEW_3.WO_STATUS WS WITH(NOLOCK) WHERE [WOS_AUTO_KEY] = @WOS_AUTO_KEY;
					SELECT @WorkScopeId = [WorkScopeId] FROM [dbo].[WorkScope] WS WITH(NOLOCK) WHERE WS.[WorkScopeCode] = @WOS_DESCRIPTION AND [MasterCompanyId] = @FromMasterComanyID;

					IF (@WorkScopeId IS NULL OR @WorkScopeId = 0)
					BEGIN
						SELECT @WorkScopeId = [WorkScopeId] FROM [dbo].[WorkScope] WS WITH(NOLOCK) WHERE UPPER(WS.[WorkScopeCode]) = UPPER('REPAIR') AND [MasterCompanyId] = @FromMasterComanyID;
					END
				
					SELECT @Part_NUMBER = IM.PartNumber, @Part_Desc = IM.PartDescription FROM [Quantum_Staging].dbo.ItemMasters IM WITH(NOLOCK) WHERE IM.ItemMasterId = @PNM_AUTO_KEY;

					SELECT @ItemMaster_Id = IM.[ItemMasterId],@OverhaulHours = IM.[OverhaulHours],@RpHours = [RpHours],
				       @TestHours = [TestHours],@MfgHours = [MfgHours],@IsPma = [IsPma],@IsDER = [IsDER],
					   @TurnTimeOverhaulHours = [TurnTimeOverhaulHours],@TurnTimeRepairHours = [TurnTimeRepairHours],@turnTimeBenchTest = turnTimeBenchTest
					FROM [dbo].[ItemMaster] IM WITH(NOLOCK) WHERE UPPER(IM.[partnumber]) = UPPER(@Part_NUMBER) AND UPPER(IM.[PartDescription]) = UPPER(@Part_Desc)
					AND IM.MasterCompanyId = @FromMasterComanyID;

					SELECT @WorkScopeName = [WorkScopeCode] FROM [dbo].[WorkScope] WS WITH(NOLOCK) WHERE [WorkScopeId] = @WorkScopeId AND [MasterCompanyId] = @FromMasterComanyID;

					SELECT @NTE = CASE WHEN @WorkScopeName = 'OH' THEN @OverhaulHours 
				                   WHEN @WorkScopeName = 'REP' THEN @RpHours 
								   WHEN @WorkScopeName = 'BENCHCHECK' THEN @TestHours
								   WHEN @WorkScopeName = 'MFG' THEN @MfgHours
								   ELSE 0 END;

					SELECT @TATDaysStandard = CASE WHEN @WorkScopeName = 'OH' THEN @OverhaulHours 
									   WHEN @WorkScopeName = 'REP' THEN @RpHours 
									   WHEN @WorkScopeName = 'BENCHCHECK' THEN @TestHours								  
									   ELSE 0 END;

					PRINT '@CurrentWorkOrderId';
					PRINT @CurrentWorkOrderId;

					SELECT @STM_AUTO_KEY = StocklineId FROM Quantum_Staging.dbo.StockReservations WITH(NOLOCK) WHERE WorkOrderId = @CurrentWorkOrderId;

					IF (@STM_AUTO_KEY > 0)
					BEGIN
						PRINT '@STM_AUTO_KEY > 0';
						PRINT @STM_AUTO_KEY;

						SELECT @PCC_AUTO_KEY = [PCC_AUTO_KEY], @STOCK_LINE = (CAST(ISNULL(STOCK_LINE, '') AS VARCHAR)), @CTRL_ID = (CAST(ISNULL(CTRL_ID, '') AS VARCHAR)), @CTRL_NUMBER = (CAST(ISNULL(CTRL_NUMBER, '') AS VARCHAR))				
						FROM [Quantum].QCTL_NEW_3.STOCK WHERE [STM_AUTO_KEY] = @STM_AUTO_KEY;

						SELECT @StockLineId = [StockLineId] FROM [dbo].[Stockline] 
						WHERE UPPER([StockLineNumber])  = UPPER(@STOCK_LINE) AND UPPER([IdNumber])  = UPPER(@CTRL_ID) 
						AND UPPER([ControlNumber])  = UPPER(@CTRL_NUMBER) 
						AND [ItemMasterId] = @ItemMaster_Id;

						SELECT @TearDownTypes = [TearDownTypes], 
							   @IsTraveler = [IsTraveler], 
							   @WorkOrderStageId = [DefaultStageCodeId],  
							   @WorkOrderStatusId = [DefaultStatusId], 
							   @PriorityId = [DefaultPriorityId]
						FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @FromMasterComanyID;

						IF (@StockLineId > 0)
						BEGIN
							PRINT '@StockLineId > 0';
							PRINT @StockLineId;

							SELECT @ConditionCode = CC.CONDITION_CODE FROM [Quantum].QCTL_NEW_3.[PART_CONDITION_CODES] CC WITH(NOLOCK) WHERE CC.PCC_AUTO_KEY = @PCC_AUTO_KEY;	   	  
							
							SELECT @ConditionId = [ConditionId] FROM [dbo].[Condition] Cond WITH(NOLOCK) WHERE (UPPER(Cond.Code) = UPPER(@ConditionCode)) AND [MasterCompanyId] = @FromMasterComanyID;

							IF (@ConditionId IS NULL OR @ConditionId = 0)
							BEGIN
								SELECT @ConditionId = [DefaultConditionId] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @FromMasterComanyID;
							END

							SELECT @CMMId = PIM.[PublicationRecordId] 
							FROM [dbo].[Publication] P WITH(NOLOCK)
							INNER JOIN [dbo].[PublicationItemMasterMapping] PIM WITH(NOLOCK) ON P.[PublicationRecordId] = PIM.[PublicationRecordId]
							WHERE P.[MasterCompanyId] = @FromMasterComanyID 
							AND P.[ExpirationDate] <= GETDATE() AND P.IsDeleted = 0 AND P.IsActive = 1 
							AND PIM.[ItemMasterId] = @ItemMaster_Id;

							SELECT @WorkflowId =[WorkflowId] FROM [dbo].[Workflow] P WITH(NOLOCK)
							WHERE P.[MasterCompanyId] = @FromMasterComanyID 
							AND (P.[CustomerId] IS NULL OR P.CustomerId = @CustomerId) 
							AND P.[ItemMasterId] = @ItemMaster_Id AND P.WorkScopeId = @WorkScopeId AND P.[IsDeleted] = 0 AND P.[IsActive] = 1 
							AND (P.[IsVersionIncrease] = 0 OR P.[IsVersionIncrease] IS NULL);

							SELECT @StationId = [StationId] 
							FROM [dbo].[Employee] E WITH(NOLOCK) 
							INNER JOIN dbo.[EmployeeStation] ES WITH(NOLOCK) ON E.[StationId] = ES.[EmployeeStationId]
							WHERE E.[MasterCompanyId] = @FromMasterComanyID AND [EmployeeId] = @DefaultUserId;

							SELECT TOP 1 @ManagementStructureId = MS.ManagementStructureId FROM DBO.ManagementStructure MS WHERE [MasterCompanyId] = @FromMasterComanyID;

							INSERT INTO [dbo].[WorkOrderPartNumber]([WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate]
							   ,[EstimatedCompletionDate],[NTE],[Quantity],[StockLineId],[CMMId],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId]
							   ,[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],[UpdatedBy]
							   ,[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent]
							   ,[RevisedPartId],[ManagementStructureId],[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate]
							   ,[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1]
							   ,[Level2],[Level3],[Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid]
							   ,[RevisedPartNumber],[RevisedPartDescription],[IsTraveler])
							SELECT @InsertedWorkOrderId, @WorkScopeId, DATEADD(DAY, 90, CAST(WO.EntryDate AS DATETIME2)), CAST(WO.EntryDate AS DATETIME2), DATEADD(DAY, 90, CAST(WO.EntryDate AS DATETIME2)),
								DATEADD(DAY, 90, CAST(WO.EntryDate AS DATETIME2)), @NTE, (CAST(ISNULL(WO.KitQty, 0) AS INT)), @StockLineId, @CMMId, @WorkflowId, @WorkOrderStageId, @WorkOrderStatusId,
								@PriorityId, @IsPma, @IsDER, @StationId, @TATDaysStandard, @FromMasterComanyID, @UserName, @UserName,
								CAST(WO.EntryDate AS DATETIME2), CAST(WO.EntryDate AS DATETIME2), 1, 0, @ItemMaster_Id, NULL, @ConditionId, 0,
								NULL, @ManagementStructureId, 0, NULL, @WorkScopeName, 0, CAST(WO.EntryDate AS DATETIME2),
								0, WO.TailNumber, NULL, NULL, 0, @ConditionId, WO.CompanyRefNumber, NULL,
								NULL, NULL, NULL, CAST(WO.EntryDate AS DATETIME2), NULL, NULL, NULL,
								NULL, NULL, 1
							FROM #TempWOHeader AS WO WHERE ID = @LoopID;

							SELECT @PartId = IDENT_CURRENT('WorkOrderPartNumber');

							SELECT @WOPartModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrderMPN';
				 						 				 
							EXEC [dbo].[USP_SaveWOMSDetails] @WOPartModuleId, @PartId, @ManagementStructureId, @FromMasterComanyID, @UserName, 0;

							--------------------------------------------------WORK ORDER WORK FLOW-----------------------------------
							DECLARE @WorkFlowWorkOrderId BIGINT

							INSERT INTO [dbo].[WorkOrderWorkFlow] ([WorkOrderId],[WorkflowDescription],[Version],[WorkScopeId],[ItemMasterId]
                                   ,[CustomerId],[CurrencyId],[WorkflowExpirationDate],[IsCalculatedBERThreshold],[IsFixedAmount]
								   ,[FixedAmount],[IsPercentageOfNew],[CostOfNew],[PercentageOfNew],[IsPercentageOfReplacement]
								   ,[CostOfReplacement],[PercentageOfReplacement],[Memo],[BERThresholdAmount],[WorkOrderNumber]
								   ,[OtherCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive]
								   ,[IsDeleted],[WorkflowCreateDate],[WorkflowId],[WorkFlowWorkOrderNo],[ChangedPartNumberId]
								   ,[MaterilaCost],[ExpertiseCost],[ChargesCost],[Total],[PerOfBerThreshold],[WorkOrderPartNoId])
							 SELECT @CurrentWorkOrderId, NULL, NULL, NULL, @ItemMaster_Id
							        , NULL, NULL, NULL, NULL, NULL
									, NULL, NULL, NULL, NULL, NULL
									, NULL, NULL, NULL, NULL, NULL
									, NULL, @FromMasterComanyID, @UserName, @UserName, CAST(WO.EntryDate AS DATETIME2), CAST(WO.EntryDate AS DATETIME2), 1
									, 0, CAST(WO.EntryDate AS DATETIME2), 0, NULL, NULL
									, NULL, NULL, NULL, NULL, NULL, @PartId
							   FROM #TempWOHeader AS WO WHERE [ID] = @LoopID; 

							SELECT @WorkFlowWorkOrderId = IDENT_CURRENT('WorkOrderWorkFlow');

							---------------------------------------------------------Work Order Settlement--------------------------------------------------------------------------
							
							INSERT INTO [dbo].[WorkOrderSettlementDetails]([WorkOrderId],[WorkFlowWorkOrderId],[workOrderPartNoId],[WorkOrderSettlementId]
								   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsMastervalue]
								   ,[Isvalue_NA],[Memo],[ConditionId],[UserId],[UserName],[sattlement_DateTime],[conditionName],[RevisedPartId])
     						SELECT @CurrentWorkOrderId, @WorkFlowWorkOrderId, @PartId, [WorkOrderSettlementId],
							        @FromMasterComanyID, @UserName, @UserName, @ENTRY_DATE, @ENTRY_DATE, 1, 0, 0,
									0, '', NULL, NULL, NULL, NULL, NULL, NULL	
							FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK) WHERE [IsDeleted] = 0;

							---------------------------------------------------------Common WorkOrder Teardown-----------------------------------------------------------------------------------------------
							
							INSERT INTO [dbo].[CommonWorkOrderTearDown]([CommonTeardownTypeId],[WorkOrderId],[WorkFlowWorkOrderId],[WOPartNoId],[Memo]
								   ,[ReasonId],[TechnicianId],[TechnicianDate],[InspectorId],[InspectorDate],[IsDocument],[ReasonName],[InspectorName]
								   ,[TechnicalName],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[MasterCompanyId]
								   ,[IsSubWorkOrder],[SubWorkOrderId],[SubWOPartNoId])
							SELECT  Item, @CurrentWorkOrderId, @WorkFlowWorkOrderId, @PartId, '',
									NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL,
									NULL, @UserName, @UserName, @ENTRY_DATE, @ENTRY_DATE, 1, 0, @FromMasterComanyID,
									0, 0, 0 
							FROM [dbo].SplitString(@TearDownTypes,',');

							----------------------------------------------------------------LABOR----------------------------------------------------------------------------------------
					
							EXEC [dbo].[USP_CreateTravelerLabourTask] @CurrentWorkOrderId, @PartId, @WorkFlowWorkOrderId, @FromMasterComanyID, @UserName;

							EXEC [dbo].[UpdateWorkOrderColumnsWithId] @CurrentWorkOrderId;

							UPDATE WOH
							SET WOH.Migrated_Id = @InsertedWorkOrderId,
							WOH.SuccessMsg = 'Record migrated successfully'
							FROM [Quantum_Staging].DBO.WorkOrderHeaders WOH WHERE WOH.WorkOrderId = @CurrentWorkOrderId;
						END
					END
					ELSE
					BEGIN
						UPDATE WOH
						SET WOH.ErrorMsg = WOH.ErrorMsg + '<p>MPN Stockline Not Found</p>'
						FROM [Quantum_Staging].DBO.WorkOrderHeaders WOH WHERE WOH.WorkOrderId = @CurrentWorkOrderId;
					END

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