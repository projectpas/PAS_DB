/*************************************************************           
 ** File:   [USP_UpdateWorkOrderFromAircraft]
 ** Author:    Moin Bloch
 ** Description: This stored procedure is used to Update Work Order 
 ** Purpose:         
 ** Date:   01/06/2026        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1    01/06/2026		Moin Bloch			Created
	2    8/06/2026		Divyesh Kathiriya   Update WorkOrderNum on AircraftMaintenanceProgram Table [PN-16704]
	3    02/06/2026     Amit Ghediya		Update for get CustomerId from AircraftRegistryHeader [PN-16679]
	4    09/06/2026     Amit Ghediya		Adding Header data in History module [PN-16581]

**************************************************************/
CREATE    PROCEDURE [dbo].[USP_UpdateWorkOrderFromAircraft]
@AircraftInstalledPartDetailsId BIGINT = NULL,
@AircraftRegistryId             BIGINT = NULL,
@ProgramId                      BIGINT = NULL,
@MtcCategoryId                  BIGINT = NULL,
@MaintenanceTypeId              BIGINT = NULL,
@StockLineId                    BIGINT = NULL,
@WorksheetHeaderId              BIGINT = NULL,
@EmployeeId                     BIGINT = NULL,
@CreatedBy                      VARCHAR(256),
@MasterCompanyId                INT = NULL,
@WorkOrderId                    BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
    BEGIN TRANSACTION
	    
		DECLARE @Customer INT,@Internal INT,@TearDown INT,@ShopServices INT,@OpenDate DATETIME2(7) = GETUTCDATE(),@WorkOrderTypeId INT 
		DECLARE @ExternalCustomerType VARCHAR(50) = 'External', @CustomerAffiliation VARCHAR(50) = NULL
		DECLARE @WorkOrderStatusId BIGINT,@Memo NVARCHAR(MAX) = NULL,@Notes NVARCHAR(MAX) = NULL
		DECLARE @SalesPersonId BIGINT = NULL,@CreatedDate DATETIME= GETUTCDATE(),@UpdatedDate DATETIME= GETUTCDATE()		
		DECLARE @CSRId BIGINT = NULL,@ReceivingCustomerWorkId BIGINT = NULL         
		DECLARE @CustomerContactId BIGINT,@CustomerName VARCHAR(100) = NULL,@CustomerType VARCHAR(200) = NULL,@CreditLimit DECIMAL(18,2) = NULL,@CreditTerms VARCHAR(200) = NULL,
                @TearDownTypes VARCHAR(300) = NULL,@RMAHeaderId BIGINT = NULL,@IsWarranty BIT = NULL,@IsAccepted BIT = NULL,@ReasonId BIGINT = NULL,@Reason VARCHAR(500) = NULL,
                @CreditTermId INT = NULL,@IsManualForm BIT = NULL,@PercentId BIGINT = NULL,@Days INT = NULL,@NetDays INT = NULL,@WorkOrderType VARCHAR(50) = NULL,
                @FunctionalCurrencyId INT = NULL,@ReportCurrencyId INT = NULL,@ForeignExchangeRate DECIMAL(18,2) = NULL,@WorkOrderFormTypeId BIT = NULL,@IsWoAlwaysOrOndemandId BIT = NULL, 
                @PartNumbers NVARCHAR(MAX)=NULL,@IsTraveler BIT=NULL,@AllowInvoiceBeforeShipping BIT=NULL
		DECLARE @WorkOrderNum VARCHAR(30);

        -- PART DETAILS			
		DECLARE @WorkOrderScopeId BIGINT = NULL
		DECLARE @EstimatedShipDate DATETIME2(7) = NULL,@CustomerRequestDate DATETIME2(7) = GETUTCDATE(),@PromisedDate DATETIME2(7) = NULL,@ReceivedDate DATETIME2(7) = NULL
		DECLARE @EstimatedCompletionDate DATETIME2(7) = NULL,@MSModuleStockline INT=2,@NTE INT = 0,@WorkflowId INT = NULL,@TATDaysCurrent INT =NULL
		DECLARE @PMACOUNT INT=0,@DERCOUNT INT =0,@IsPMA BIT = 0,@IsDER BIT = 0,@TechnicianId BIGINT = NULL,@RevisedPartId BIGINT = NULL,@ManagementStructureId BIGINT = NULL
		DECLARE @ACTailNum NVARCHAR(500)= NULL,@RevisedConditionId BIGINT=NULL,@RevisedItemmasterid BIGINT=NULL,@PartDescription NVARCHAR(MAX)=''
		DECLARE @Level1 [VARCHAR](200) = NULL,@Level2 [VARCHAR](200) = NULL,@Level3 [VARCHAR](200)= NULL,@Level4 [VARCHAR](200)= NULL,@SerialNumber  VARCHAR(50)=NULL,@AirCraftSerialNumber VARCHAR(50)=NULL
		DECLARE @AircraftRegistryNumber VARCHAR(50)=NULL,@ModuleEnumCustomer INT=1,@ConditionId BIGINT=0,@WorkOrderStatus VARCHAR(50)=''
		DECLARE @PartNumber VARCHAR(200) = NULL,@ItemMasterId BIGINT=0,@CustomerId  BIGINT=0
		DECLARE @DefaultPriorityId BIGINT=0,@DefaultStageCodeId BIGINT=0,@DefaultStatusId BIGINT=0

		-- ── OLD value holders (capture BEFORE update) ─────────
        DECLARE @Old_PartNumber         VARCHAR(200),
                @Old_PartDescription    NVARCHAR(MAX),
                @Old_WorkOrderStatus    VARCHAR(100),
                @Old_SerialNumber       VARCHAR(100),
                @Old_ACTailNum          VARCHAR(500),
                @Old_WorkOrderScopeId   VARCHAR(50),
                @Old_StockLineId        VARCHAR(50),
                @Old_ProgramId          VARCHAR(50),
                @Old_WorkOrderNum       VARCHAR(250);

        -- ── Read OLD values from existing WO BEFORE update ────
        SELECT
            @Old_PartNumber         = WPN.PartNumber,
            @Old_PartDescription    = WPN.PartDescription,
            @Old_WorkOrderStatus    = WPN.WorkOrderStatus,
            @Old_SerialNumber       = WPN.CurrentSerialNumber,
            @Old_ACTailNum          = WPN.ACTailNum,
            @Old_WorkOrderScopeId   = CAST(ISNULL(WPN.WorkOrderScopeId, 0) AS VARCHAR),
            @Old_StockLineId        = CAST(ISNULL(WPN.StockLineId, 0) AS VARCHAR),
            @Old_ProgramId          = CAST(ISNULL(WPN.ProgramId, 0) AS VARCHAR),
            @Old_WorkOrderNum		= CAST(ISNULL(WO.WorkOrderNum, 0) AS VARCHAR)
        FROM dbo.WorkOrder WO WITH(NOLOCK)
        INNER JOIN dbo.WorkOrderPartNumber WPN WITH(NOLOCK)
            ON WO.WorkOrderId = WPN.WorkOrderId
        WHERE WO.WorkOrderId    = @WorkOrderId
          AND WO.MasterCompanyId = @MasterCompanyId;

		SELECT @Customer = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';	
		SELECT @Internal = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';	

		IF(@ExternalCustomerType = @CustomerAffiliation)
		BEGIN
			SET @WorkOrderTypeId = @Customer
		END
		ELSE
		BEGIN
			SET @WorkOrderTypeId = @Internal
		END

		SELECT @WorkOrderStatusId = [WorkOrderStatusId],@SalesPersonId = [SalesPersonId], @CSRId = [CSRId],@ReceivingCustomerWorkId = ReceivingCustomerWorkId,
				@Memo = Memo,@Notes= Notes,@CustomerContactId  = CustomerContactId,@CustomerName       = CustomerName,@CustomerType       = CustomerType,
				@CreditLimit = CreditLimit,@CreditTerms = CreditTerms,@TearDownTypes = TearDownTypes,@RMAHeaderId = RMAHeaderId,
				@IsWarranty = IsWarranty,@IsAccepted = IsAccepted,@ReasonId = ReasonId,@Reason = Reason,@CreditTermId = CreditTermId,@IsManualForm = IsManualForm,
				@PercentId = PercentId,@Days = Days,@NetDays = NetDays,@WorkOrderType = WorkOrderType,@FunctionalCurrencyId = FunctionalCurrencyId,
				@ReportCurrencyId     = ReportCurrencyId,@ForeignExchangeRate  = ForeignExchangeRate,@WorkOrderFormTypeId  = WorkOrderFormTypeId,
				@IsWoAlwaysOrOndemandId = IsWoAlwaysOrOndemandId,@MtcCategoryId  = MtcCategoryId		
		FROM  [dbo].[WorkOrder] WHERE [WorkOrderId]=@WorkOrderId

		SELECT @CustomerId = [CustomerId],@ConditionId = [ConditionId] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

		SELECT TOP 1 @TearDownTypes=[TearDownTypes],@IsManualForm = CASE WHEN [IsManualForm] IS NULL THEN 0 ELSE [IsManualForm] END,@IsTraveler = [IsTraveler],@AllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping],
			@DefaultPriorityId=ISNULL([DefaultPriorityId],0),@DefaultStageCodeId=ISNULL([DefaultStageCodeId],0),@DefaultStatusId=ISNULL([DefaultStatusId],0)
			FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
						
		SET @RevisedPartId = (SELECT [RevisedPartId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId);

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
		
		SET @TATDaysCurrent = DATEDIFF(DAY, @ReceivedDate, GETUTCDATE())

		SELECT @ACTailNum = [TailNum], @AirCraftSerialNumber = [SerialNum],@AircraftRegistryNumber = [AircraftRegistryNumber] FROM [dbo].[AircraftRegistryHeader] WITH(NOLOCK) WHERE [AircraftRegistryId] = @AircraftRegistryId

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

        -- Declare the required table-valued parameter
        DECLARE @tbl_WorkOrderPartNumberType WorkOrderMPNType;

        -- Populate the TVP with your data
        INSERT INTO @tbl_WorkOrderPartNumberType
        (
            [ID], [WorkOrderScopeId], [EstimatedShipDate], [CustomerRequestDate],[PromisedDate], [EstimatedCompletionDate], [NTE], [Quantity],
            [StockLineId], [CMMIds], [WorkflowId], [WorkOrderStageId],[WorkOrderStatusId], [WorkOrderPriorityId], [IsPMA], [IsDER],
            [TechStationId], [TATDaysStandard], [MasterCompanyId], [CreatedBy],[UpdatedBy], [CreatedDate],[UpdatedDate], [IsActive], [IsDeleted], 			
			[ItemMasterId], [TechnicianId],[ConditionId], [TATDaysCurrent], [RevisedPartId], [ManagementStructureId],[IsMPNContract], [ContractNo], 
			[WorkScope], [isLocked], [ReceivedDate],[IsClosed], [ACTailNum], [ClosedDate], [PDFPath], [IsFinishGood],[RevisedConditionId], [CustomerReference],
			[Level1], [Level2], [Level3],[Level4], [AssignDate], [ReceivingCustomerWorkId], [ExpertiseId],[RevisedItemmasterid], [RevisedPartNumber], [RevisedPartDescription],
            [IsTraveler], [AllowInvoiceBeforeShipping], [WOFPrintDate],[CurrentSerialNumber], [StocklineCost], [TendorStocklineCost],
            [RepairOrderId], [RONumber], [RevisedSerialNumber], [IsROCreated],[PartNumber], [PartDescription], [WorkOrderStatus], [Priority],
            [WorkOrderStage], [ManufacturerName], [TechName], [EmployeeStation],[PublicationNo], [SerialNumber], [MasterPartId], [Notes],
			[AircraftRegistryNumber],[IsFromAircraft],[AircraftInstalledPartDetailsId],[AircraftSerialNumber],[AircraftRegistryId],[ProgramId] 
        )
        VALUES
        (
            0,                                -- [ID]
            @WorkOrderScopeId,                -- [WorkOrderScopeId]
            @EstimatedShipDate,               -- [EstimatedShipDate]
            @CustomerRequestDate,             -- [CustomerRequestDate]
            @PromisedDate,                    -- [PromisedDate]
            @EstimatedCompletionDate,         -- [EstimatedCompletionDate]
            @NTE,                             -- [NTE]
            1,                                -- [Quantity]
            @StockLineId,                     -- [StockLineId]
            NULL,                             -- [CMMIds]
            @WorkflowId,                      -- [WorkflowId]
			@DefaultStageCodeId,              -- [WorkOrderStageId]            
			@DefaultStatusId,                 -- [WorkOrderStatusId]           
			@DefaultPriorityId,               -- [WorkOrderPriorityId]    
			@IsPMA,                           -- [IsPMA]                      
			@IsDER,                           -- [IsDER] 			
            NULL,                             -- [TechStationId]
            NULL,                             -- [TATDaysStandard]
            @MasterCompanyId,                 -- [MasterCompanyId]
			@CreatedBy,                       -- [CreatedBy]                  
			@CreatedBy,                       -- [UpdatedBy]                  
			@CreatedDate,                     -- [CreatedDate]                
			@CreatedDate,                     -- [UpdatedDate]
			1,                                -- [IsActive]                   
			0,                                -- [IsDeleted]			
            @ItemMasterId,                    -- [ItemMasterId]
            @TechnicianId,                    -- [TechnicianId]
			@ConditionId,                     -- [ConditionId]  			
			@TATDaysCurrent,                  -- [TATDaysCurrent]             			
			@RevisedPartId,                   -- [RevisedPartId]              
			@ManagementStructureId,           -- [ManagementStructureId]   
            0,                                -- [IsMPNContract]
            NULL,                             -- [ContractNo]
            NULL,                             -- [WorkScope]
            0,                                -- [isLocked]
			@ReceivedDate,                    -- [ReceivedDate]        
			0,                                -- [IsClosed]            
			@ACTailNum,                       -- [ACTailNum]           
			NULL,                             -- [ClosedDate]          
			NULL,                             -- [PDFPath]             
			0,                                -- [IsFinishGood]        
			@RevisedConditionId,              -- [RevisedConditionId]  
			NULL,                             -- [CustomerReference]  
			@Level1,                          -- [Level1]                   
			@Level2,                          -- [Level2]                   
			@Level3,                          -- [Level3]                   
			@Level4,                          -- [Level4]                   
			NULL,                             -- [AssignDate]               
			@ReceivingCustomerWorkId,         -- [ReceivingCustomerWorkId]  
			NULL,                             -- [ExpertiseId]              
			@RevisedItemmasterid,             -- [RevisedItemmasterid]      
			NULL,                             -- [RevisedPartNumber]        
			NULL,                             -- [RevisedPartDescription] 
            @IsTraveler,                      -- [IsTraveler]
            @AllowInvoiceBeforeShipping,      -- [AllowInvoiceBeforeShipping]
			NULL,                             -- [WOFPrintDate]                
			NULL,                             -- [CurrentSerialNumber]         
			0,                                -- [StocklineCost]               
			0,                                -- [TendorStocklineCost]         
			NULL,                             -- [RepairOrderId]               
			NULL,                             -- [RONumber]                    
			NULL,                             -- [RevisedSerialNumber]         
			0,                                -- [IsROCreated]               
			@PartNumber,                      -- [PartNumber]                
			@PartDescription,                 -- [PartDescription]           
			@WorkOrderStatus,                 -- [WorkOrderStatus]   			
			NULL,                             -- [Priority]                 
			NULL,                             -- [WorkOrderStage]           
			NULL,                             -- [ManufacturerName]         
			NULL,                             -- [TechName]                 
			NULL,                             -- [EmployeeStation]          
			NULL,                             -- [PublicationNo]  			
			@SerialNumber,                    -- [SerialNumber]                
			@ItemMasterId,                    -- [MasterPartId]                
			@Notes,                           -- [Notes]                       
			@AircraftRegistryNumber,          -- [AircraftRegistryNumber]      
			1,                                -- [IsFromAircraft]              
			@AircraftInstalledPartDetailsId,  -- [AircraftInstalledPartDetailsId] 
			@AirCraftSerialNumber,            -- [AircraftSerialNumber]        
			@AircraftRegistryId,              -- [AircraftRegistryId]          
			@ProgramId                        -- [ProgramId]                   
        );

				        -- Call the target SP
        EXEC [dbo].[USP_UpdateWorkOrder]
            @WorkOrderId                = @WorkOrderId,
            @WorkOrderNum               = '',
            @IsSinglePN                 = 0,
            @WorkOrderTypeId            = @WorkOrderTypeId,
            @OpenDate                   = @OpenDate,
            @CustomerId                 = @CustomerId,
            @WorkOrderStatusId          = @WorkOrderStatusId,
            @EmployeeId                 = @EmployeeId,
            @MasterCompanyId            = @MasterCompanyId,
            @CreatedBy                  = @CreatedBy,
            @UpdatedBy                  = @CreatedBy,
            @CreatedDate                = @CreatedDate,
            @UpdatedDate                = @UpdatedDate,
            @IsActive                   = 1,
            @IsDeleted                  = 0,
            @SalesPersonId              = @SalesPersonId,
            @CSRId                      = @CSRId,
            @ReceivingCustomerWorkId    = @ReceivingCustomerWorkId,
            @Memo                       = @Memo,
            @Notes                      = @Notes,
            @CustomerContactId          = @CustomerContactId,
            @CustomerName               = @CustomerName,
            @CustomerType               = @CustomerType,
            @CreditLimit                = @CreditLimit,
            @CreditTerms                = @CreditTerms,
            @TearDownTypes              = @TearDownTypes,
            @RMAHeaderId                = @RMAHeaderId,
            @IsWarranty                 = @IsWarranty,
            @IsAccepted                 = @IsAccepted,
            @ReasonId                   = @ReasonId,
            @Reason                     = @Reason,
            @CreditTermId               = @CreditTermId,
            @IsManualForm               = @IsManualForm,
            @PercentId                  = @PercentId,
            @Days                       = @Days,
            @NetDays                    = @NetDays,
            @WorkOrderType              = @WorkOrderType,
            @FunctionalCurrencyId       = @FunctionalCurrencyId,
            @ReportCurrencyId           = @ReportCurrencyId,
            @ForeignExchangeRate        = @ForeignExchangeRate,
            @WorkOrderFormTypeId        = @WorkOrderFormTypeId,
            @IsWoAlwaysOrOndemandId     = @IsWoAlwaysOrOndemandId,
            @PartNumbers                = @PartNumbers,
            @StockLineId                = @StockLineId,
            @IsTraveler                 = 0,
            @AllowInvoiceBeforeShipping = 0,
            @MtcCategoryId              = @MtcCategoryId,
			@WorksheetId                = @WorksheetHeaderId,
            @tbl_WorkOrderPartNumberType = @tbl_WorkOrderPartNumberType;  

			SELECT @WorkOrderNum = WO.WorkOrderNum FROM [dbo].[WorkOrder] WO WITH(NOLOCK) WHERE WO.WorkOrderId = @WorkOrderId;

			UPDATE AMP
			SET
				AMP.WorkOrderNum = @WorkOrderNum,
				AMP.UpdatedBy    = @CreatedBy,
				AMP.UpdatedDate  = GETUTCDATE()
			FROM [dbo].[AircraftMaintenanceProgram] AMP
			WHERE AMP.ProgramId = @ProgramId
			  AND AMP.MasterCompanyId = @MasterCompanyId
			  AND ISNULL(AMP.WorkOrderNum, '') <> ISNULL(@WorkOrderNum, ''); 

			-- ══════════════════════════════════════════════════════
			-- HISTORY BLOCK
			-- Same pattern as USP_CreateWorkOrderFromAircraft
			-- ══════════════════════════════════════════════════════
			DECLARE @TemplateBody   VARCHAR(MAX)  = '',
					@Activity       VARCHAR(MAX)  = 'Existing WorkOrder Added',
					@HistCreatedBy  VARCHAR(256)  = @CreatedBy,
					@WorkOrderStr   VARCHAR(100)  = NULL;

			-- Get WO number for NewValue label
			SELECT @WorkOrderStr = 'WorkOrder Num.: ' + ISNULL(WorkOrderNum,'') FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId;

			-- NEW values after update
			DECLARE @New_PartNumber         VARCHAR(200)    = ISNULL(@PartNumber,''),
					@New_PartDescription    NVARCHAR(MAX)   = ISNULL(@PartDescription,''),
					@New_SerialNumber       VARCHAR(100)    = ISNULL(@SerialNumber,''),
					@New_ACTailNum          VARCHAR(500)    = ISNULL(@ACTailNum,''),
					@New_WorkOrderScopeId   VARCHAR(50)     = CAST(ISNULL(@WorkOrderScopeId,0) AS VARCHAR),
					@New_StockLineId        VARCHAR(50)     = CAST(ISNULL(@StockLineId,0) AS VARCHAR),
					@New_ProgramId          VARCHAR(50)     = CAST(ISNULL(@ProgramId,0) AS VARCHAR);

			-- Diff old vs new — only changed fields appended
			IF ISNULL(@Old_PartNumber,'')        <> @New_PartNumber        AND @New_PartNumber        <> ''
				SET @TemplateBody += 'Part Num.: '         + ISNULL(@Old_PartNumber,'')       + ' to ' + @New_PartNumber        + ' | ';

			IF ISNULL(@Old_PartDescription,'')   <> @New_PartDescription   AND @New_PartDescription   <> ''
				SET @TemplateBody += 'Part Desc.: '        + ISNULL(@Old_PartDescription,'')  + ' to ' + @New_PartDescription   + ' | ';

			IF ISNULL(@Old_SerialNumber,'')      <> @New_SerialNumber      AND @New_SerialNumber      <> ''
				SET @TemplateBody += 'Serial No.: '        + ISNULL(@Old_SerialNumber,'')     + ' to ' + @New_SerialNumber      + ' | ';

			IF ISNULL(@Old_ACTailNum,'')         <> @New_ACTailNum         AND @New_ACTailNum         <> ''
				SET @TemplateBody += 'AC Tail No.: '       + ISNULL(@Old_ACTailNum,'')        + ' to ' + @New_ACTailNum         + ' | ';

			IF ISNULL(@Old_WorkOrderScopeId,'0') <> @New_WorkOrderScopeId  AND @New_WorkOrderScopeId  <> '0'
				SET @TemplateBody += 'Work Scope: '        + ISNULL(@Old_WorkOrderScopeId,'') + ' to ' + @New_WorkOrderScopeId  + ' | ';

			SET @TemplateBody += 'Updated By: ' + ISNULL(@CreatedBy,'') + ' | ';
			SET @TemplateBody += 'Updated Date: ' + CONVERT(VARCHAR(30), GETUTCDATE(), 103);

			-- Remove trailing ' | ' safely without touching the value
			SET @TemplateBody = RTRIM(@TemplateBody);

			IF RIGHT(@TemplateBody, 3) = ' | '
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 3);
			ELSE IF RIGHT(@TemplateBody, 2) = ' |'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 2);
			ELSE IF RIGHT(@TemplateBody, 1) = '|'
				SET @TemplateBody = LEFT(@TemplateBody, LEN(@TemplateBody) - 1);

			-- Call usp_SaveAircraftHistory once
			IF ISNULL(LTRIM(RTRIM(@TemplateBody)), '') <> ''
			BEGIN
				EXEC [dbo].[USP_SaveAircraftHistory] @ModuleId = 2,@ModuleName = 'Aircraft WorkOrder',@RefferenceId = @AircraftRegistryId,@FieldsName = NULL,
											 @OldValue = NULL,@NewValue = @WorkOrderStr,@HistoryText = @TemplateBody,@Activity = @Activity,@MasterCompanyId = @MasterCompanyId,
											 @CreatedBy = @CreatedBy;
			END
			-- ── END HISTORY BLOCK ─────────────────────────────────

	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrderFromAircraft' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters    = @ProcedureParameters
                     , @ApplicationName        = @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END