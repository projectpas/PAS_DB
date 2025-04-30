/*************************************************************           
 ** File:   [USP_UpdateWorkOrder]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Update Work Order Quote
 ** Purpose:         
 ** Date:   24/03/2025      
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date          Author		Change Description            
 ** --   --------	   -------		--------------------------------          
    1    24/03/2025    Moin Bloch    Created
    2    14/04/2025    RAJESH GAMI   Implement the traverler Number logic    
	3    18/04/2025    Moin Bloch    Added For CREATING TRAVELER LABOUR HEADER
	4    30/04/2025    Rajesh Gami   Fix the RevisedItemMasterId, Desc and PartNumber related issue.
--   EXEC [USP_UpdateWorkOrder] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateWorkOrder]
@WorkOrderId BIGINT = NULL,
@WorkOrderNum VARCHAR(30) = NULL,
@IsSinglePN BIT = NULL,
@WorkOrderTypeId BIGINT = NULL,
@OpenDate DATETIME2(7) NULL,
@CustomerId BIGINT = NULL,
@WorkOrderStatusId BIGINT,
@EmployeeId BIGINT = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@UpdatedDate DATETIME2(7),
@IsActive BIT,
@IsDeleted BIT,
@SalesPersonId BIGINT = NULL,
@CSRId BIGINT = NULL,
@ReceivingCustomerWorkId BIGINT = NULL,
@Memo NVARCHAR(MAX) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@CustomerContactId BIGINT,
@CustomerName VARCHAR(100) = NULL,
@CustomerType VARCHAR(200) = NULL,
@CreditLimit DECIMAL(18,2) = NULL,
@CreditTerms VARCHAR(200) = NULL,
@TearDownTypes VARCHAR(300) = NULL,
@RMAHeaderId BIGINT = NULL,
@IsWarranty BIT = NULL,
@IsAccepted BIT = NULL,
@ReasonId BIGINT = NULL,
@Reason VARCHAR(500) = NULL,
@CreditTermId INT = NULL,
@IsManualForm BIT = NULL,
@PercentId BIGINT = NULL,
@Days INT = NULL,
@NetDays INT = NULL,
@WorkOrderType VARCHAR(50) = NULL,
@FunctionalCurrencyId INT = NULL,
@ReportCurrencyId INT = NULL,
@ForeignExchangeRate DECIMAL(18,2) = NULL,
@WorkOrderFormTypeId BIT = NULL,
@IsWoAlwaysOrOndemandId BIT = NULL, 
@PartNumbers NVARCHAR(MAX)=NULL,  -- Assuming you will pass the part numbers as JSON or CSV
@StockLineId INT=NULL,
@IsTraveler BIT=NULL,
@AllowInvoiceBeforeShipping BIT=NULL,
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
    -- Declare variables
	  DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
	  DECLARE @EmpExpCode VARCHAR(20)='TECHNICIAN',@EmployeeExpertiseId SMALLINT= NULL,@OldWorkFlowId BIGINT = NULL
	  DECLARE @ID BIGINT=NULL,@CreditTermsId INT=NULL,@WorkOrderScopeId BIGINT = NULL,@OldWorkScopeId BIGINT = NULL,@OldWorkScopeName VARCHAR(500)
	  DECLARE @OldWorkPriorityId BIGINT,@OldWorkPriorityName VARCHAR(100),@OldCMMName VARCHAR(MAX)='',@OldWorkFlowName VARCHAR(256)
	  DECLARE @WorkOrderPartNumberId BIGINT=0,@WorkOrderMPNManagementStructureModule INT,@WorkOrderModuleID INT,@WOMaterialsModuleID INT
	  DECLARE @NewWorkFlowName VARCHAR(256),@NewWorkFlowId BIGINT = NULL,@NewItemMasterId BIGINT=NULL,@WorkOrderPartId BIGINT=NULL
	  DECLARE @NewPartNumber VARCHAR(200)=NULL,@TemplateBody NVARCHAR(MAX)='',@NewCMMName VARCHAR(MAX)='',@NewWorkPriorityId BIGINT = NULL
	  DECLARE @NewWorkPriorityName VARCHAR(100),@NewWorkScopeName VARCHAR(500),@NewWorkScopeId BIGINT = NULL
	  DECLARE @CurrentNumber AS BIGINT,@TravelerCodeTypeId BIGINT = (SELECT  [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'TravelerId')
	  DECLARE @TravelerName AS varchar(100) = 0 , @ItemMasterId BIGINT =0;        
	SET @CreatedDate = GETUTCDATE();
    SET @UpdatedDate = GETUTCDATE();

	SELECT @WorkOrderMPNManagementStructureModule = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';

	SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';

	SELECT @WOMaterialsModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMaterials';
			
	IF OBJECT_ID(N'tempdb..#tmprCreateWorkOrderPartNumber') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCreateWorkOrderPartNumber
	END
	
	CREATE TABLE #tmprCreateWorkOrderPartNumber
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL,
		[WorkOrderId] [BIGINT] NULL,    
		[WorkOrderScopeId] [BIGINT] NULL,
		[EstimatedShipDate] [DATETIME2](7) NULL,
		[CustomerRequestDate] [DATETIME2](7) NULL,
		[PromisedDate] [DATETIME2](7) NULL,
		[EstimatedCompletionDate] [DATETIME2](7) NULL,
		[NTE] [VARCHAR](30),
		[Quantity] [INT] NULL,
		[StockLineId] [BIGINT] NULL,
		[CMMIds] [VARCHAR](256) NULL,
		[WorkflowId] [BIGINT] NULL,
		[WorkOrderStageId] [BIGINT] NULL,
		[WorkOrderStatusId] [BIGINT] NULL,
		[WorkOrderPriorityId] [BIGINT] NULL,
		[IsPMA] [BIT] NULL,
		[IsDER] [BIT] NULL,
		[TechStationId] [BIGINT] NULL,
		[TATDaysStandard] [INT] NULL,
		[MasterCompanyId] [INT] NULL,
		[CreatedBy] [VARCHAR](256) NULL,
		[UpdatedBy] [VARCHAR](256) NULL,
		[CreatedDate] [DATETIME2](7) NULL,
		[UpdatedDate] [DATETIME2](7) NULL,
		[IsActive] [BIT] NULL,
		[IsDeleted] [BIT] NULL,
		[ItemMasterId] [BIGINT] NULL,
		[TechnicianId] [BIGINT] NULL,  
		[ConditionId] [BIGINT] NULL,
		[TATDaysCurrent] [INT] NULL,
		[RevisedPartId] [BIGINT] NULL,
		[ManagementStructureId] [BIGINT] NULL,
		[IsMPNContract] [BIT] NULL,
		[ContractNo] [VARCHAR](20) NULL,
		[WorkScope] [VARCHAR](200) NULL,
		[isLocked] [BIT] NULL,
		[ReceivedDate] [DATETIME] NULL,
		[IsClosed] [BIT] NULL,
		[ACTailNum] [NVARCHAR](500) NULL,
		[ClosedDate] [DATETIME] NULL,
		[PDFPath] [NVARCHAR](MAX) NULL,
		[IsFinishGood] [BIT] NULL,
		[RevisedConditionId] [BIGINT] NULL,
		[CustomerReference] [VARCHAR](256) NULL,
		[Level1] [VARCHAR](200) NULL,
		[Level2] [VARCHAR](200) NULL,
		[Level3] [VARCHAR](200) NULL,
		[Level4] [VARCHAR](200) NULL,
		[AssignDate] [DATETIME2](7) NULL,
		[ReceivingCustomerWorkId] [BIGINT] NULL,
		[ExpertiseId] [SMALLINT] NULL,
		[RevisedItemmasterid] [BIGINT] NULL,
		[RevisedPartNumber] [VARCHAR](50) NULL,
		[RevisedPartDescription] [VARCHAR](MAX) NULL,
		[IsTraveler] [BIT] NULL,
		[AllowInvoiceBeforeShipping] [BIT] NULL,
		[WOFPrintDate] [DATETIME] NULL,
		[CurrentSerialNumber] [VARCHAR](100) NULL,
		[StocklineCost] [DECIMAL](18,2) NULL,
		[TendorStocklineCost] [DECIMAL](18,2) NULL,
		[RepairOrderId] [BIGINT] NULL,
		[RONumber] [VARCHAR](50) NULL,
		[RevisedSerialNumber] [VARCHAR](50) NULL,
		[IsROCreated] [BIT] NULL,
		[PartNumber] [VARCHAR](200) NULL,
		[PartDescription] [NVARCHAR](MAX) NULL,
		[WorkOrderStatus] [VARCHAR](MAX) NULL,
		[Priority] [VARCHAR](100) NULL,
		[WorkOrderStage] [VARCHAR](150) NULL,
		[ManufacturerName] [VARCHAR](250) NULL, 
		[TechName] [VARCHAR](100) NULL, 
		[EmployeeStation] [VARCHAR](100) NULL, 
		[PublicationNo] [VARCHAR](MAX) NULL,
		[SerialNumber] [VARCHAR](100) NULL,
		[MasterPartId] [BIGINT] NULL,
		[Isadd] [BIT] NULL
	)
			   	 
    -- Set CSRId and SalesPersonId to NULL if 0
    IF @CSRId = 0
        SET @CSRId = NULL;
    IF @SalesPersonId = 0
        SET @SalesPersonId = NULL;

    -- Fetch WorkOrderSettings based on parameters
    SELECT TOP 1 @TearDownTypes=[TearDownTypes],@IsManualForm = CASE WHEN [IsManualForm] IS NULL THEN 0 ELSE [IsManualForm] END,@IsTraveler = [IsTraveler],@AllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
			
	SELECT TOP 1 @EmployeeExpertiseId = [EmployeeExpertiseId] FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE [EmpExpCode] = @EmpExpCode AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

	INSERT INTO #tmprCreateWorkOrderPartNumber([ID],[WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId],[Isadd])
	SELECT [ID],@WorkOrderId,[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],@CreatedDate,@UpdatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId],0 FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber    

	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @WorkflowId BIGINT = NULL,@TechnicianId BIGINT = NULL,@TechStationId BIGINT = NULL,@RevisedPartId BIGINT = NULL
		DECLARE @CustomerRequestDate DATETIME2(7)=NULL,@PromisedDate DATETIME2(7)=NULL,@EstimatedCompletionDate DATETIME2(7)=NULL
		DECLARE @EstimatedShipDate DATETIME2(7)=NULL,@PartAllowInvoiceBeforeShipping BIT = NULL,@StocklineCost DECIMAL(18,2) = 0

		SELECT @ID = ISNULL([ID],0),
		       @WorkflowId = [WorkflowId],
			   @TechnicianId = [TechnicianId],
			   @TechStationId = [TechStationId],
			   @RevisedPartId = [RevisedPartId],
			   @CustomerRequestDate = [CustomerRequestDate],
			   @PromisedDate = [PromisedDate],
			   @EstimatedCompletionDate = [EstimatedCompletionDate],
			   @EstimatedShipDate = [EstimatedShipDate],
			   @PartAllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping],
			   @StockLineId = [StockLineId]
		FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId

		SELECT @StocklineCost = [UnitCost] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;
		
		UPDATE #tmprCreateWorkOrderPartNumber 
		   SET [WorkflowId] =  CASE WHEN @WorkflowId = 0 THEN NULL ELSE @WorkflowId END,
			   [TechnicianId] = CASE WHEN @TechnicianId = 0 THEN NULL ELSE @TechnicianId END,
			   [TechStationId] = CASE WHEN @TechStationId = 0 THEN NULL ELSE @TechStationId END,
			   [RevisedPartId] = CASE WHEN @RevisedPartId = 0 THEN NULL ELSE @RevisedPartId END,
			   [CustomerRequestDate] = @CustomerRequestDate AT TIME ZONE 'UTC',
			   [PromisedDate] = CASE WHEN @PromisedDate IS NOT NULL THEN @PromisedDate AT TIME ZONE 'UTC' ELSE @PromisedDate END,
			   [EstimatedCompletionDate] = CASE WHEN @EstimatedCompletionDate IS NOT NULL THEN @EstimatedCompletionDate AT TIME ZONE 'UTC' ELSE @EstimatedCompletionDate END,
			   [EstimatedShipDate] = CASE WHEN @EstimatedShipDate IS NOT NULL THEN @EstimatedShipDate AT TIME ZONE 'UTC' ELSE @EstimatedShipDate END,			   
			   [UpdatedBy] = @CreatedBy,			   
			   [UpdatedDate] = @UpdatedDate,
			   [AssignDate] =  CASE WHEN @TechnicianId > 0 THEN GETUTCDATE() ELSE NULL END,
			   [IsActive] = 1,
			   [IsDeleted] = 0,
			   [MasterCompanyId] = @MasterCompanyId			   
		 WHERE [PKID] = @MinId

		 IF(@ID = 0)
		 BEGIN
			UPDATE #tmprCreateWorkOrderPartNumber 
			   SET [ExpertiseId] =  CASE WHEN @EmployeeExpertiseId IS NOT NULL THEN @EmployeeExpertiseId ELSE [ExpertiseId] END,
			   	   [IsTraveler] = CASE WHEN  @IsTraveler IS NULL THEN 0 ELSE @IsTraveler END,
			       [AllowInvoiceBeforeShipping] = CASE WHEN @PartAllowInvoiceBeforeShipping IS NULL THEN @AllowInvoiceBeforeShipping ELSE @PartAllowInvoiceBeforeShipping END,	
				   [Isadd] = 1,
				   [StocklineCost] = CASE WHEN @StockLineId > 0 THEN @StocklineCost ELSE [StocklineCost] END
			 WHERE [PKID] = @MinId
		 END	
		   			 
		SET @MinId = @MinId + 1
	END

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber   
	WHILE @MinId <= @TotalRecord
	BEGIN	
		DECLARE @WOId BIGINT=0,@PartIsDeleted BIT = NULL,@WorkScopeDescription VARCHAR(500)=NULL,@PartReceivingCustomerWorkId BIGINT = NULL,@PartStockLineId BIGINT = NULL
		   				
		SELECT @ID = ISNULL([ID],0),
		       @PartReceivingCustomerWorkId = [ReceivingCustomerWorkId],
			   @WorkOrderScopeId = [WorkOrderScopeId],
			   @WOId = CASE WHEN [IsDeleted] = 0 THEN [WorkOrderId] ELSE 0 END,
			   @PartStockLineId = [StockLineId]
 		FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId	
		
		SELECT @WorkScopeDescription = [Description] FROM [dbo].[WorkScope] WITH(NOLOCK) WHERE [WorkScopeId] = @WorkOrderScopeId;

		UPDATE #tmprCreateWorkOrderPartNumber 
		   SET [WorkScope] = @WorkScopeDescription
		 WHERE [PKID] = @MinId

		IF(@PartReceivingCustomerWorkId > 0) 
		BEGIN
			-- Updating Work Order Id in Stockline Table		
			UPDATE [dbo].[StockLine]
			   SET [WorkOrderId] = @WOId,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy,
				   [WorkOrderPartNoId] = @ID
			 WHERE [StockLineId] = @PartStockLineId;

           -- Updating Work Order Id in Receiving Customer Table

			UPDATE [dbo].[ReceivingCustomerWork]
			   SET [WorkOrderId] = @WOId,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
             WHERE [ReceivingCustomerWorkId] = @PartReceivingCustomerWorkId
		END

		SET @MinId = @MinId + 1
	END	 
	
	SELECT @CreditTermsId = [CreditTermId] FROM [dbo].[WorkOrder] WHERE [WorkOrderId] = @WorkOrderId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
    
	SELECT TOP 1 @OldWorkScopeId = WP.[WorkOrderScopeId],	               
				 @OldWorkPriorityId = WP.[WorkOrderPriorityId],
				 @OldWorkFlowId = WP.[WorkflowId],
				 @OldWorkScopeName = WS.[Description],
				 @OldWorkPriorityName = PR.[Description],
				 @OldWorkFlowName = ISNULL(WF.[WorkOrderNumber],'')
		    FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) 
			LEFT JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON WP.[WorkOrderScopeId] = WS.[WorkScopeId]
			LEFT JOIN [dbo].[Priority] PR WITH(NOLOCK) ON WP.[WorkOrderPriorityId] = PR.[PriorityId]
			LEFT JOIN [dbo].[Workflow] WF WITH(NOLOCK) ON WP.[WorkflowId] = WF.[WorkflowId]
			WHERE WP.[WorkOrderId] = @WorkOrderId;

	EXEC [dbo].[USP_GetPublicationNameByWOId_OR_WOPartId] @WorkOrderId,0,@OldCMMName OUTPUT

	UPDATE [dbo].[WorkOrder]
	   SET [WorkOrderStatusId] = @WorkOrderStatusId
		  ,[UpdatedBy] = @UpdatedBy      
		  ,[UpdatedDate] = @UpdatedDate      
		  ,[SalesPersonId] = @SalesPersonId
		  ,[CSRId] = @CSRId
		  ,[Memo] = @Memo
		  ,[Notes] = @Notes
		  ,[CustomerContactId] = @CustomerContactId      
		  ,[CreditLimit] = @CreditLimit
		  ,[CreditTerms] = @CreditTerms                  
		  ,[CreditTermId] = @CreditTermId
		  ,[IsWarranty] = @IsWarranty
		  ,[IsAccepted] = @IsAccepted
		  ,[ReasonId] = @ReasonId
		  ,[Reason] = @Reason
		  ,[IsManualForm] = @IsManualForm
		  ,[PercentId] = @PercentId
		  ,[Days] = @Days
		  ,[NetDays] = @NetDays
		  ,[FunctionalCurrencyId] = @FunctionalCurrencyId
		  ,[ReportCurrencyId] = @ReportCurrencyId
		  ,[ForeignExchangeRate] = @ForeignExchangeRate
	 WHERE [WorkOrderId] = @WorkOrderId;

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber    

	WHILE @MinId <= @TotalRecord
	BEGIN
			SELECT @ID = ISNULL([ID],0),@ItemMasterId = ItemMasterId, @WorkOrderScopeId = WorkOrderScopeId  FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId
			IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ItemMasterId=@ItemMasterId and ISNULL(IsVersionIncrease,0)=0))            
			BEGIN            
				SELECT top 1 @TravelerName= CONVERT(varchar(250),ISNULL(TravelerId,'')) FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ItemMasterId=@ItemMasterId and ISNULL(IsVersionIncrease,0)=0            
			END            
			ELSE IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ISNULL(IsVersionIncrease,0)=0))            
			BEGIN            
				SELECT top 1 @TravelerName= CONVERT(varchar(250),ISNULL(TravelerId,'')) FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ISNULL(ItemMasterId,0)=0 and ISNULL(IsVersionIncrease,0)=0            
			END   

		IF(@ID > 0)
		BEGIN
			IF(@TravelerName = '' OR @TravelerName = '0')
			BEGIN
				SET @TravelerName = (SELECT ISNULL(TravelerNumber,'') FROM dbo.WorkOrderPartNumber WITH(NOLOCK) WHERE ID = @ID)
			END
			IF(@TravelerName = '')
			BEGIN
			/***** Prefixes : Reference Number*******/		   			
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixesWPN') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixesWPN
				END
	
				CREATE TABLE #tmpCodePrefixesWPN
				(
						ID BIGINT NOT NULL IDENTITY, 
						CodePrefixId BIGINT NULL,
						CodeTypeId BIGINT NULL,
						CurrentNumber BIGINT NULL,
						CodePrefix VARCHAR(50) NULL,
						CodeSufix VARCHAR(50) NULL,
						StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixesWPN (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId = @TravelerCodeTypeId
				AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
				IF (EXISTS (SELECT 1 FROM #tmpCodePrefixesWPN WHERE CodeTypeId = @TravelerCodeTypeId))
				BEGIN
					SET @CurrentNumber = (SELECT CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
					FROM #tmpCodePrefixesWPN WHERE CodeTypeId = @TravelerCodeTypeId)
					
					SET @TravelerName = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
									ISNULL(@CurrentNumber,0)+1,
									(SELECT CodePrefix FROM #tmpCodePrefixesWPN WHERE CodeTypeId = @TravelerCodeTypeId),
									(SELECT CodeSufix FROM #tmpCodePrefixesWPN WHERE CodeTypeId = @TravelerCodeTypeId)))
					UPDATE dbo.CodePrefixes SEt CurrentNummber = ISNULL(@CurrentNumber,0)+1 WHERE CodePrefixId = (SELECT TOP 1 CodePrefixId FROM #tmpCodePrefixesWPN)
				END
				/******End Prefixes******/	
			END

			UPDATE WOP
			   SET WOP.[WorkOrderScopeId] = WOPT.[WorkOrderScopeId]
				  ,WOP.[EstimatedShipDate] = WOPT.[EstimatedShipDate]
				  ,WOP.[CustomerRequestDate] = WOPT.[CustomerRequestDate]
				  ,WOP.[PromisedDate] = WOPT.[PromisedDate]
				  ,WOP.[EstimatedCompletionDate] = WOPT.[EstimatedCompletionDate]
				  ,WOP.[NTE] = WOPT.[NTE]				  
				  ,WOP.[StockLineId] = WOPT.[StockLineId]
				  ,WOP.[CMMIds] = WOPT.[CMMIds]
				  ,WOP.[WorkflowId] = WOPT.[WorkflowId]
				  ,WOP.[WorkOrderStageId] = WOPT.[WorkOrderStageId]
				  ,WOP.[WorkOrderStatusId] = WOPT.[WorkOrderStatusId]
				  ,WOP.[WorkOrderPriorityId] = WOPT.[WorkOrderPriorityId]				  
				  ,WOP.[TechStationId] = WOPT.[TechStationId]
				  ,WOP.[TATDaysStandard] = WOPT.[TATDaysStandard]		  
				  ,WOP.[UpdatedBy] = @UpdatedBy		 
				  ,WOP.[UpdatedDate] = @UpdatedDate		  
				  ,WOP.[IsDeleted] = WOPT.[IsDeleted]				  
				  ,WOP.[TechnicianId] = WOPT.[TechnicianId]
				  ,WOP.[ConditionId] = WOPT.[ConditionId]
				  ,WOP.[TATDaysCurrent] = WOPT.[TATDaysCurrent]
				  ,WOP.[RevisedPartId] = WOPT.[RevisedPartId]
				  ,WOP.[IsMPNContract] = WOPT.[IsMPNContract]
				  ,WOP.[ContractNo] = WOPT.[ContractNo]
				  ,WOP.[WorkScope] = WOPT.[WorkScope]
				  ,WOP.[isLocked] = WOPT.[isLocked]
				  ,WOP.[ReceivedDate] = WOPT.[ReceivedDate]
				  ,WOP.[IsClosed] = WOPT.[IsClosed]
				  ,WOP.[ACTailNum] = WOPT.[ACTailNum]
				  ,WOP.[ClosedDate] = WOPT.[ClosedDate]		  
				  ,WOP.[IsFinishGood] = WOPT.[IsFinishGood]
				  ,WOP.[RevisedConditionId] = WOPT.[RevisedConditionId]
				  ,WOP.[CustomerReference] = WOPT.[CustomerReference]				  
				  ,WOP.[AssignDate] = WOPT.[AssignDate]
				  ,WOP.[ReceivingCustomerWorkId] = WOPT.[ReceivingCustomerWorkId]
				  ,WOP.[ExpertiseId] = WOPT.[ExpertiseId]
				  ,WOP.[RevisedItemmasterid] = CASE WHEN ISNULL(WOPT.[RevisedItemmasterid],0) = 0 THEN Im.ItemMasterId ELSE WOPT.[RevisedItemmasterid] END
				  ,WOP.[RevisedPartNumber] = CASE WHEN ISNULL(WOPT.[RevisedItemmasterid],0) = 0 THEN Im.partNumber ELSE WOPT.[RevisedPartNumber] END
				  ,WOP.[RevisedPartDescription] = CASE WHEN ISNULL(WOPT.[RevisedItemmasterid],0) = 0 THEN Im.PartDescription ELSE  WOPT.[RevisedPartDescription] END
				  ,WOP.[IsTraveler] = WOPT.[IsTraveler]
				  ,WOP.[AllowInvoiceBeforeShipping] = WOPT.[AllowInvoiceBeforeShipping]
				  ,WOP.[WOFPrintDate] = WOPT.[WOFPrintDate]
				  ,WOP.[CurrentSerialNumber] = WOPT.[CurrentSerialNumber]
				  ,WOP.[StocklineCost] = WOPT.[StocklineCost]
				  ,WOP.[TendorStocklineCost] = WOPT.[TendorStocklineCost]
				  ,WOP.[RepairOrderId] = WOPT.[RepairOrderId]
				  ,WOP.[RONumber] = WOPT.[RONumber]
				  ,WOP.[RevisedSerialNumber] = WOPT.[RevisedSerialNumber]
				  ,WOP.[IsROCreated] = WOPT.[IsROCreated]				  
				  ,WOP.[WorkOrderStatus] = WOPT.[WorkOrderStatus]
				  ,WOP.[Priority] = WOPT.[Priority]
				  ,WOP.[WorkOrderStage] = WOPT.[WorkOrderStage]
				  ,WOP.[ManufacturerName] = WOPT.[ManufacturerName]
				  ,WOP.[TechName] = WOPT.[TechName]
				  ,WOP.[EmployeeStation] = WOPT.[EmployeeStation]
				  ,WOP.[PublicationNo] = WOPT.[PublicationNo]
				  ,WOP.TravelerNumber = @TravelerName
			FROM [dbo].[WorkOrderPartNumber] WOP  WITH(NOLOCK)    
			INNER JOIN dbo.ItemMaster Im WITH(NOLOCK)     ON WOP.ItemMasterId = Im.ItemMasterId
			INNER JOIN #tmprCreateWorkOrderPartNumber WOPT ON WOPT.ID = WOP.ID  
			WHERE WOPT.[PKID] = @MinId		
		END
		ELSE
		BEGIN
			IF((@IsSinglePN = 1 AND (@TravelerName = '' OR @TravelerName = '0')) OR @IsSinglePN = 0)
			BEGIN
				/***** Prefixes : Reference Number*******/		   			
				IF OBJECT_ID(N'tempdb..#tmpCodePrefixesWPNUInsert') IS NOT NULL
				BEGIN
					DROP TABLE #tmpCodePrefixesWPNUInsert
				END
	
				CREATE TABLE #tmpCodePrefixesWPNUInsert
				(
						ID BIGINT NOT NULL IDENTITY, 
						CodePrefixId BIGINT NULL,
						CodeTypeId BIGINT NULL,
						CurrentNumber BIGINT NULL,
						CodePrefix VARCHAR(50) NULL,
						CodeSufix VARCHAR(50) NULL,
						StartsFrom BIGINT NULL,
				)

				INSERT INTO #tmpCodePrefixesWPNUInsert (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
				SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
				FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
				WHERE CT.CodeTypeId = @TravelerCodeTypeId
				AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
				IF (EXISTS (SELECT 1 FROM #tmpCodePrefixesWPNUInsert WHERE CodeTypeId = @TravelerCodeTypeId))
				BEGIN
					SET @CurrentNumber = (SELECT CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
					FROM #tmpCodePrefixesWPNUInsert WHERE CodeTypeId = @TravelerCodeTypeId)
					
					SET @TravelerName = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
									ISNULL(@CurrentNumber,0)+1,
									(SELECT CodePrefix FROM #tmpCodePrefixesWPNUInsert WHERE CodeTypeId = @TravelerCodeTypeId),
									(SELECT CodeSufix FROM #tmpCodePrefixesWPNUInsert WHERE CodeTypeId = @TravelerCodeTypeId)))
					UPDATE dbo.CodePrefixes SEt CurrentNummber = ISNULL(@CurrentNumber,0)+1 WHERE CodePrefixId = (SELECT TOP 1 CodePrefixId FROM #tmpCodePrefixesWPNUInsert)
				END
				/******End Prefixes******/	

			END

			INSERT INTO [dbo].[WorkOrderPartNumber]([WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
					[StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],
					[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],
					[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],
					[Level1],[Level2],[Level3],[Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],
					[AllowInvoiceBeforeShipping],[WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],
					[PartNumber],[PartDescription],[WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],TravelerNumber)
			 SELECT [WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
					[StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],
					[CreatedBy],[UpdatedBy],@CreatedDate,@UpdatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],
					[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],
					[Level1],[Level2],[Level3],[Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],ItemMasterId,[PartNumber],[PartDescription],[IsTraveler],
					[AllowInvoiceBeforeShipping],[WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],
					[PartNumber],[PartDescription],[WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],@TravelerName
			   FROM #tmprCreateWorkOrderPartNumber 
			  WHERE [PKID] = @MinId

			SET @ID = SCOPE_IDENTITY();	

			UPDATE #tmprCreateWorkOrderPartNumber SET [ID] = @ID WHERE [PKID] = @MinId
		END
		
		SET @MinId = @MinId + 1
	END

	DECLARE @WorkOrderParts WorkOrderPartNumberType;

	INSERT INTO @WorkOrderParts([ID],[WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId])
	SELECT [ID],@WorkOrderId,[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],@CreatedDate,@UpdatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId] FROM #tmprCreateWorkOrderPartNumber
	 WHERE [IsDeleted] = 0
		   		   
	-- CREATING WORKFLOWWORKORDER FROM WORK FLOW
	EXEC [dbo].[CreateWorkFlowWorkOrderFromWorkFlow] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,@MasterCompanyId;
		
	-- CREATING WORK ORDER SETTLEMENTDETAILS
	EXEC [dbo].[CreateWorkOrderSettlementDetails] @WorkOrderParts,@WorkOrderId,@WorkOrderTypeId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	-- CREATING WORK ORDER TEARDOWN FO REMOVAL REASON
	EXEC [dbo].[CreateCommonWorkOrderRemovalTearDown] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,@MasterCompanyId;

	-- COMPANY NOT AVAIALABLE WITH MASTERCOMPANYCODE LIKE 'AIR'
	-- CreateCommonWorkOrderCustomerInspecionTearDown(workOrder.PartNumbers, workOrder.WorkOrderId, workOrder.CreatedBy);
			   
	-- UPDATING WORK ORDER FIELDS NAMES
	EXEC [dbo].[UpdateWorkOrderColumnsWithId] @WorkOrderId;

	-- CREATING TRAVELER LABOUR HEADER
	EXEC [dbo].[USP_CreateWorkOrderLaborHeader] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	-- CREATING TRAVELER LABOUR TASK
	EXEC [dbo].[CreateTravelerLabourTask] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@MasterCompanyId;
	   	  
	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber    

	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @Isadd BIT = 0,@ManagementStructureId BIGINT=NULL,@MSDetailsId BIGINT=NULL
		SET @ReceivingCustomerWorkId = 0

		SELECT @WorkOrderPartNumberId = [ID],
		       @Isadd = [Isadd],
			   @ManagementStructureId = [ManagementStructureId],
			   @ReceivingCustomerWorkId = [ReceivingCustomerWorkId],
			   @StockLineId = [StockLineId]
		 FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId

		-- UPDATE NAME FIELDS FROM ID
		EXEC [dbo].[UpdateWorkOrderPartNumberColumnsWithId] @WorkOrderPartNumberId;

		IF(@Isadd = 1)
		BEGIN			
			EXEC [dbo].[USP_SaveWOMSDetails] @WorkOrderMPNManagementStructureModule,@WorkOrderPartNumberId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, @MSDetailsId OUTPUT
		END
		ELSE
		BEGIN
			EXEC [dbo].[USP_UpdateWOMSDetails] @WorkOrderMPNManagementStructureModule, @WorkOrderPartNumberId, @ManagementStructureId, @UpdatedBy
		END
		IF(@ReceivingCustomerWorkId > 0)
		BEGIN
			DECLARE @QuantityAvailable INT=0,@Quantity INT=0,@IsSerialized BIT=0

			SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),
			       @Quantity = ISNULL([Quantity],0),
				   @IsSerialized = ISNULL([IsSerialized],0) 
			 FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

			 IF(@IsSerialized = 0 AND (@QuantityAvailable > 1 OR @Quantity > 1))
			 BEGIN
				EXEC [dbo].[USP_CreateChildStockline] @StockLineId, @MasterCompanyId, @WorkOrderModuleID, @WorkOrderId, 1, 1, 0, 0, 0, @WOMaterialsModuleID, 0, 0, 0, 0
			 END
			 ELSE
			 BEGIN
				EXEC [dbo].[USP_CreateChildStockline] @StockLineId, @MasterCompanyId, @WorkOrderModuleID, @WorkOrderId, 0, 0, 0, 0, 1, @WOMaterialsModuleID, 0, 0, 0, 0
			 END		
		END
		
		SET @MinId = @MinId + 1
	END
	
	SELECT TOP 1 @NewWorkFlowId = WP.[WorkflowId],
	             @NewItemMasterId = WP.[ItemMasterId],
				 @WorkOrderPartId = WP.[ID],
				 @NewPartNumber = ISNULL(IM.[PartNumber],''),
				 @NewWorkFlowName = ISNULL(WF.[WorkOrderNumber],''),
				 @NewWorkPriorityId = WP.[WorkOrderPriorityId],
				 @NewWorkPriorityName = PR.[Description],
				 @NewWorkScopeId = WP.[WorkOrderScopeId],
				 @NewWorkScopeName = WS.[Description]
		   FROM [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) 
	  LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WP.[ItemMasterId] = IM.[ItemMasterId]
	  LEFT JOIN [dbo].[Workflow] WF WITH(NOLOCK) ON WP.[WorkflowId] = WF.[WorkflowId]
	  LEFT JOIN [dbo].[Priority] PR WITH(NOLOCK) ON WP.[WorkOrderPriorityId] = PR.[PriorityId]
	  LEFT JOIN [dbo].[WorkScope] WS WITH(NOLOCK) ON WP.[WorkOrderScopeId] = WS.[WorkScopeId]
	  WHERE WP.[WorkOrderId] = @WorkOrderId;
		  
	IF(@OldWorkFlowId <> @NewWorkFlowId)
	BEGIN
		IF(@OldWorkFlowId IS NOT NULL)
		BEGIN
			DECLARE @UpdateWorkFlow VARCHAR(20) = 'UpdateWorkFlow';

			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @UpdateWorkFlow;

			SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @NewPartNumber)
			SET @TemplateBody = REPLACE(@TemplateBody, '##OldWorkFlow##', @OldWorkFlowName)
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewWorkFlow##', @NewWorkFlowName)

			EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartId,@OldWorkFlowName,@NewWorkFlowName,@TemplateBody,@UpdateWorkFlow,@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate
		END
		ELSE
		BEGIN			
			DECLARE @AddWorkFlow VARCHAR(20) = 'AddWorkFlow';

			SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @AddWorkFlow;

			SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @NewPartNumber)
			SET @TemplateBody = REPLACE(@TemplateBody, '##NewWorkFlow##', @NewWorkFlowName)

			EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartId,'',@NewWorkFlowName,@TemplateBody,@AddWorkFlow,@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate
		END
	END
	
	EXEC [dbo].[USP_GetPublicationNameByWOId_OR_WOPartId] @WorkOrderId,0,@NewCMMName OUTPUT

	IF(@OldCMMName <> @NewCMMName)
	BEGIN
		DECLARE @UpdateWOPublication VARCHAR(30) = 'UpdateWorkOrderPublication';
		
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @UpdateWOPublication;

		SET @OldCMMName = ISNULL(@OldCMMName,'');
		SET @NewCMMName = ISNULL(@NewCMMName,'');

		SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @NewPartNumber)
		SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', @OldCMMName)
		SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', @NewCMMName)

		EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartId,@OldCMMName,@NewCMMName,@TemplateBody,@UpdateWOPublication,@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate
		
	END
	IF(@OldWorkPriorityId <> @NewWorkPriorityId)
	BEGIN		
		DECLARE @UpdateWOPriority VARCHAR(30) = 'UpdateWorkOrderPriority';
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @UpdateWOPriority;

		SET @OldWorkPriorityName = ISNULL(@OldWorkPriorityName,'');
		SET @NewWorkPriorityName = ISNULL(@NewWorkPriorityName,'');

		SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @NewPartNumber)
		SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', @OldWorkPriorityName)
		SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', @NewWorkPriorityName)

		EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartId,@OldWorkPriorityName,@NewWorkPriorityName,@TemplateBody,@UpdateWOPriority,@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate

	END
	IF(@OldWorkScopeId <> @NewWorkScopeId)
	BEGIN		
		DECLARE @UpdateWOScope VARCHAR(20) = 'UpdateWorkScope';
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @UpdateWOScope;

		SET @OldWorkScopeName = ISNULL(@OldWorkScopeName,'');
		SET @NewWorkScopeName = ISNULL(@NewWorkScopeName,'');

		SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', @NewPartNumber)
		SET @TemplateBody = REPLACE(@TemplateBody, '##OldValue##', @OldWorkPriorityName)
		SET @TemplateBody = REPLACE(@TemplateBody, '##NewValue##', @NewWorkScopeName)

		EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartId,@OldWorkScopeName,@NewWorkScopeName,@TemplateBody,@UpdateWOScope,@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate

	END

	SELECT @WorkOrderId AS [WorkOrderId]

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateWorkOrder' 
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