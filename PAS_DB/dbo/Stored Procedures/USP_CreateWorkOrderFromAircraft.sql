/*************************************************************           
 ** File:   [USP_CreateWorkOrderFromAircraft]           
 ** Author:    Moin Bloch
 ** Description: This stored procedure is used to Create Work Order Quote
 ** Purpose:         
 ** Date:   29/05/2026        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    29/05/2026   Moin Bloch       Updated
	2    02/06/2026   Amit Ghediya     Update for get CustomerId from AircraftRegistryHeader [PN-16679]

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderFromAircraft]
@AircraftInstalledPartDetailsId BIGINT = NULL,
@AircraftRegistryId             BIGINT = NULL,
@ProgramId                      BIGINT = NULL,
@MtcCategoryId                  BIGINT = NULL,
@MaintenanceTypeId              BIGINT = NULL,
@StockLineId                    BIGINT = NULL,
@WorksheetHeaderId              BIGINT = NULL,
@EmployeeId                     BIGINT = NULL,
@CreatedBy                      VARCHAR(256),
@MasterCompanyId                INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		-- Declare variables
			DECLARE @Customer INT,@Internal INT,@TearDown INT,@ShopServices INT,@OpenDate DATETIME2(7) = GETUTCDATE(),@WorkOrderTypeId INT 
			DECLARE @CustomerId BIGINT=0,@CustomerContactId BIGINT=0,@ReceivingCustomerWorkId BIGINT=NULL,@ItemMasterId BIGINT=0,@ConditionId BIGINT=0,@RecStockLineId BIGINT=0,@WorkScopeId BIGINT=0,@CsrId BIGINT=0
			DECLARE @WorkOrderStatusId BIGINT, @CreatedDate DATETIME2(7) = GETUTCDATE(),@SalesPersonId BIGINT=0,@ContactContactId BIGINT=NULL
			DECLARE @Memo VARCHAR(MAX)='Created From Aircraft',@Notes VARCHAR(MAX)='Created From Aircraft'
			DECLARE @CustomerName VARCHAR(100)='',@ContractReference VARCHAR(100)='',@Email VARCHAR(200)='',@CustomerPhone VARCHAR(20)=''
			DECLARE @CreditLimit DECIMAL(18,2)=0,@AnnualRevenuePotential DECIMAL(16,2)=0,@ARBalance DECIMAL(18,2)=0,@SalesPersonName VARCHAR(100)='',@MPNPartNumber VARCHAR(400)=''
			DECLARE @CreditTermsId INT=0,@CreditTerms VARCHAR(200) = NULL,@TearDownTypes VARCHAR(300) = NULL,@RMAHeaderId BIGINT = NULL,@IsWarranty BIT = NULL,@IsAccepted BIT = NULL
			DECLARE @ReasonId BIGINT = NULL,@Reason VARCHAR(500) = NULL, @IsManualForm BIT = NULL,@CurrencyId BIGINT = NULL,@Partnumber VARCHAR(50)=''
			DECLARE @PercentId BIGINT = NULL,@Days INT = NULL,@NetDays INT = NULL,@ForeignExchangeRate  DECIMAL(18,2) = 1.00
			DECLARE @WorkOrderType VARCHAR(50) ='Customer', @WorkOrderFormTypeId BIGINT=1,@IsWoAlwaysOrOndemandId  BIT = NULL, @CustomerTypeId BIGINT = NULL
			DECLARE @PartNumbers NVARCHAR(MAX)=NULL,@IsTraveler BIT=NULL,@AllowInvoiceBeforeShipping BIT=NULL,@IsFromLot BIT=NULL,@WorkOrderScopeId BIGINT = NULL
			DECLARE @CustomerType VARCHAR(200) = NULL, @CustomerAffiliation VARCHAR(50) = NULL,@CustomerAffiliationId  BIGINT = NULL,@IsActive BIT=1,@IsDeleted BIT=0,@WorkOrderStatus VARCHAR(50)=''
			DECLARE  @ExternalCustomerType VARCHAR(50) = 'External'
			DECLARE @DefaultPriorityId BIGINT=0,@DefaultStageCodeId BIGINT=0,@DefaultStatusId BIGINT=0,@ModuleEnumCustomer INT=1

			SELECT @CustomerId = [CustomerId],@ConditionId = [ConditionId] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;
			IF(ISNULL(@CustomerId,0) = 0)
			BEGIN
				 SELECT @CustomerId = ACH.CustomerId  FROM dbo.AircraftRegistryHeader ACH WITH(NOLOCK) WHERE [AircraftRegistryId] = @AircraftRegistryId
			END

			SELECT @CustomerName=[Name], @CustomerAffiliationId = [CustomerAffiliationId], @CustomerTypeId = CustomerTypeId FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;
			
		    SELECT @Customer = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';	
			SELECT @Internal = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';		
			
			SELECT @WorkOrderStatusId=[Id] FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE [Description] = 'Open';

			SELECT @CustomerAffiliation = [Description] FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) WHERE [CustomerAffiliationId]=@CustomerAffiliationId

		    IF(@ExternalCustomerType = @CustomerAffiliation)
			BEGIN
				SET @WorkOrderTypeId = @Customer
			END
			ELSE
			BEGIN
				SET @WorkOrderTypeId = @Internal
			END
			
			SELECT TOP 1 @CreditLimit=[CreditLimit],@CreditTermsId=[CreditTermsId],@CurrencyId=[CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

			SELECT @PercentId=[PercentId],@Days=[Days],@NetDays=[NetDays],@CreditTerms = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId AND [MasterCompanyId]=@MasterCompanyId AND [IsActive]=1 AND [IsDeleted]=0;
			
			SELECT TOP 1 @CsrId =[CsrId],@SalesPersonId = [PrimarySalesPersonId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

			SELECT @CustomerContactId = cc.CustomerContactId, @ContactContactId=con.[ContactId] FROM [dbo].[CustomerContact] cc WITH(NOLOCK)
			INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.ContactId = con.ContactId 
			WHERE cc.CustomerId = @CustomerId AND cc.IsDefaultContact = 1 

			SELECT TOP 1 @TearDownTypes=[TearDownTypes],@IsManualForm = CASE WHEN [IsManualForm] IS NULL THEN 0 ELSE [IsManualForm] END,@IsTraveler = [IsTraveler],@AllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping],
			@DefaultPriorityId=ISNULL([DefaultPriorityId],0),@DefaultStageCodeId=ISNULL([DefaultStageCodeId],0),@DefaultStatusId=ISNULL([DefaultStatusId],0)
			FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
					   						
			-- PART DETAILS					

			DECLARE @EstimatedShipDate DATETIME2(7) = NULL,@CustomerRequestDate DATETIME2(7) = GETUTCDATE(),@PromisedDate DATETIME2(7) = NULL,@ReceivedDate DATETIME2(7) = NULL
			DECLARE @EstimatedCompletionDate DATETIME2(7) = NULL,@MSModuleStockline INT=2,@NTE INT = 0,@WorkflowId INT = NULL,@TATDaysCurrent INT =NULL
			
			DECLARE @PMACOUNT INT=0,@DERCOUNT INT =0,@IsPMA BIT = 0,@IsDER BIT = 0,@TechnicianId BIGINT = NULL,@RevisedPartId BIGINT = NULL,@ManagementStructureId BIGINT = NULL
			DECLARE @ACTailNum NVARCHAR(500)= NULL,@RevisedConditionId BIGINT=NULL,@RevisedItemmasterid BIGINT=NULL,@PartDescription NVARCHAR(MAX)=''
			DECLARE @Level1 [VARCHAR](200) = NULL,@Level2 [VARCHAR](200) = NULL,@Level3 [VARCHAR](200)= NULL,@Level4 [VARCHAR](200)= NULL,@SerialNumber  VARCHAR(50)=NULL,@AirCraftSerialNumber VARCHAR(50)=NULL
			DECLARE @AircraftRegistryNumber VARCHAR(50)=NULL
			

			IF OBJECT_ID(N'tempdb..#TempTableForPartType') IS NOT NULL
			BEGIN
				DROP TABLE #TempTableForPartType
			END
		
			CREATE TABLE #TempTableForPartType
			(			 
				[PartType] VARCHAR(100)
			)

			INSERT INTO #TempTableForPartType([PartType])
			SELECT rp.[PartType] FROM [dbo].[StockLine] rc WITH(NOLOCK)
			JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.[ItemMasterId] = im.[ItemMasterId]
			JOIN [dbo].[RestrictedParts] rp WITH(NOLOCK) ON rc.[CustomerId] = rp.[ReferenceId]
			WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rp.[ModuleId] = @ModuleEnumCustomer
			AND rc.[StockLineId] = @StockLineId;

			SELECT @PMACOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'PMA';
			SELECT @DERCOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'DER';
			
			SELECT 
				@PartNumber = im.[PartNumber],
				@PartDescription = im.[PartDescription],
				@SerialNumber = sl.[SerialNumber],				
				@ReceivedDate = ISNULL(sl.[ReceivedDate], GETUTCDATE()),				
				@ManagementStructureId = sl.[ManagementStructureId],							
				@ItemMasterId = sl.[ItemMasterId],				
				@WorkOrderScopeId = NULL,
				@NTE = im.[OverhaulHours] + im.[mfgHours] + im.[RPHours] + im.[TestHours],
			    @IsPMA = CASE WHEN @PMACOUNT > 0 THEN 0 ELSE c.[RestrictPMA] END,
			    @IsDER = CASE WHEN @DERCOUNT > 0 THEN 0 ELSE c.[RestrictDER] END,				 			
				@ACTailNum = sl.[AircraftTailNumber]								
			FROM [dbo].[StockLine] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sl.[ItemMasterId] = im.[ItemMasterId]
			LEFT JOIN [dbo].[Customer] c WITH(NOLOCK) ON sl.[CustomerId] = c.[CustomerId]
			INNER JOIN [dbo].[Condition] con WITH(NOLOCK) ON sl.[ConditionId] = con.[ConditionId]			
			 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
			 LEFT JOIN [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK) ON sl.[StockLineId] = msd.[ReferenceID] AND msd.[ModuleID] = @MSModuleStockline
			WHERE sl.[StockLineId] = @StockLineId;
						
			IF(@MaintenanceTypeId > 0)
			BEGIN
				SET @WorkOrderScopeId = @MaintenanceTypeId
			END
			ELSE 
			BEGIN
				SET @WorkOrderScopeId = (SELECT TOP 1 [MaintenanceTypeId] FROM [dbo].[AircraftSetup] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId)				
			END

			SELECT TOP 1 @WorkflowId = CASE WHEN  wf.[WorkflowId] = 0 THEN NULL ELSE wf.[WorkflowId] END					 
			FROM [dbo].[Workflow] wf  WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON wf.[ItemMasterId] = im.[ItemMasterId]
			INNER JOIN [dbo].[WorkScope] ws  WITH(NOLOCK) ON wf.[WorkScopeId] = ws.[WorkScopeId]
			WHERE wf.[IsDeleted] = 0 AND wf.[IsActive] = 1 AND wf.[ItemMasterId] = @ItemMasterId AND wf.[WorkScopeId] = @WorkOrderScopeId AND wf.[IsVersionIncrease] = 0;
						
			SET @RevisedPartId = (SELECT [RevisedPartId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId);

			SELECT @ACTailNum = [TailNum], @AirCraftSerialNumber = [SerialNum],@AircraftRegistryNumber = [AircraftRegistryNumber] FROM [dbo].[AircraftRegistryHeader] WITH(NOLOCK) WHERE [AircraftRegistryId] = @AircraftRegistryId
			
			SET @TATDaysCurrent = DATEDIFF(DAY, @ReceivedDate, GETUTCDATE())
			DECLARE @tbl_Parts WorkOrderMPNType;
			INSERT INTO @tbl_Parts
			(
				[ID],[WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],
				[NTE],[Quantity],[StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],
				[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],
				[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
				[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],
				[ManagementStructureId],[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate],
				[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],
				[CustomerReference],[Level1],[Level2],[Level3],[Level4],[AssignDate],
				[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],
				[AllowInvoiceBeforeShipping],[WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],
				[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],[WorkOrderStatus],
				[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],
				[SerialNumber],[MasterPartId],[Notes],[AircraftRegistryNumber],[IsFromAircraft],[AircraftInstalledPartDetailsId],
				[AircraftSerialNumber],[AircraftRegistryId],[ProgramId]
			)
			VALUES
			(
				0,                        -- [ID]                          bigint
				0,                        -- [WorkOrderId]                 bigint       (set by SP after insert)
				@WorkOrderScopeId,        -- [WorkOrderScopeId]            bigint
				@EstimatedShipDate,       -- [EstimatedShipDate]           datetime2(7)
				@CustomerRequestDate,     -- [CustomerRequestDate]         datetime2(7)
				@PromisedDate,            -- [PromisedDate]                datetime2(7)
				@EstimatedCompletionDate, -- [EstimatedCompletionDate]     datetime2(7)
				@NTE,                     -- [NTE]                         varchar(30)
				1,                        -- [Quantity]                    int
				@StockLineId,             -- [StockLineId]                 bigint
				NULL,                     -- [CMMIds]                      varchar(256)
				@WorkflowId,              -- [WorkflowId]                  bigint
				@DefaultStageCodeId,      -- [WorkOrderStageId]            bigint
				@DefaultStatusId,         -- [WorkOrderStatusId]           bigint
				@DefaultPriorityId,       -- [WorkOrderPriorityId]         bigint
				@IsPMA,                   -- [IsPMA]                       bit
				@IsDER,                   -- [IsDER]                       bit
				NULL,                     -- [TechStationId]               bigint
				NULL,                     -- [TATDaysStandard]             int
				@MasterCompanyId,         -- [MasterCompanyId]             int
				@CreatedBy,               -- [CreatedBy]                   varchar(256)
				@CreatedBy,               -- [UpdatedBy]                   varchar(256)
				@CreatedDate,             -- [CreatedDate]                 datetime2(7)
				@CreatedDate,             -- [UpdatedDate]                 datetime2(7)
				@IsActive,                -- [IsActive]                    bit
				@IsDeleted,               -- [IsDeleted]                   bit
				@ItemMasterId,            -- [ItemMasterId]                bigint
				@TechnicianId,            -- [TechnicianId]                bigint
				@ConditionId,             -- [ConditionId]                 bigint
				@TATDaysCurrent,          -- [TATDaysCurrent]              int				
				@RevisedPartId,           -- [RevisedPartId]               bigint
				@ManagementStructureId,   -- [ManagementStructureId]       bigint
				0,                        -- [IsMPNContract]               bit
				NULL,                     -- [ContractNo]                  varchar(20)
				NULL,                     -- [WorkScope]                   varchar(200)
				0,                        -- [isLocked]                    bit
				@ReceivedDate,            -- [ReceivedDate]                datetime
				0,                        -- [IsClosed]                    bit
				@ACTailNum,               -- [ACTailNum]                   nvarchar(500)
				NULL,                     -- [ClosedDate]                  datetime
				NULL,                     -- [PDFPath]                     nvarchar(max)
				0,                        -- [IsFinishGood]                bit
				@RevisedConditionId,      -- [RevisedConditionId]          bigint
				NULL,                     -- [CustomerReference]           varchar(256)
				@Level1,                  -- [Level1]                      varchar(200)  Management structure
				@Level2,                  -- [Level2]                      varchar(200)
				@Level3,                  -- [Level3]                      varchar(200)
				@Level4,                  -- [Level4]                      varchar(200)
				NULL,                     -- [AssignDate]                  datetime2(7) (set by SP if TechnicianId > 0)
				@ReceivingCustomerWorkId, -- [ReceivingCustomerWorkId]   bigint
				NULL,                     -- [ExpertiseId]                 smallint     (set by SP from EmployeeExpertise)
				@RevisedItemmasterid,     -- [RevisedItemmasterid]         bigint
				NULL,                     -- [RevisedPartNumber]           varchar(50)
				NULL,                     -- [RevisedPartDescription]     varchar(max)
				@IsTraveler,                 -- [IsTraveler]                  bit          (overridden by WorkOrderSettings)
				@AllowInvoiceBeforeShipping, -- [AllowInvoiceBeforeShipping]  bit          (overridden by WorkOrderSettings)
				NULL,                        -- [WOFPrintDate]                datetime
				NULL,                        -- [CurrentSerialNumber]         varchar(100)
				0,                           -- [StocklineCost]               decimal(18,2)(overridden by SP from StockLine)
				0,                           -- [TendorStocklineCost]         decimal(18,2)
				NULL,                        -- [RepairOrderId]               bigint
				NULL,                        -- [RONumber]                    varchar(50)
				NULL,                        -- [RevisedSerialNumber]         varchar(50)
				0,                      -- [IsROCreated]                 bit
				@PartNumber,            -- [PartNumber]                  varchar(200)
				@PartDescription,       -- [PartDescription]             nvarchar(max)
				@WorkOrderStatus,       -- [WorkOrderStatus]             varchar(max) (display label)
				NULL,                   -- [Priority]                    varchar(100) (display label)
				NULL,                   -- [WorkOrderStage]              varchar(150) (display label)
				NULL,                   -- [ManufacturerName]            varchar(250) (display label)
				NULL,                   -- [TechName]                    varchar(100) (display label)
				NULL,                   -- [EmployeeStation]             varchar(100) (display label)
				NULL,                   -- [PublicationNo]               varchar(max)
				@SerialNumber,          -- [SerialNumber]                varchar(100)
				@ItemMasterId,          -- [MasterPartId]                bigint
				@Notes,                 -- [Notes]                       nvarchar(max)
				@AircraftRegistryNumber,-- [AircraftRegistryNumber]      varchar(30)
				1,                      -- [IsFromAircraft]              bit
				@AircraftInstalledPartDetailsId,                   -- [AircraftInstalledPartDetailsId] bigint
				@AirCraftSerialNumber,           -- [AircraftSerialNumber]        varchar(100)
				@AircraftRegistryId,                   -- [AircraftRegistryId]          bigint
				@ProgramId                    -- [ProgramId]                   bigint
			)
					   			 

			DECLARE @Result TABLE ([WorkOrderId] BIGINT)
			DECLARE @WorkOrderId BIGINT

			INSERT INTO @Result ([WorkOrderId])
			EXEC [dbo].[USP_CreateWorkOrder]
				@WorkOrderId                 = 0,
				@WorkOrderNum                = NULL,
				@IsSinglePN                  = 0,
				@WorkOrderTypeId             = @WorkOrderTypeId,
				@OpenDate                    = @OpenDate,
				@CustomerId                  = @CustomerId,
				@WorkOrderStatusId           = @WorkOrderStatusId,
				@EmployeeId                  = @EmployeeId,
				@MasterCompanyId             = @MasterCompanyId,
				@CreatedBy                   = @CreatedBy,
				@UpdatedBy                   = @CreatedBy,
				@CreatedDate                 = @CreatedDate,
				@UpdatedDate                 = @CreatedDate,
				@IsActive                    = @IsActive,
				@IsDeleted                   = @IsDeleted,
				@SalesPersonId               = @SalesPersonId,
				@CSRId                       = @CsrId,
				@ReceivingCustomerWorkId     = @ReceivingCustomerWorkId,
				@Memo                        = @Memo,
				@Notes                       = @Notes,
				@CustomerContactId           = @CustomerContactId,
				@CustomerName                = @CustomerName,
				@CustomerType                = @CustomerType,
				@CreditLimit                 = @CreditLimit,
				@CreditTerms                 = @CreditTerms,
				@TearDownTypes               = @TearDownTypes,
				@RMAHeaderId                 = @RMAHeaderId,
				@IsWarranty                  = @IsWarranty,
				@IsAccepted                  = @IsAccepted,
				@ReasonId                    = @ReasonId,
				@Reason                      = @Reason,
				@CreditTermId                = @CreditTermsId,
				@IsManualForm                = @IsManualForm,
				@PercentId                   = @PercentId,
				@Days                        = @Days,
				@NetDays                     = @NetDays,
				@WorkOrderType               = @WorkOrderType,
				@FunctionalCurrencyId        = @CurrencyId,
				@ReportCurrencyId            = @CurrencyId,
				@ForeignExchangeRate         = @ForeignExchangeRate,
				@WorkOrderFormTypeId         = @WorkOrderFormTypeId,
				@IsWoAlwaysOrOndemandId      = @IsWoAlwaysOrOndemandId,
				@PartNumbers                 = @PartNumbers,
				@StockLineId                 = @StockLineId,
				@IsTraveler                  = @IsTraveler,
				@AllowInvoiceBeforeShipping  = @AllowInvoiceBeforeShipping,
				@IsFromLot                   = @IsFromLot,
				@MtcCategoryId               = @MtcCategoryId,
				@WorksheetId				 = @WorksheetHeaderId,
				@tbl_WorkOrderPartNumberType = @tbl_Parts    

			-- Retrieve the new WorkOrderId
			SELECT @WorkOrderId = [WorkOrderId] FROM @Result	
			
			-- ══════════════════════════════════════════════════
			-- HISTORY BLOCK
			-- Same pattern as USP_CreateAircraftRegistryHeader
			-- ══════════════════════════════════════════════════
			DECLARE @TemplateBody   VARCHAR(MAX)    = '',
					@Activity       VARCHAR(MAX)    = NULL,
					@HistCreatedBy  VARCHAR(256)    = NULL,
					@WorkOrderStr   VARCHAR(50)     = NULL;

			-- ── NEW value holders ─────────────────────────────────
			DECLARE @New_PartNumbers                   VARCHAR(200),
					@New_PartDescription                   VARCHAR(200),
					@New_IsActive                   VARCHAR(10);

			SELECT @WorkOrderStr = WorkOrderNum FROM DBO.Workorder WITH(NOLOCK) WHERE workorderid= @WorkOrderId;

			SET @WorkOrderStr = 'WorkOrder Num.: ' + @WorkOrderStr;

			-- Read NEW values from TVP
			SELECT
				@New_PartNumbers                  = @PartNumbers,
				@New_PartDescription             = @PartDescription,
				@New_IsActive                  = 'Active';

			SET @Activity = 'New WorkOrder Added';

               IF @New_PartNumbers                 <> '' SET @TemplateBody += 'Part Num.: '                 + @New_PartNumbers                 + ' | ';
               IF @New_PartDescription            <> '' SET @TemplateBody += 'Part Desc.: '            + @New_PartDescription            + ' | ';
               SET @TemplateBody += 'Created By: ' + ISNULL(@HistCreatedBy,'') + ' | ';
               SET @TemplateBody += 'Created Date: '+ CONVERT(VARCHAR(30), GETUTCDATE(), 103);

			-- Call usp_SaveAircraftHistory once
			IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
			BEGIN

				EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2,@ModuleName = 'Aircraft WorkOrder',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
											 @OldValue = NULL,@NewValue = @WorkOrderStr,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
											 @CreatedBy = @CreatedBy;
			END
			-- ── END HISTORY BLOCK ─────────────────────────────
	END

	SELECT @WorkOrderId AS [WorkOrderId]

	
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrder' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
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