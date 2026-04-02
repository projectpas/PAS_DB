/*************************************************************           
 ** File:  [GetWorkOrderById]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to Get Work Order Details     
 ** Date:   26/02/2025              
 ** PARAMETERS: @WorkOrderId bigint,@ReceivingCustomerId bigint,@RMAHeaderId bigint,@StockLineId bigint     
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    26/02/2025   Moin Bloch    Created
	2    12/03/2025   Moin Bloch    Fixed Multiple MPN Issue
	3    09/05/2025	  Abhishek Jirawla Add Repair Management
	4    13/05/2025	  Abhishek Jirawla Isue with create work order with stockline
	5    04/06/2025	  Devendra Shekh   added stockLineUnitCost to PartNumbers
	6    10/06/2025	  Devendra Shekh   added @AllowPrintReleaseForm
	7    01/07/2025	  Devendra Shekh   added New Field : MPNPartNumber
	8    03/07/2025   Moin Bloch       Changed Old To New Billing Table
	9    26/08/2025   Moin Bloch	   added RevisedSerialNumber 
	10   24/09/2025   Rajesh Gami	   added MPN Notes   
	11   25/09/2025   Vishal Suthar	   Fixed populating WorkFlowId based on customerId as well
	12   14/11/2025   Sahdev Saliya    Added New Field : RevisedCondition
	13	 30/01/2026   Moin Bloch       Added IncomingPartNumber
	14	 24-FEB-2026  Moin Bloch 	   Added OutGoingItemMasterId And OutGoingPartNumber PN-15427
	15   09/03/2026   Moin Bloch	   Added OutGoingPartDescription PN-15681
	16   23-MAR-2026  Ayushi Patel     PN-15825 added lineNum
	17   27/03/2026   Moin Bloch	   Rename Internal To Internal Repair   PN-15850

--    EXEC [dbo].[GetWorkOrderById] 0,5714,0,0,1
--    EXEC [dbo].[GetWorkOrderById] 0,0,29,0,2  
--    EXEC [dbo].[GetWorkOrderById] 8927,0,0,0,4

************************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderById]
@WorkOrderId BIGINT=0,
@ReceivingCustomerId BIGINT=0,
@RMAHeaderId BIGINT=0,
@StockLineId BIGINT=0,
@Opr INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	IF OBJECT_ID(N'tempdb..#TempTableForPartType') IS NOT NULL
	BEGIN
		DROP TABLE #TempTableForPartType
	END
		
	CREATE TABLE #TempTableForPartType
	(			 
		[PartType] VARCHAR(100)
	)

	IF OBJECT_ID(N'tempdb..#TempTableForPartsDetailsWO') IS NOT NULL
	BEGIN
		DROP TABLE #TempTableForPartsDetailsWO
	END

	CREATE TABLE #TempTableForPartsDetailsWO
	(		
		[ID] BIGINT NOT NULL IDENTITY, 
		[ReceivingCustomerWorkId] BIGINT NULL,
		[Partnumber] VARCHAR(50) NULL,
		[PartDescription] NVARCHAR(MAX) NULL,
		[RevisedPartNo] VARCHAR(250) NULL,
		[Condition] VARCHAR(256) NULL,
		[ConditionId] BIGINT NULL,
		[StockLineNumber] VARCHAR(50) NULL,  
		[StockLineId] BIGINT NULL,
		[SerialNumber] VARCHAR(100) NULL,  
		[Reference] VARCHAR(256) NULL,
		[ReceivedDate] DATETIME2(7) NULL,
		[ManagementStructureId] BIGINT NULL,
		[CustReqDate] DATETIME2(7) NULL,
		[Quantity] INT NULL,
		[ItemMasterId] BIGINT NULL,
		[ItemGroup] VARCHAR(30) NULL,
		[WorkOrderScopeId] BIGINT NULL,
		[NTE] INT NULL,
		[IsPMA] BIT NULL,
		[IsDER] BIT NULL,
		[ACTailNum] NVARCHAR(1000) NULL,
		[SiteId] BIGINT NULL,
		[Site]  VARCHAR(100) NULL, 
		[Warehouse] VARCHAR(100) NULL, 
		[Location] VARCHAR(100) NULL, 
		[Shelf] VARCHAR(100) NULL, 
		[Bin] VARCHAR(100) NULL, 
		[IsFinishedGood] BIT NULL, 
		[LastMSLevel] VARCHAR(100) NULL, 
		[AllMSlevels] VARCHAR(MAX) NULL,
		[WorkOrderPriorityId] BIGINT NULL,
		[WorkOrderStageId] BIGINT NULL,
		[DefaultWorkOrderStatusId] BIGINT NULL,
		[WorkFlowNo] VARCHAR(256) NULL,
		[WorkFlowId] BIGINT NULL,
		[WorkflowExpirationDate] DATETIME2(7) NULL,
		[IsRepairManagement] BIT NULL,
		[StockLineUnitCost] DECIMAL(18, 2) NULL,
		[MPNPartNumber] VARCHAR(400) NULL,
		[Notes] NVARCHAR(MAX) NULL,
	)

    DECLARE @CustomerId BIGINT=0,@CustomerContactId BIGINT=0,@ReceivingCustomerWorkId BIGINT=0,@ItemMasterId BIGINT=0,@ConditionId BIGINT=0,@RecStockLineId BIGINT=0,@WorkScopeId BIGINT=0,@CsrId BIGINT=0,@EmployeeId BIGINT=0
	DECLARE @PrimarySalesPersonId BIGINT=0,@CustomerFinancialId BIGINT=0,@ContactContactId BIGINT=NULL,@DefaultPriorityId BIGINT=0,@DefaultStageCodeId BIGINT=0,@DefaultStatusId BIGINT=0,@EmployeeName VARCHAR(50)=NULL
	DECLARE @MasterCompanyId INT=0,@CustomerAffiliationId INT=0,@CustAffiliationId INT=0,@CreditTermsId INT=0,@CurrencyId INT=0,@WorkOrderStatusId INT=0,@WorkOrderTypeId INT=0,@ModuleEnumCustomer INT=1,@MSModuleEnumRecevingCustomer INT=1,@MSModuleStockline INT=2
	DECLARE @Reference VARCHAR(256)='',@RCReference VARCHAR(256)='',@ReceivingNumber VARCHAR(50)='',@CustomerPhoneNo VARCHAR(50)=NULL,@CustomerEmail VARCHAR(50)=NULL,@Condition VARCHAR(256)=NULL,@RevisedCondition VARCHAR(256)=NULL,@StockLineNumber VARCHAR(50)=NULL,@StockLineUnitCost DECIMAL(18, 2)=NULL
	DECLARE @Memo VARCHAR(MAX)='',@PartDescription NVARCHAR(MAX)='',@Partnumber VARCHAR(50)='',@ManufacturerName VARCHAR(250)='',@RevisedPartNo VARCHAR(250)=NULL
	DECLARE @SerialNumber VARCHAR(100)='',@CustName VARCHAR(100)='',@ContractReference VARCHAR(100)='',@Email VARCHAR(200)='',@CustomerPhone VARCHAR(20)='',@CSRName VARCHAR(100)='',@CreditTermName VARCHAR(20)=NULL,@CustomerContact VARCHAR(200)=NULL
	DECLARE @CreditLimit DECIMAL(18,2)=0,@AnnualRevenuePotential DECIMAL(16,2)=0,@ARBalance DECIMAL(18,2)=0,@SalesPersonName VARCHAR(100)='',@MPNPartNumber VARCHAR(400)=''
	DECLARE @PMACOUNT INT=0,@DERCOUNT INT =0,@ReceivedDate datetime2(7)=NULL,@ManagementStructureId BIGINT = 0,@CustReqDate datetime2(7)=NULL,@Quantity INT = 0
    DECLARE @ItemGroup VARCHAR(30)='',@WorkOrderScopeId BIGINT = NULL,@NTE INT = 0,@IsPMA BIT = 0,@IsDER BIT = 0,@ACTailNum NVARCHAR(1000)=''
    DECLARE @SiteId BIGINT = 0,@Site  VARCHAR(100)='',@Warehouse VARCHAR(100)='',@Location VARCHAR(100)='',@Shelf VARCHAR(100)='',@Bin VARCHAR(100)=''
    DECLARE @IsFinishedGood BIT = 0,@LastMSLevel VARCHAR(100)='',@AllMSlevels VARCHAR(MAX)='',@WorkFlowNo NVARCHAR(500)='',@WorkflowId BIGINT=0,@WorkflowExpirationDate DATETIME2(7)=NULL
	DECLARE @IsSinglePN BIT = 1,@WorkOrderMPNMSModuleEnum INT=12 
	DECLARE @IsRepairManagement BIT = 0
	DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
	DECLARE @OutGoingPartNumber VARCHAR(50)='',@OutGoingItemMasterId BIGINT=0,@IncomingPartNumber VARCHAR(50)='',@OutGoingPartDescription NVARCHAR(MAX)=''
	SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
	SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
	SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
	
	-- For ReceivingCustomer
	IF(@Opr=1)
	BEGIN	
		SELECT @CustomerId = RC.[CustomerId],@MasterCompanyId = RC.[MasterCompanyId],@Reference = RC.[Reference],@Memo = RC.[Memo],@CustomerContactId = RC.[CustomerContactId],
		       @ReceivingCustomerWorkId = RC.[ReceivingCustomerWorkId],@ItemMasterId = RC.[ItemMasterId],
			   @ConditionId = RC.[ConditionId],@RecStockLineId = RC.[StockLineId],@ReceivingNumber = RC.[ReceivingNumber],@WorkScopeId = RC.[WorkScopeId],
			   @OutGoingItemMasterId = RC.[OutGoingItemMasterId],@OutGoingPartNumber = RC.[OutGoingPartNumber],@IncomingPartNumber = RC.[PartNumber],@OutGoingPartDescription = IM.[PartDescription]
		  FROM [dbo].[ReceivingCustomerWork] RC WITH(NOLOCK)
		  LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON RC.[OutGoingItemMasterId] = IM.[ItemMasterId]
		  WHERE RC.[ReceivingCustomerWorkId] = @ReceivingCustomerId;
		
		SELECT @CustName=[Name],@CustomerAffiliationId=[CustomerAffiliationId],@ContractReference=[ContractReference],@Email=[Email],@CustomerPhone=[CustomerPhone] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT TOP 1 @CustomerFinancialId=[CustomerFinancialId],@CreditLimit=[CreditLimit],@CreditTermsId=[CreditTermsId],@CurrencyId=[CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;
				  
		SELECT TOP 1 @AnnualRevenuePotential=[AnnualRevenuePotential],@CsrId =[CsrId],@PrimarySalesPersonId = [PrimarySalesPersonId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;
					
		SELECT @WorkOrderStatusId=[Id] FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE [Description] = 'Open';

		SELECT @CustAffiliationId = [CustomerAffiliationId] FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) WHERE [Description]='Internal';

		SELECT @ContactContactId=con.[ContactId],@CustomerContact = con.FirstName + ' ' + con.LastName,@CustomerPhoneNo = con.WorkPhone + ' ' + con.WorkPhoneExtn 
		FROM [dbo].[CustomerContact] cc WITH(NOLOCK)
		INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.ContactId = con.ContactId 
		WHERE cc.CustomerContactId = @CustomerContactId;						

		IF(@CsrId > 0)
		BEGIN
			SELECT @CSRName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CsrId;
		END

		IF(@PrimarySalesPersonId > 0)
		BEGIN
			SELECT @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @PrimarySalesPersonId;
		END

		IF(@CustomerAffiliationId = @CustAffiliationId)
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';
		END
		ELSE
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
		END

		IF(@CustomerFinancialId > 0 AND @CreditTermsId > 0)
		BEGIN			
			SELECT @CreditTermName = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId;
		END
		
		SELECT TOP 1 @ARBalance = ISNULL(ARBalance,0) FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId ORDER BY [CustomerCreditTermsHistoryId] DESC;

		SELECT TOP 1 @DefaultPriorityId = [DefaultPriorityId],@DefaultStageCodeId = [DefaultStageCodeId],@DefaultStatusId = [DefaultStatusId] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

		INSERT INTO #TempTableForPartType([PartType])
		SELECT rp.[PartType] FROM [dbo].[ReceivingCustomerWork] rc WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.ItemMasterId = im.ItemMasterId
			INNER JOIN [dbo].[RestrictedParts] rp WITH(NOLOCK) ON rc.CustomerId = rp.ReferenceId
			WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rp.[ModuleId] = @ModuleEnumCustomer AND rc.[ReceivingCustomerWorkId] = @ReceivingCustomerId 
			AND rc.[ItemMasterId] = rp.ItemMasterId AND rp.[IsActive] = 1 AND rp.[IsDeleted] = 0;

		SELECT @PMACOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'PMA';
		SELECT @DERCOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'DER';
							   			 
		SELECT @Partnumber = im.[PartNumber],
			   @ManufacturerName = im.[ManufacturerName],
			   @PartDescription = CASE WHEN @OutGoingPartDescription IS NULL OR @OutGoingPartDescription = '' THEN im.[PartDescription] ELSE @OutGoingPartDescription END,
			   @RevisedPartNo = im.[RevisedPart],
			   @Condition = cn.[Description], 
			   @StockLineNumber = sl.[StockLineNumber],
			   @SerialNumber = rc.[SerialNumber],
			   --@Reference = rc.[Reference],
			   @ReceivedDate = rc.[ReceivedDate],			
			   @ManagementStructureId = rc.[ManagementStructureId],
			   @CustReqDate = rc.[CustReqDate],
			   @Quantity = rc.[Quantity],			   
			   @ItemGroup = COALESCE(ig.[ItemGroupCode], ''),
			   @WorkOrderScopeId = rc.[WorkScopeId],
			   @NTE = (im.[OverhaulHours] + CAST(im.[mfgHours] AS INT) + im.[RPHours] + im.[TestHours]),
			   @IsPMA = CASE WHEN @PMACOUNT > 0 THEN 0 ELSE c.[RestrictPMA] END,
			   @IsDER = CASE WHEN @DERCOUNT > 0 THEN 0 ELSE c.[RestrictDER] END,	
			   @ACTailNum = rc.[ACTailNum],			
			   @SiteId = sl.[SiteId],
			   @Site = sl.[Site],
			   @Warehouse = sl.[Warehouse],
			   @Location =sl.[Location],
			   @Shelf = sl.[Shelf],
			   @Bin = sl.[Bin],
			   @IsFinishedGood = 0,			
			   @LastMSLevel = COALESCE(msd.[LastMSLevel], ''),
			   @AllMSlevels = COALESCE(msd.[AllMSlevels], ''),
			   @IsRepairManagement = ISNULL(sl.IsRepairManagement, 0),
			   @StockLineUnitCost = ISNULL(sl.UnitCost, 0),
			   @MPNPartNumber = CONCAT(@OutGoingPartNumber, CASE	WHEN COALESCE(@SerialNumber, '') <> '' THEN ' - ' + @SerialNumber
															WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
															ELSE '' END)
		  FROM [dbo].[ReceivingCustomerWork] rc WITH(NOLOCK)
		INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON rc.[StockLineId] = sl.[StockLineId]
		INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.[ItemMasterId] = im.[ItemMasterId]
		INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON rc.[CustomerId] = c.[CustomerId]
		INNER JOIN [dbo].[Condition] cn WITH(NOLOCK) ON rc.[ConditionId] = cn.[ConditionId]
		 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
		 LEFT JOIN [dbo].[WorkOrderManagementStructureDetails] msd WITH(NOLOCK) ON rc.[ReceivingCustomerWorkId] = msd.[ReferenceID] AND msd.[ModuleID] = @MSModuleEnumRecevingCustomer
		WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rc.[ReceivingCustomerWorkId] = @ReceivingCustomerId;

		--EXEC [dbo].[VerifiedItemMasterCapsByItemMasterAndWorkScope] @ItemMasterId,@WorkScopeId,@ManagementStructureId,@MasterCompanyId;

		SELECT TOP 1 @WorkFlowNo = CONCAT(wf.[WorkOrderNumber], '_', wf.[Version]),
		             @WorkflowId = wf.[WorkflowId],
					 @WorkflowExpirationDate = wf.[WorkflowExpirationDate]
		FROM [dbo].[Workflow] wf  WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON wf.[ItemMasterId] = im.[ItemMasterId]
		INNER JOIN [dbo].[WorkScope] ws  WITH(NOLOCK) ON wf.[WorkScopeId] = ws.[WorkScopeId]
		WHERE wf.[IsDeleted] = 0 AND wf.[IsActive] = 1 AND wf.[ItemMasterId] = @ItemMasterId 
		AND (wf.CustomerId IS NULL OR wf.CustomerId = @ReceivingCustomerId)
		AND wf.[WorkScopeId] = @WorkOrderScopeId 
		AND wf.[IsVersionIncrease] = 0;
			   
		SELECT @WorkOrderTypeId [WorkOrderTypeId],               
               @WorkOrderStatusId [WorkOrderStatusId],               
               @CustomerId [CustomerId],
               @MasterCompanyId [MasterCompanyId],
               @ReceivingCustomerId [ReceivingCustomerWorkId],
               @Reference [CustomerReference],			  
               @CustName [CustomerName],
               ISNULL(@CreditLimit,0) [CreditLimit],
               ISNULL(@CreditTermsId,0) [CreditTermsId],               
               @ContractReference [CustomerRef],
               @Email [CustomerEmail],
               @CustomerPhone [CustomerPhone],
			   ISNULL(@CurrencyId,0) [CurrencyId],
			   ISNULL(@AnnualRevenuePotential,0) [AnnualRevenuePotential],
			   ISNULL(@CsrId,0) [CSRId],
			    @CSRName [CSRName],
			   ISNULL(@PrimarySalesPersonId,0) [SalesPersonId],
			   @SalesPersonName AS [SalesPersonName],			  
			   ISNULL(@PrimarySalesPersonId,0) EmployeeId,			   
			   @Memo [Memo],
			   @CreditTermName [CreditTerms],
			   @CustomerContact [CustomerContact],
               @CustomerPhoneNo [CustomerPhoneNo],
               @CustomerContactId [CustomerContactId],
			   ISNULL(@ARBalance,0) [AccountsReceivableBalance],
			   @Condition [Condition],
			   @ManufacturerName [ManufacturerName],
			   @SerialNumber [SerialNumber],
			   @StockLineNumber [StockLineNumber],
			   @PartDescription [PartDescription],
			   @PartNumber [PartNumber],
			   @RevisedPartNo [RevisedPartNo],
			   @ItemMasterId [ItemMasterId],
			   @ConditionId [ConditionId],
			   @RecStockLineId [StockLineId],
			   @ReceivedDate [ReceivedDate],
			   @ReceivingNumber [ReceivingNumber],
			   @ManagementStructureId [ManagementStructureId],
			   @CustReqDate [CustReqDate],
			   ISNULL(@Quantity,0) [Quantity],
			   ISNULL(@NTE,0) [NTE],
			   @IsDER [IsDER],
			   @IsPMA [IsPMA],
			   @WorkOrderScopeId [WorkOrderScopeId],
			   @ACTailNum [ACTailNum],
			   @ItemGroup [ItemGroup],
			   @SiteId [SiteId],
			   @Site [Site],
			   @Warehouse [Warehouse],
			   @Location [Location],
			   @Shelf [Shelf],
			   @Bin [Bin],
			   @IsFinishedGood [IsFinishedGood],
			   @LastMSLevel [LastMSLevel],
			   @AllMSlevels [AllMSlevels],
			   ISNULL(@DefaultPriorityId,0) [WorkOrderPriorityId],
			   ISNULL(@DefaultStageCodeId,0) [WorkOrderStageId],
			   ISNULL(@DefaultStatusId,0) [DefaultWorkOrderStatusId],
			   CASE WHEN @WorkflowId = 0 THEN NULL ELSE @WorkflowId END [WorkFlowId],
               @WorkFlowNo [WorkFlowNo],
               @WorkflowExpirationDate [WorkflowExpirationDate],
			   @IsRepairManagement [IsRepairManagement],
			   @StockLineUnitCost [StockLineUnitCost],
			   @MPNPartNumber [MPNPartNumber],
			   @IncomingPartNumber [IncomingPartNumber],
			   @OutGoingItemMasterId [RevisedItemmasterid]
	END
	-- For Customer RMA
	IF(@Opr=2)
	BEGIN		
		DECLARE @RMAReasonId INT=0		
		DECLARE @TotalRecord INT = 0;   
		DECLARE @MinId BIGINT = 1;  
		DECLARE @RMADeatilsId BIGINT = 0;
		DECLARE @IsWorkOrder BIT = 1
		DECLARE @CustomerRMAHeaderModuleId INT=62;
				
		IF OBJECT_ID(N'tempdb..#TempTableForCustomerRMADeatils') IS NOT NULL
		BEGIN
			DROP TABLE #TempTableForCustomerRMADeatils
		END
		
		CREATE TABLE #TempTableForCustomerRMADeatils
		(		
			[ID] BIGINT NOT NULL IDENTITY, 
			[RMADeatilsId] BIGINT NULL,
			[isWorkOrder] BIT NULL,
			[ItemMasterId] BIGINT NULL,
		)	 	

		SELECT @CustomerId = [CustomerId],@MasterCompanyId = [MasterCompanyId],@Memo = [Memo],@CustomerContactId = [CustomerContactId] FROM [dbo].[CustomerRMAHeader] WITH(NOLOCK) WHERE [RMAHeaderId] = @RMAHeaderId;	
		
		SELECT @CustName=[Name],@CustomerAffiliationId=[CustomerAffiliationId],@ContractReference=[ContractReference],@Email=[Email],@CustomerPhone=[CustomerPhone] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT TOP 1 @CustomerFinancialId=[CustomerFinancialId],@CreditLimit=[CreditLimit],@CreditTermsId=[CreditTermsId],@CurrencyId=[CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT TOP 1 @AnnualRevenuePotential=[AnnualRevenuePotential],@CsrId =[CsrId],@PrimarySalesPersonId = [PrimarySalesPersonId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT @WorkOrderStatusId=[Id] FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE [Description] = 'Open';

		SELECT @CustAffiliationId = [CustomerAffiliationId] FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) WHERE [Description]='Internal';

		INSERT INTO #TempTableForCustomerRMADeatils ([RMADeatilsId],[isWorkOrder],[ItemMasterId])
		SELECT [RMADeatilsId],[isWorkOrder],[ItemMasterId] FROM [dbo].[CustomerRMADeatils] WITH(NOLOCK) WHERE [RMAHeaderId] = @RMAHeaderId;	

		SELECT TOP 1 @RMAReasonId = ISNULL([RMAReasonId],0) FROM [dbo].[RMACreditMemoSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

		SELECT @ContactContactId=con.[ContactId],@CustomerContact = con.FirstName + ' ' + con.LastName,@CustomerPhoneNo = con.WorkPhone + ' ' + con.WorkPhoneExtn 
		FROM [dbo].[CustomerContact] cc WITH(NOLOCK)
		INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.ContactId = con.ContactId 
		WHERE cc.CustomerContactId = @CustomerContactId;	

		IF(@CsrId > 0)
		BEGIN
			SELECT @CSRName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CsrId;
		END

		IF(@PrimarySalesPersonId > 0)
		BEGIN
			SELECT @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @PrimarySalesPersonId;
		END

		IF(@CustomerAffiliationId = @CustAffiliationId)
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';
		END
		ELSE
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
		END

		IF(@CustomerFinancialId > 0 AND @CreditTermsId > 0)
		BEGIN			
			SELECT @CreditTermName = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId;
		END

		SELECT TOP 1 @ARBalance = ISNULL(ARBalance,0) FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId ORDER BY [CustomerCreditTermsHistoryId] DESC;

		SELECT TOP 1 @DefaultPriorityId = [DefaultPriorityId],@DefaultStageCodeId = [DefaultStageCodeId],@DefaultStatusId = [DefaultStatusId] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		
		SELECT @TotalRecord = COUNT([RMADeatilsId]), @MinId = MIN(ID) FROM #TempTableForCustomerRMADeatils    

		IF(@TotalRecord > 1)
		BEGIN
			SET @IsSinglePN = 0;
		END
		ELSE 
		BEGIN
			SET @IsSinglePN = 1;
		END
		
		WHILE @MinId <= @TotalRecord
		BEGIN				
			SELECT @RMADeatilsId = [RMADeatilsId],
			       @IsWorkOrder = [isWorkOrder],
				   @ItemMasterId = [ItemMasterId]	    
			FROM #TempTableForCustomerRMADeatils WHERE [ID] = @MinId;

			INSERT INTO #TempTableForPartType([PartType])
			SELECT rp.[PartType] FROM [dbo].[CustomerRMADeatils] rc WITH(NOLOCK)
			JOIN [dbo].[CustomerRMAHeader] CRM WITH(NOLOCK) ON rc.[RMAHeaderId] = CRM.[RMAHeaderId]
			JOIN [dbo].[RestrictedParts] rp WITH(NOLOCK) ON CRM.[CustomerId] = rp.[ReferenceId]
			WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rp.[ModuleId] = @ModuleEnumCustomer AND rc.[RMADeatilsId] = @RMADeatilsId 
			AND rc.[ItemMasterId] = rp.[ItemMasterId] AND rp.[IsActive] = 1 AND rp.[IsDeleted] = 0;

			SELECT @PMACOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'PMA';
			SELECT @DERCOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'DER';
			
			IF(@IsWorkOrder = 1)
			BEGIN	
				INSERT INTO #TempTableForPartsDetailsWO([ReceivingCustomerWorkId],[Partnumber],[PartDescription],[RevisedPartNo],[Condition],[ConditionId],
					[StockLineNumber],[StockLineId],[SerialNumber],[Reference],[ReceivedDate],[ManagementStructureId],[CustReqDate],[Quantity],[ItemMasterId],
					[ItemGroup],[WorkOrderScopeId],[NTE],[IsPMA],[IsDER],[ACTailNum],[SiteId],[Site],[Warehouse],[Location],[Shelf],[Bin],[IsFinishedGood],
					[LastMSLevel],[AllMSlevels],[WorkOrderPriorityId],[WorkOrderStageId],[DefaultWorkOrderStatusId],[WorkFlowNo],[WorkFlowId],[WorkflowExpirationDate], [IsRepairManagement], [StockLineUnitCost], [MPNPartNumber],Notes)				
				SELECT 0,im.[PartNumber],im.[PartDescription],im.[RevisedPart],con.[Description],COALESCE(wopn.[RevisedConditionId], 0),
					sl.[StockLineNumber],sl.[StockLineId],sl.[SerialNumber],rc.[CustomerReference],CRM.[OpenDate],CRM.[ManagementStructureId],CRM.[OpenDate],1,rc.[ItemMasterId],
					COALESCE(ig.[ItemGroupCode], ''),wopn.[WorkOrderScopeId],ISNULL((im.[OverhaulHours] + COALESCE(im.[mfgHours], 0) + im.[RPHours] + im.[TestHours]),0),
					CASE WHEN @PMACOUNT > 0 THEN 0 ELSE c.[RestrictPMA] END,CASE WHEN @DERCOUNT > 0 THEN 0 ELSE c.[RestrictDER] END,wopn.[ACTailNum],
					sl.[SiteId],sl.[Site],sl.[Warehouse],sl.[Location],sl.[Shelf],sl.[Bin],0,COALESCE(msd.[LastMSLevel], ''),COALESCE(msd.[AllMSlevels], ''),
					ISNULL(@DefaultPriorityId,0),ISNULL(@DefaultStageCodeId,0),ISNULL(@DefaultStatusId,0),(wf.[WorkOrderNumber] + '_' + wf.[Version]),
					(CASE WHEN wf.WorkflowId = 0 THEN NULL ELSE wf.WorkflowId END),wf.WorkflowExpirationDate, sl.IsRepairManagement, ISNULL(sl.UnitCost, 0),
					CONCAT(im.[PartNumber], CASE	WHEN COALESCE(sl.[SerialNumber], '') <> '' THEN ' - ' + sl.[SerialNumber]
													WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
													ELSE '' END),ISNULL(wopn.Notes,'')
				FROM [dbo].[CustomerRMADeatils] rc WITH(NOLOCK)
				INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON rc.[RMADeatilsId] = sl.[RMADeatilsId]
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.[ItemMasterId] = im.[ItemMasterId]
				INNER JOIN [dbo].[CustomerRMAHeader] CRM WITH(NOLOCK) ON rc.[RMAHeaderId] = CRM.[RMAHeaderId]
				INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON CRM.[CustomerId] = c.[CustomerId]
				--INNER JOIN [dbo].[WorkOrderBillingInvoicingItem] wobi WITH(NOLOCK) ON rc.[BillingInvoicingItemId] = wobi.[WOBillingInvoicingItemId] AND ISNULL(wobi.[IsPerformaInvoice],0) = 0
				--INNER JOIN [dbo].[WorkOrderPartNumber] wopn WITH(NOLOCK) ON wobi.[WorkOrderPartId] = wopn.[ID]
				INNER JOIN [dbo].[BillingInvoicingItems] wobi WITH(NOLOCK) ON rc.[BillingInvoicingItemId] = wobi.[BillingInvoicingItemId] AND ISNULL(wobi.[IsPerformaInvoice],0) = 0 AND wobi.[ModuleId] = @WOModuleId
				INNER JOIN [dbo].[WorkOrderPartNumber] wopn WITH(NOLOCK) ON wobi.[SubReferenceId] = wopn.[ID]
				INNER JOIN [dbo].[Condition] con WITH(NOLOCK) ON wopn.[ConditionId] = con.[ConditionId]				
				 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
				 LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] msd WITH(NOLOCK) ON CRM.[RMAHeaderId] = msd.[ReferenceID] AND msd.[ModuleID] = @CustomerRMAHeaderModuleId
				 LEFT JOIN [dbo].[Workflow] wf WITH(NOLOCK) ON wf.[ItemMasterId] = rc.[ItemMasterId] AND wf.[WorkScopeId] = wopn.WorkOrderScopeId AND ISNULL(wf.IsVersionIncrease,0) = 0 AND rc.[IsActive] = 1 AND rc.[IsDeleted] = 0				 				 				
				WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rc.[RMADeatilsId] = @RMADeatilsId;
			END
			ELSE
			BEGIN
				INSERT INTO #TempTableForPartsDetailsWO([ReceivingCustomerWorkId],[Partnumber],[PartDescription],[RevisedPartNo],[Condition],[ConditionId],
					[StockLineNumber],[StockLineId],[SerialNumber],[Reference],[ReceivedDate],[ManagementStructureId],[CustReqDate],[Quantity],[ItemMasterId],
					[ItemGroup],[WorkOrderScopeId],[NTE],[IsPMA],[IsDER],[ACTailNum],[SiteId],[Site],[Warehouse],[Location],[Shelf],[Bin],[IsFinishedGood],
					[LastMSLevel],[AllMSlevels],[WorkOrderPriorityId],[WorkOrderStageId],[DefaultWorkOrderStatusId],[WorkFlowNo],[WorkFlowId],[WorkflowExpirationDate], [IsRepairManagement], [StockLineUnitCost], [MPNPartNumber])	
				SELECT 0,im.[PartNumber],im.[PartDescription],im.[RevisedPart],con.[Description],COALESCE(wopn.[ConditionId], 0),
				    sl.[StockLineNumber],sl.[StockLineId],sl.[SerialNumber],rc.[CustomerReference],CRM.[OpenDate],CRM.[ManagementStructureId],CRM.[OpenDate],1,rc.[ItemMasterId],
				    COALESCE(ig.[ItemGroupCode], ''),NULL,ISNULL((im.OverhaulHours + COALESCE(im.mfgHours, 0) + im.RPHours + im.TestHours),0),
					CASE WHEN @PMACOUNT > 0 THEN 0 ELSE c.[RestrictPMA] END,CASE WHEN @DERCOUNT > 0 THEN 0 ELSE c.[RestrictDER] END,NULL,
					sl.[SiteId],sl.[Site],sl.[Warehouse],sl.[Location],sl.[Shelf],sl.[Bin],0,COALESCE(msd.[LastMSLevel], ''),COALESCE(msd.[AllMSlevels], ''),
					ISNULL(@DefaultPriorityId,0),ISNULL(@DefaultStageCodeId,0),ISNULL(@DefaultStatusId,0),NULL,NULL,NULL, sl.IsRepairManagement, ISNULL(sl.UnitCost, 0),
					CONCAT(im.[PartNumber], CASE	WHEN COALESCE(sl.[SerialNumber], '') <> '' THEN ' - ' + sl.[SerialNumber]
													WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
													ELSE '' END)
				FROM [dbo].[CustomerRMADeatils] rc WITH(NOLOCK)
				INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON rc.[RMADeatilsId] = sl.[RMADeatilsId]
				INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.[ItemMasterId] = im.[ItemMasterId]
				INNER JOIN [dbo].[CustomerRMAHeader] CRM WITH(NOLOCK) ON rc.[RMAHeaderId] = CRM.[RMAHeaderId]
				INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON CRM.[CustomerId] = c.[CustomerId]
				--INNER JOIN [dbo].[SalesOrderBillingInvoicingItem] wobi WITH(NOLOCK) ON rc.[BillingInvoicingItemId] = wobi.[SOBillingInvoicingItemId]
				INNER JOIN [dbo].[BillingInvoicingItems] wobi WITH(NOLOCK) ON rc.[BillingInvoicingItemId] = wobi.[BillingInvoicingItemId] AND [ModuleId] = @SOModuleId
				INNER JOIN [dbo].[SalesOrderPartV1] wopn WITH(NOLOCK) ON wobi.[SubReferenceId] = wopn.[SalesOrderPartId]
				INNER JOIN [dbo].[Condition] con WITH(NOLOCK) ON wopn.[ConditionId] = con.[ConditionId]				
				 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
				 LEFT JOIN [dbo].[RMACreditMemoManagementStructureDetails] msd WITH(NOLOCK) ON CRM.[RMAHeaderId] = msd.[ReferenceID] AND msd.[ModuleID] = @CustomerRMAHeaderModuleId
				WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rc.[RMADeatilsId] = @RMADeatilsId;	
			END
			
			TRUNCATE TABLE #TempTableForPartType;
					
			SET @MinId = @MinId + 1
		END

		SELECT @WorkOrderTypeId [WorkOrderTypeId],               
               @WorkOrderStatusId [WorkOrderStatusId],               
               @CustomerId [CustomerId],
               @MasterCompanyId [MasterCompanyId],
			   @RMAReasonId [RMAReasonId],              
               '' [CustomerReference],
               @CustName [CustomerName],
               ISNULL(@CreditLimit,0) [CreditLimit],
               ISNULL(@CreditTermsId,0) [CreditTermsId],               
               @ContractReference [CustomerRef],
               @Email [CustomerEmail],
               @CustomerPhone [CustomerPhone],
			   ISNULL(@CurrencyId,0) [CurrencyId],
			   ISNULL(@AnnualRevenuePotential,0) [AnnualRevenuePotential],
			   ISNULL(@CsrId,0) [CSRId],
			    @CSRName [CSRName],
			   ISNULL(@PrimarySalesPersonId,0) [SalesPersonId],
			   @SalesPersonName AS [SalesPersonName],			  
			   ISNULL(@PrimarySalesPersonId,0) EmployeeId,			   
			   @Memo [Memo],
			   @CreditTermName [CreditTerms],
			   @CustomerContact [CustomerContact],
               @CustomerPhoneNo [CustomerPhoneNo],
               @CustomerContactId [CustomerContactId],
			   ISNULL(@ARBalance,0) [AccountsReceivableBalance],
			   @IsSinglePN [IsSinglePN]
			  
		SELECT * FROM #TempTableForPartsDetailsWO

	END
	-- For StockLine
	IF(@Opr=3)
	BEGIN
	    DECLARE @NPMStockQTY INT=1
		SELECT @CustomerId = [CustomerId],@MasterCompanyId = [MasterCompanyId],@Memo = [Memo],@ConditionId = [ConditionId] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;	
		
		SELECT @CustName=[Name],@CustomerAffiliationId=[CustomerAffiliationId],@ContractReference=[ContractReference],@Email=[Email],@CustomerPhone=[CustomerPhone] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT TOP 1 @CustomerFinancialId=[CustomerFinancialId],@CreditLimit=[CreditLimit],@CreditTermsId=[CreditTermsId],@CurrencyId=[CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT TOP 1 @AnnualRevenuePotential=[AnnualRevenuePotential],@CsrId =[CsrId],@PrimarySalesPersonId = [PrimarySalesPersonId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

		SELECT @WorkOrderStatusId=[Id] FROM [dbo].[WorkOrderStatus] WITH(NOLOCK) WHERE [Description] = 'Open';

		SELECT @CustAffiliationId = [CustomerAffiliationId] FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) WHERE [Description]='Internal';

		SELECT TOP 1 @RMAReasonId = ISNULL([RMAReasonId],0) FROM [dbo].[RMACreditMemoSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId

		SELECT @CustomerContactId = cc.CustomerContactId, @ContactContactId=con.[ContactId],@CustomerContact = con.FirstName + ' ' + con.LastName,@CustomerPhoneNo = con.WorkPhone + ' ' + con.WorkPhoneExtn 
		FROM [dbo].[CustomerContact] cc WITH(NOLOCK)
		INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.ContactId = con.ContactId 
		WHERE cc.CustomerId = @CustomerId AND cc.IsDefaultContact = 1 

		IF(@CsrId > 0)
		BEGIN
			SELECT @CSRName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CsrId;
		END

		IF(@PrimarySalesPersonId > 0)
		BEGIN
			SELECT @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @PrimarySalesPersonId;
		END

		IF(@CustomerId = 0 OR @CustomerId IS NULL OR @CustomerAffiliationId = @CustAffiliationId)
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';
		END
		ELSE
		BEGIN
			SELECT @WorkOrderTypeId = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
		END

		IF(@CustomerFinancialId > 0 AND @CreditTermsId > 0)
		BEGIN			
			SELECT @CreditTermName = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId;
		END

		SELECT TOP 1 @ARBalance = ISNULL(ARBalance,0) FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId ORDER BY [CustomerCreditTermsHistoryId] DESC;

		SELECT TOP 1 @DefaultPriorityId = [DefaultPriorityId],@DefaultStageCodeId = [DefaultStageCodeId],@DefaultStatusId = [DefaultStatusId] FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		
		SET @IsSinglePN = 1;

		INSERT INTO #TempTableForPartType([PartType])
			SELECT rp.[PartType] FROM [dbo].[StockLine] rc WITH(NOLOCK)
			JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON rc.[ItemMasterId] = im.[ItemMasterId]
			JOIN [dbo].[RestrictedParts] rp WITH(NOLOCK) ON rc.[CustomerId] = rp.[ReferenceId]
		WHERE rc.[IsActive] = 1 AND rc.[IsDeleted] = 0 AND rp.[ModuleId] = @ModuleEnumCustomer
		AND rc.[StockLineId] = @StockLineId;

		SELECT @PMACOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'PMA';
		SELECT @DERCOUNT = COUNT([PartType]) FROM #TempTableForPartType WHERE [PartType] = 'DER';
		
		IF(@CustomerId > 0)
		BEGIN
			SELECT 
				@PartNumber = im.[PartNumber],
				@PartDescription = im.[PartDescription],
				@ManufacturerName = im.[ManufacturerName],
                @RevisedPartNo = im.[RevisedPart],
				@Condition = con.[Description],
				@StockLineNumber = sl.[StockLineNumber],
				@SerialNumber = sl.[SerialNumber],
				@Reference = NULL,
				@ReceivedDate = ISNULL(sl.[ReceivedDate], GETUTCDATE()),				
				@ManagementStructureId = sl.[ManagementStructureId],
				@CustReqDate = ISNULL(sl.CreatedDate, GETUTCDATE()),
				--@NPMStockQTY AS Quantity,
				@ItemMasterId = sl.[ItemMasterId],
				@ItemGroup = ISNULL(ig.[ItemGroupCode], ''),
				@WorkOrderScopeId = NULL,
				@NTE = im.[OverhaulHours] + im.[mfgHours] + im.[RPHours] + im.[TestHours],
			    @IsPMA = CASE WHEN @PMACOUNT > 0 THEN 0 ELSE c.[RestrictPMA] END,
			    @IsDER = CASE WHEN @DERCOUNT > 0 THEN 0 ELSE c.[RestrictDER] END,				 			
				@ACTailNum = sl.[AircraftTailNumber],
				@SiteId = sl.[SiteId],
			    @Site = sl.[Site],
			    @Warehouse = sl.[Warehouse],
			    @Location =sl.[Location],
			    @Shelf = sl.[Shelf],
			    @Bin = sl.[Bin],
			    @IsFinishedGood = 0,
				@LastMSLevel = COALESCE(msd.[LastMSLevel], ''),
			    @AllMSlevels = COALESCE(msd.[AllMSlevels], ''),
				@IsRepairManagement = COALESCE(sl.[IsRepairManagement], 0),
				@StockLineUnitCost = ISNULL(sl.UnitCost, 0),
				@MPNPartNumber = CONCAT(@PartNumber, CASE	WHEN COALESCE(@SerialNumber, '') <> '' THEN ' - ' + @SerialNumber
															WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
															ELSE '' END)
			FROM [dbo].[StockLine] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sl.[ItemMasterId] = im.[ItemMasterId]
			INNER JOIN [dbo].[Customer] c WITH(NOLOCK) ON sl.[CustomerId] = c.[CustomerId]
			INNER JOIN [dbo].[Condition] con WITH(NOLOCK) ON sl.[ConditionId] = con.[ConditionId]			
			LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
			LEFT JOIN [dbo].[StocklineManagementStructureDetails] msd WITH(NOLOCK) ON sl.[StockLineId] = msd.[ReferenceID] AND msd.[ModuleID] = @MSModuleStockline
			WHERE sl.[IsActive] = 1 AND sl.[IsDeleted] = 0 AND sl.[IsParent] = 1 AND sl.[StockLineId] = @StockLineId;			
		END
		ELSE
		BEGIN
			SELECT 
				@PartNumber = im.[PartNumber],
				@PartDescription = im.[PartDescription],
				@ManufacturerName =im.[ManufacturerName],
				@RevisedPartNo = im.[RevisedPart],
				@Condition = con.[Description],
				@StockLineNumber = sl.[StockLineNumber],
				@SerialNumber = sl.[SerialNumber],
				@Reference = NULL,
				@ReceivedDate = ISNULL(sl.[ReceivedDate], GETUTCDATE()),				
				@ManagementStructureId = sl.[ManagementStructureId],
				@CustReqDate = ISNULL(sl.[CreatedDate], GETUTCDATE()),
				--@NPMStockQTY AS Quantity,
				@ItemMasterId = sl.[ItemMasterId],
				@ItemGroup = ISNULL(ig.[ItemGroupCode], ''),
				@WorkOrderScopeId = NULL,
				@NTE = im.[OverhaulHours] + im.[mfgHours] + im.[RPHours] + im.[TestHours],			   
				@IsPMA = 0,
				@IsDER = 0,
				@ACTailNum = sl.[AircraftTailNumber],								
				@SiteId = sl.[SiteId],
			    @Site = sl.[Site],
			    @Warehouse = sl.[Warehouse],
			    @Location =sl.[Location],
			    @Shelf = sl.[Shelf],
			    @Bin = sl.[Bin],
			    @IsFinishedGood = 0,				
				@LastMSLevel = COALESCE(msd.[LastMSLevel], ''),
			    @AllMSlevels = COALESCE(msd.[AllMSlevels], ''),
				@IsRepairManagement = COALESCE(sl.[IsRepairManagement], 0),
				@StockLineUnitCost = ISNULL(sl.UnitCost, 0),
				@MPNPartNumber = CONCAT(@PartNumber, CASE	WHEN COALESCE(@SerialNumber, '') <> '' THEN ' - ' + @SerialNumber
															WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
															ELSE '' END)
			FROM [dbo].[StockLine] sl WITH(NOLOCK)
			INNER JOIN [dbo].[ItemMaster] im ON sl.[ItemMasterId] = im.[ItemMasterId]
			INNER JOIN [dbo].[Condition] con ON sl.[ConditionId] = con.[ConditionId]
			LEFT JOIN [dbo].[Customer] c ON sl.[CustomerId] = c.[CustomerId]		
			LEFT JOIN [dbo].[ItemGroup] ig ON im.[ItemGroupId] = ig.[ItemGroupId]
			LEFT JOIN [dbo].[StocklineManagementStructureDetails] msd ON sl.[StockLineId] = msd.[ReferenceID] AND msd.[ModuleID] = @MSModuleStockline
			WHERE sl.[IsActive] = 1 AND sl.[IsDeleted] = 0 AND sl.[IsParent] = 1 AND sl.[StockLineId] = @StockLineId;
		END
		
		SELECT TOP 1 @WorkFlowNo = CONCAT(wf.[WorkOrderNumber], '_', wf.[Version]),
		             @WorkflowId = wf.[WorkflowId],
					 @WorkflowExpirationDate = wf.[WorkflowExpirationDate]
		FROM [dbo].[Workflow] wf  WITH(NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im  WITH(NOLOCK) ON wf.[ItemMasterId] = im.[ItemMasterId]
		INNER JOIN [dbo].[WorkScope] ws  WITH(NOLOCK) ON wf.[WorkScopeId] = ws.[WorkScopeId]
		WHERE wf.[IsDeleted] = 0 AND wf.[IsActive] = 1 AND wf.[ItemMasterId] = @ItemMasterId AND wf.[WorkScopeId] = @WorkOrderScopeId AND wf.[IsVersionIncrease] = 0;
				
		SELECT @WorkOrderTypeId [WorkOrderTypeId],               
               @WorkOrderStatusId [WorkOrderStatusId],               
               ISNULL(@CustomerId,0) [CustomerId],
               @MasterCompanyId [MasterCompanyId],
			   @RMAReasonId [RMAReasonId],         
               '' [CustomerReference],
               @CustName [CustomerName],
               ISNULL(@CreditLimit,0) [CreditLimit],
               ISNULL(@CreditTermsId,0) [CreditTermsId],               
               @ContractReference [CustomerRef],
               @Email [CustomerEmail],
               @CustomerPhone [CustomerPhone],
			   ISNULL(@CurrencyId,0) [CurrencyId],
			   ISNULL(@AnnualRevenuePotential,0) [AnnualRevenuePotential],
			   ISNULL(@CsrId,0) [CSRId],
			    @CSRName [CSRName],
			   ISNULL(@PrimarySalesPersonId,0) [SalesPersonId],
			   @SalesPersonName AS [SalesPersonName],			  
			   ISNULL(@PrimarySalesPersonId,0) EmployeeId,			   
			   @Memo [Memo],
			   @CreditTermName [CreditTerms],
			   @CustomerContact [CustomerContact],
               @CustomerPhoneNo [CustomerPhoneNo],
               @CustomerContactId [CustomerContactId],
			   ISNULL(@ARBalance,0) [AccountsReceivableBalance],
			   @Condition [Condition],
			   @ManufacturerName [ManufacturerName],
			   @SerialNumber [SerialNumber],
			   @StockLineNumber [StockLineNumber],
			   @PartDescription [PartDescription],
			   @PartNumber [PartNumber],
			   @RevisedPartNo [RevisedPartNo],
			   @ItemMasterId [ItemMasterId],
			   @ConditionId [ConditionId],
			   @StockLineId [StockLineId],
			   @ReceivedDate [ReceivedDate],
			   @ReceivingNumber [ReceivingNumber],
			   @ManagementStructureId [ManagementStructureId],
			   @CustReqDate [CustReqDate],			   
			   @NPMStockQTY AS [Quantity],
			   ISNULL(@NTE,0) [NTE],
			   @IsDER [IsDER],
			   @IsPMA [IsPMA],
			   @WorkOrderScopeId [WorkOrderScopeId],
			   @ACTailNum [ACTailNum],
			   @ItemGroup [ItemGroup],
			   @SiteId [SiteId],
			   @Site [Site],
			   @Warehouse [Warehouse],
			   @Location [Location],
			   @Shelf [Shelf],
			   @Bin [Bin],
			   @IsFinishedGood [IsFinishedGood],
			   @LastMSLevel [LastMSLevel],
			   @AllMSlevels [AllMSlevels],
			   ISNULL(@DefaultPriorityId,0) [WorkOrderPriorityId],
			   ISNULL(@DefaultStageCodeId,0) [WorkOrderStageId],
			   ISNULL(@DefaultStatusId,0) [DefaultWorkOrderStatusId],
			   CASE WHEN @WorkflowId = 0 THEN NULL ELSE @WorkflowId END [WorkFlowId],
               @WorkFlowNo [WorkFlowNo],
               @WorkflowExpirationDate [WorkflowExpirationDate],	 
			   @Reference Reference,
    		   ISNULL(@IsRepairManagement, 0) [IsRepairManagement],
			   @StockLineUnitCost [StockLineUnitCost],
			   @MPNPartNumber [MPNPartNumber]
	END	
	-- For Work Order
	IF(@Opr=4)
	BEGIN
			DECLARE @WorkOrderNum VARCHAR(30)=NULL,@CustomerCode VARCHAR(100)=NULL
			DECLARE @WorkOrderQuoteId BIGINT=NULL,@TechnicianId BIGINT=NULL , @WOCreditLimit DECIMAL(18,2)=0
			DECLARE @SentDate DATETIME2(7) = NULL,@ApprovedDate DATETIME2(7) = NULL
			DECLARE @TotalRecords INT = 0,@IsWorkflowTranfer BIT = 0,@WOCreditTermsId INT = 0     
			DECLARE @MinIds BIGINT = 1,@ID  BIGINT = 0,@RepairOrderId BIGINT = NULL 
			DECLARE @RevisedSerialNumber VARCHAR(50)=NULL,@CurrentSerialNumber VARCHAR(100)=NULL
			DECLARE @WorkFlowWorkOrderId BIGINT = 0,@RevisedPartId BIGINT=NULL,@WorkOrderPartNoId BIGINT=NULL
			DECLARE @IsAllowReOpenWO BIT=0,@TechnicianName NVARCHAR(255)=NULL,@WOCreditTerms VARCHAR(50)=NULL
			DECLARE @RevisePartId BIGINT=0,@OldWorkOrderId BIGINT = 0,@InvoiceId BIGINT = 0
			DECLARE @ExistingRMAHeaderId BIGINT=0,@IsWoadded BIT=0,@CreditMemoHeaderId BIGINT;
			DECLARE @WorkOrderFormTypeId BIGINT=0, @TearDownTypes VARCHAR(300)
			DECLARE @CreatedBy VARCHAR(256),@UpdatedBy VARCHAR(256),@CreatedDate DATETIME2(7),@UpdatedDate DATETIME2(7)
			DECLARE @FunctionalCurrencyId INT=NULL,@ReportCurrencyId INT=NULL,@OpenDate DATETIME2(7)=''						 
			DECLARE @IsActive  BIT=1,@IsDeleted BIT=0,@IsWarranty BIT=NULL,@IsAccepted BIT=NULL,@IsManualForm BIT=0,@IsWoAlwaysOrOndemandId BIT=0			 
			DECLARE @ReasonId BIGINT=NULL,@PercentId BIGINT=0			
			DECLARE @Notes NVARCHAR(MAX),@CustomerType VARCHAR(200),@Reason VARCHAR(500)
			DECLARE @Days INT=0,@NetDays INT=0,@ForeignExchangeRate  DECIMAL(18,2) = 0
			DECLARE @WOReceivingCustomerWorkId BIGINT=NULL
			DECLARE @AllowPrintReleaseForm BIT = 0;
			
			IF OBJECT_ID(N'tempdb..#TempWOPartShippingDetails') IS NOT NULL
			BEGIN
				DROP TABLE #TempWOPartShippingDetails
			END

			IF OBJECT_ID(N'tempdb..#TempWorkOrderPartNumberDetails') IS NOT NULL
			BEGIN
				DROP TABLE #TempWorkOrderPartNumberDetails
			END

			CREATE TABLE #TempWOPartShippingDetails
			(		
				[ID] BIGINT NOT NULL IDENTITY, 				
				[ShipDate] DATETIME2(7) NULL,				
				[WorkOrderPartNoId] BIGINT NULL				
			)
			
			CREATE TABLE #TempWorkOrderPartNumberDetails
			(		
				[PKID] BIGINT NOT NULL IDENTITY, 
				[ID] BIGINT NULL,
				[WorkOrderId] BIGINT NULL,
				[WorkOrderScopeId] BIGINT NULL,
				[EstimatedShipDate] DATETIME2(7) NULL,
				[CustomerRequestDate] DATETIME2(7) NULL,
				[PromisedDate] DATETIME2(7) NULL,
				[EstimatedCompletionDate] DATETIME2(7) NULL,
				[NTE] [varchar](30) NULL,
				[Quantity] [int] NOT NULL,
				[StockLineId] [bigint] NULL,
				[CMMIds] VARCHAR(256) NULL,
				[WorkflowId] BIGINT NULL,
				[WorkOrderStageId] BIGINT NULL,
				[WorkOrderStatusId] BIGINT NULL,
				[WorkOrderPriorityId] BIGINT NULL,
				[IsPMA] BIT NULL,
				[IsDER] BIT NULL,
				[TechStationId] BIGINT NULL,
				[TATDaysStandard] INT NULL,
				[MasterCompanyId] INT NULL,
				[CreatedBy] VARCHAR(256) NULL,
				[UpdatedBy] VARCHAR(256) NULL,
				[CreatedDate] DATETIME2(7) NULL,
				[UpdatedDate] DATETIME2(7) NULL,
				[IsActive] BIT NULL,
				[IsDeleted] BIT NULL,
				[ItemMasterId] BIGINT NULL,
				[TechnicianId] BIGINT NULL,
				[ConditionId] BIGINT NULL,
				[TATDaysCurrent] INT NULL,
				[RevisedPartId] BIGINT NULL,
				[ManagementStructureId] BIGINT NULL,
				[IsMPNContract] BIT NULL,
				[ContractNo] VARCHAR(20) NULL,
				[WorkScope] VARCHAR(200) NULL,
				[isLocked] BIT NULL,
				[ReceivedDate] DATETIME NULL,
				[IsClosed] BIT NULL,
				[ACTailNum] NVARCHAR(500) NULL,
				[ClosedDate] DATETIME NULL,
				[PDFPath] NVARCHAR(max) NULL,
				[IsFinishGood] BIT NULL,
				[RevisedConditionId] BIGINT NULL,
				[CustomerReference] VARCHAR(256) NULL,
				[Level1] VARCHAR(200) NULL,
				[Level2] VARCHAR(200) NULL,
				[Level3] VARCHAR(200) NULL,
				[Level4] VARCHAR(200) NULL,
				[AssignDate] DATETIME2(7) NULL,
				[ReceivingCustomerWorkId] BIGINT NULL,
				[ExpertiseId] SMALLINT NULL,
				[RevisedItemmasterid] BIGINT NULL,
				[RevisedPartNumber] VARCHAR(50) NULL,
				[RevisedPartDescription] VARCHAR(max) NULL,
				[IsTraveler] BIT NULL,
				[AllowInvoiceBeforeShipping] BIT NULL,
				[WOFPrintDate] DATETIME2(7) NULL,
				[CurrentSerialNumber] VARCHAR(100) NULL,
				[StocklineCost] DECIMAL(18, 2) NULL,
				[TendorStocklineCost] DECIMAL(18, 2) NULL,
				[RepairOrderId] BIGINT NULL,
				[RONumber] VARCHAR(50) NULL,
				[RevisedSerialNumber] VARCHAR(50) NULL,
				[IsROCreated] BIT NULL,
				[PartNumber] VARCHAR(200) NULL,
				[PartDescription] NVARCHAR(max) NULL,
				[WorkOrderStatus] VARCHAR(max) NULL,
				[Priority] VARCHAR(100) NULL,
				[WorkOrderStage] VARCHAR(150) NULL,
				[ManufacturerName] VARCHAR(250) NULL,
				[TechName] VARCHAR(100) NULL,
				[EmployeeStation] VARCHAR(100) NULL,
				[PublicationNo] VARCHAR(max) NULL,				
				[MasterPartId] BIGINT NULL,				
				[isWorkflowTranfer] BIT NULL,
				[WorkFlowWorkOrderId] BIGINT NULL,
				[vendorName] VARCHAR(256) NULL,
				[vendorCode] VARCHAR(50) NULL,
				[vendorId] BIGINT NULL,
				[IsDeletable] BIT NULL,
				[WorkFlowNo] VARCHAR(100) NULL,
				[WorkflowExpirationDate] DATETIME2(7) NULL,
				[publicatonExpirationDate] DATETIME2(7) NULL,
				[IsAllowReOpenWO] BIT NULL,
				[RevisedPartNo] VARCHAR(250) NULL,
				[TechnicianName] VARCHAR(100) NULL,
				[Condition] VARCHAR(256) NULL,		
				[RevisedCondition] VARCHAR(256) NULL,
				[SerialNumber] VARCHAR(100) NULL,
				[StockLineNumber] VARCHAR(50) NULL,				
				[ReceivingNumber] VARCHAR(50) NULL,				
				[ItemGroup] VARCHAR(30) NULL,	
				[SiteId] BIGINT NULL,
				[Site] VARCHAR(100) NULL,
				[Warehouse] VARCHAR(100) NULL,
				[Location] VARCHAR(100) NULL,
				[Shelf] VARCHAR(100) NULL,
				[Bin] VARCHAR(100) NULL,				
				[AllMSlevels] NVARCHAR(MAX) NULL,
				[LastMSLevel] VARCHAR(100) NULL, 
				[IsVerified]  BIT NULL,
				[IsWoadded]  BIT NULL,
				[IsRepairManagement]  BIT NULL,
				[StockLineUnitCost] DECIMAL(18, 2) NULL,
				[MPNPartNumber] VARCHAR(400) NULL,
				[NOTES] NVARCHAR(MAX) NULL,
				[IncomingPartNumber] VARCHAR(50) NULL,
				[lineNum] BIGINT NULL
			)

			SELECT @WorkOrderNum=[WorkOrderNum],@PrimarySalesPersonId=[SalesPersonId],@CsrId =[CsrId] ,@EmployeeId=[EmployeeId],@CustomerId = [CustomerId],
			       @WOCreditLimit = ISNULL([CreditLimit],0),@WOCreditTermsId = [CreditTermId],@WorkOrderFormTypeId= ISNULL(WorkOrderFormTypeId,0), 
				   @WorkOrderStatusId = [WorkOrderStatusId], @WorkOrderTypeId = [WorkOrderTypeId],@CustomerContactId=[CustomerContactId], @WOCreditTerms=[CreditTerms],
				   @IsSinglePN=[IsSinglePN],@CreatedBy = [CreatedBy],@UpdatedBy=[UpdatedBy],@CreatedDate=[CreatedDate],@UpdatedDate = [UpdatedDate],
				   @TearDownTypes = [TearDownTypes],@FunctionalCurrencyId = [FunctionalCurrencyId],@ReportCurrencyId=[ReportCurrencyId], 				   
				   @OpenDate = [OpenDate],@IsActive=[IsActive],@IsDeleted=[IsDeleted],@IsWarranty=[IsWarranty],@IsAccepted = [IsAccepted],@IsManualForm=[IsManualForm],
				   @IsWoAlwaysOrOndemandId=[IsWoAlwaysOrOndemandId],@ReasonId=[ReasonId],@PercentId=[PercentId],@RMAHeaderId=[RMAHeaderId],@Memo=[Memo],@Notes=[Notes],
				   @CustomerType=[CustomerType],@Reason=[Reason],@Days=[Days],@NetDays=[NetDays],@ForeignExchangeRate=[ForeignExchangeRate],
				   @WOReceivingCustomerWorkId = [ReceivingCustomerWorkId]
			  FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;

			IF(@WorkOrderNum IS NOT NULL)
			BEGIN
				SELECT TOP 1 @WorkOrderQuoteId=[WorkOrderQuoteId],@SentDate=[SentDate],@ApprovedDate=[ApprovedDate] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [IsVersionIncrease] = 0;
								
				INSERT INTO #TempWOPartShippingDetails ([ShipDate],[WorkOrderPartNoId])
				                                 SELECT [ShipDate],[WorkOrderPartNoId] FROM [dbo].[WorkOrderShipping] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;	
												 				
				INSERT INTO #TempWorkOrderPartNumberDetails([ID],[WorkOrderId], [WorkOrderScopeId], [EstimatedShipDate], [CustomerRequestDate], [PromisedDate], [EstimatedCompletionDate], [NTE], [Quantity], [StockLineId], [CMMIds], [WorkflowId], [WorkOrderStageId], [WorkOrderStatusId], [WorkOrderPriorityId], [IsPMA], [IsDER], [TechStationId], [TATDaysStandard], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [TechnicianId], [ConditionId], [TATDaysCurrent], [RevisedPartId], [ManagementStructureId], [IsMPNContract], [ContractNo], [WorkScope], [isLocked], [ReceivedDate], [IsClosed], [ACTailNum], [ClosedDate], [PDFPath], [IsFinishGood], [RevisedConditionId], [CustomerReference], [Level1], [Level2], [Level3], [Level4], [AssignDate], [ReceivingCustomerWorkId], [ExpertiseId], [RevisedItemmasterid], [RevisedPartNumber], [RevisedPartDescription], [IsTraveler], [AllowInvoiceBeforeShipping], [WOFPrintDate], [CurrentSerialNumber], [StocklineCost], [TendorStocklineCost], [RepairOrderId], [RONumber], [RevisedSerialNumber], [IsROCreated], [PartNumber], [PartDescription], [WorkOrderStatus], [Priority], [WorkOrderStage], [ManufacturerName], [TechName], [EmployeeStation], [PublicationNo],[NOTES],[IncomingPartNumber],[lineNum]) 
				                                     SELECT [ID],[WorkOrderId], [WorkOrderScopeId], [EstimatedShipDate], [CustomerRequestDate], [PromisedDate], [EstimatedCompletionDate], [NTE], [Quantity], [StockLineId], [CMMIds], [WorkflowId], [WorkOrderStageId], [WorkOrderStatusId], [WorkOrderPriorityId], [IsPMA], [IsDER], [TechStationId], [TATDaysStandard], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [ItemMasterId], [TechnicianId], [ConditionId], [TATDaysCurrent], [RevisedPartId], [ManagementStructureId], [IsMPNContract], [ContractNo], [WorkScope], [isLocked], [ReceivedDate], [IsClosed], [ACTailNum], [ClosedDate], [PDFPath], [IsFinishGood], [RevisedConditionId], [CustomerReference], [Level1], [Level2], [Level3], [Level4], [AssignDate], [ReceivingCustomerWorkId], [ExpertiseId], [RevisedItemmasterid], [RevisedPartNumber], [RevisedPartDescription], [IsTraveler], [AllowInvoiceBeforeShipping], [WOFPrintDate], [CurrentSerialNumber], [StocklineCost], [TendorStocklineCost], [RepairOrderId], [RONumber], [RevisedSerialNumber], [IsROCreated], [PartNumber], [PartDescription], [WorkOrderStatus], [Priority], [WorkOrderStage], [ManufacturerName], [TechName], [EmployeeStation], [PublicationNo],[NOTES],[IncomingPartNumber],ROW_NUMBER() OVER (ORDER BY WorkOrderPartNumber.ID)
				FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND IsDeleted = 0 ORDER BY ID 	

								
				IF(@PrimarySalesPersonId > 0)
				BEGIN
					SELECT @SalesPersonName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @PrimarySalesPersonId;
				END
				IF(@CsrId > 0)
				BEGIN
					SELECT @CSRName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CsrId;
				END
				IF(@EmployeeId > 0)
				BEGIN
					SELECT @EmployeeName = [FirstName] + ' ' + [LastName] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @EmployeeId;
				END				
				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderCharges]  WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [IsFromWorkFlow] = 1)
				BEGIN
					SET @IsWorkflowTranfer = 1;
				END
				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderAssets]  WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [IsFromWorkFlow] = 1)
				BEGIN
					SET @IsWorkflowTranfer = 1;
				END
				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderMaterials]  WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [IsFromWorkFlow] = 1)
				BEGIN
					SET @IsWorkflowTranfer = 1;
				END
				IF EXISTS(SELECT TOP 1 wl.WorkOrderLaborId FROM [dbo].[WorkOrderLaborHeader] wlh WITH(NOLOCK) JOIN [dbo].[WorkOrderLabor] wl WITH(NOLOCK) ON wlh.[WorkOrderLaborHeaderId] = wl.[WorkOrderLaborHeaderId] WHERE wlh.[WorkOrderId] = @WorkOrderId AND wl.[IsFromWorkFlow] = 1)
				BEGIN
					SET @IsWorkflowTranfer = 1;
				END

				SELECT @TotalRecords = COUNT([ItemMasterId]), @MinId = MIN(ID) FROM #TempWorkOrderPartNumberDetails    
		
				WHILE @MinIds <= @TotalRecords
				BEGIN				
					SELECT @ID = [ID],
					       @ItemMasterId = [ItemMasterId],
					       @CurrentSerialNumber = [CurrentSerialNumber],
						   @RevisedSerialNumber=[RevisedSerialNumber],
						   @RepairOrderId = [RepairOrderId],	
						   @WorkflowId = [WorkflowId],
						   @TechnicianId = [TechnicianId]
					  FROM #TempWorkOrderPartNumberDetails WHERE [PKID] = @MinIds;

					DECLARE @IsPaymentReceived BIT = NULL;
					
					--SELECT @IsPaymentReceived = CASE WHEN (ISNULL(SUM(WOBI.[RemainingAmount]),0) - ISNULL(SUM(WOBI.[GrandTotal]), 0)) = 0 THEN 0 ELSE 1 END 
					--FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH (NOLOCK) 
					--JOIN [dbo].[WorkOrderBillingInvoicingItem] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
					--WHERE WOBI.WorkOrderId = @WorkOrderId 
					--AND WOBII.[WorkOrderPartId] = @ID 
					--AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 
					--AND ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0

					SELECT @IsPaymentReceived = CASE WHEN (ISNULL(SUM(WOBI.[RemainingAmount]),0) - ISNULL(SUM(WOBI.[GrandTotal]), 0)) = 0 THEN 0 ELSE 1 END 
					FROM [dbo].[BillingInvoicing] WOBI WITH (NOLOCK) 
					JOIN [dbo].[BillingInvoicingItems] WOBII WITH (NOLOCK) ON WOBII.[BillingInvoicingId] = WOBI.[BillingInvoicingId] 
					WHERE WOBI.ReferenceId = @WorkOrderId 
					AND WOBI.[ModuleId] = @WOModuleId
					AND WOBII.[SubReferenceId] = @ID 
					AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBI.[IsVersionIncrease], 0) = 0 AND WOBI.[IsDeleted] = 0 
					AND ISNULL(WOBII.[IsPerformaInvoice], 0) = 0 AND ISNULL(WOBII.[IsVersionIncrease], 0) = 0 AND WOBII.[IsDeleted] = 0

					IF(@IsPaymentReceived = 1)
					BEGIN
						SET @IsAllowReopenWO = 0;				
					END
					ELSE
					BEGIN
						SET @IsAllowReopenWO = 1;
					END

					SELECT @WorkFlowWorkOrderId = (SELECT TOP 1 [WorkFlowWorkOrderId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId] = @ID)
					
					SET @RevisedPartId = (SELECT [RevisedPartId] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId);
										
					IF @RevisedPartId > 0
					BEGIN
						SELECT @RevisedPartNo = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @RevisedPartId;
					END

					IF @TechnicianId > 0
					BEGIN
						SELECT @TechnicianName = CONCAT([FirstName], ' ', [LastName]) FROM [dbo].[Employee] WHERE [EmployeeId] = @TechnicianId;
					END

					SELECT TOP 1 
						@ReceivingCustomerWorkId = ISNULL(rc.ReceivingCustomerWorkId, 0),
						@PartNumber = CASE WHEN wop.[RevisedPartNumber] IS NOT NULL AND wop.[RevisedPartNumber] <> '' THEN wop.[RevisedPartNumber] ELSE im.[PartNumber] END,
						@ManufacturerName = im.[ManufacturerName],
						@PartDescription = CASE WHEN wop.[RevisedPartDescription] IS NOT NULL AND wop.[RevisedPartDescription] <> '' THEN wop.[RevisedPartDescription] ELSE im.[PartDescription] END,						
						@Condition = con.[Description],
						@RevisedCondition = rcon.[Description],
						@StockLineNumber = sl.[StockLineNumber],
						--@SerialNumber = CASE WHEN wop.[RevisedSerialNumber] IS NOT NULL AND wop.[RevisedSerialNumber] <> '' THEN wop.[RevisedSerialNumber] ELSE sl.[SerialNumber] END,
						@SerialNumber =  CASE WHEN @CurrentSerialNumber IS NULL THEN sl.[SerialNumber] ELSE @CurrentSerialNumber END, 
						@ReceivedDate = ISNULL(wop.[ReceivedDate], GETUTCDATE()),
						@ReceivingNumber = ISNULL(rc.[ReceivingNumber], ''),
						@Reference = wop.[CustomerReference],						
						@CustReqDate = ISNULL(wop.[CustomerRequestDate], GETUTCDATE()),
						@ItemGroup = ISNULL(ig.[ItemGroupCode], ''),
						@WorkOrderScopeId = rc.[WorkScopeId],
						@MasterCompanyId = wop.[MasterCompanyId],
						@ManagementStructureId = wop.[ManagementStructureId],	
						@SiteId = sl.[SiteId],
						@Site = sl.[Site],
						@Warehouse = sl.[Warehouse],
						@Location =sl.[Location],
						@Shelf = sl.[Shelf],
						@Bin = sl.[Bin],						
						@IsFinishedGood = wop.[IsFinishGood],
						@LastMSLevel = msd.LastMSLevel,
						@AllMSlevels = msd.AllMSlevels,
						@IsRepairManagement = ISNULL(sl.IsRepairManagement, 0),
						@StockLineUnitCost = ISNULL(sl.UnitCost, 0),
						@MPNPartNumber = CONCAT(@PartNumber, CASE	WHEN COALESCE(@SerialNumber, '') <> '' THEN ' - ' + @SerialNumber
																	WHEN COALESCE(sl.ControlNumber, '') <> '' THEN ' - ' + sl.ControlNumber
																	ELSE '' END)

					FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
					INNER JOIN [dbo].[StockLine] sl WITH(NOLOCK) ON wop.[StockLineId] = sl.[StockLineId]
					INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON wop.[ItemMasterId] = im.[ItemMasterId]
					INNER JOIN [dbo].[WorkOrderManagementStructureDetails] msd WITH(NOLOCK) ON wop.[ID] = msd.[ReferenceID]
					 LEFT JOIN [dbo].[ItemGroup] ig WITH(NOLOCK) ON im.[ItemGroupId] = ig.[ItemGroupId]
					INNER JOIN [dbo].[Condition] con WITH(NOLOCK) ON wop.[ConditionId] = con.[ConditionId]
					 LEFT JOIN [dbo].[Condition] rcon WITH(NOLOCK) ON wop.[RevisedConditionId] = rcon.[ConditionId]
					INNER JOIN [dbo].[WorkOrder] wo WITH(NOLOCK) ON wop.[WorkOrderId] = wo.[WorkOrderId]
					 LEFT JOIN [dbo].[ReceivingCustomerWork] rc WITH(NOLOCK) ON wop.[ReceivingCustomerWorkId] = rc.[ReceivingCustomerWorkId]
					WHERE wop.[WorkOrderId] = @WorkOrderId AND wop.[ID] = @ID AND msd.[ModuleID] = @WorkOrderMPNMSModuleEnum;

					IF(@ItemMasterId > 0 AND (@SerialNumber != NULL AND @SerialNumber <> ''))
					BEGIN  
						SELECT TOP 1 @OldWorkOrderId = WO.[WorkOrderId]
						FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
						LEFT JOIN [dbo].[WorkOrderPartNumber] WP WITH(NOLOCK) ON WO.WorkOrderId = WP.WorkOrderId
						LEFT JOIN [dbo].[Stockline] SL WITH(NOLOCK) ON WP.StockLineId = SL.StockLineId
						LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON WP.ItemMasterId = IM.ItemMasterId
						WHERE WP.[ItemMasterId] = @ItemMasterId AND SL.[SerialNumber] = @SerialNumber AND WO.[MasterCompanyId] = @MasterCompanyId AND YEAR(WO.[CreatedDate]) = YEAR(DATEADD(YEAR, 0, SYSDATETIME())) 
					
						IF(@OldWorkOrderId > 0)
						BEGIN
							--SELECT @InvoiceId = WOBI.[BillingInvoicingId]
							--	 FROM [dbo].[WorkOrderBillingInvoicing] WOBI WITH(NOLOCK)
							--LEFT JOIN [dbo].[Customer] C WITH(NOLOCK) ON WOBI.CustomerId = C.CustomerId
							--LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
							--LEFT JOIN [dbo].[CustomerType] CT WITH(NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
							--LEFT JOIN [dbo].[CustomerContact] CUN WITH(NOLOCK) ON CUN.CustomerContactId=WO.CustomerContactId
							--LEFT JOIN [dbo].[Contact] CON WITH(NOLOCK) ON CON.ContactId=CUN.ContactId
							--LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH(NOLOCK) ON wo.MasterCompanyId = RMAC.MasterCompanyId
							--WHERE WO.[WorkOrderId] = @OldWorkOrderId  AND ISNULL(WOBI.[IsVersionIncrease],0) = 0 AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0;

							SELECT @InvoiceId = WOBI.[BillingInvoicingId]
						    FROM [dbo].[BillingInvoicing] WOBI WITH(NOLOCK)
							LEFT JOIN [dbo].[Customer] C WITH(NOLOCK) ON WOBI.CustomerId = C.CustomerId
							LEFT JOIN [dbo].[WorkOrder] WO WITH(NOLOCK) ON WOBI.ReferenceId = WO.WorkOrderId
							LEFT JOIN [dbo].[CustomerType] CT WITH(NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
							LEFT JOIN [dbo].[CustomerContact] CUN WITH(NOLOCK) ON CUN.CustomerContactId=WO.CustomerContactId
							LEFT JOIN [dbo].[Contact] CON WITH(NOLOCK) ON CON.ContactId=CUN.ContactId
							LEFT JOIN [dbo].[RMACreditMemoSettings] RMAC WITH(NOLOCK) ON wo.MasterCompanyId = RMAC.MasterCompanyId
							WHERE WO.[WorkOrderId] = @OldWorkOrderId  AND ISNULL(WOBI.[IsVersionIncrease],0) = 0 AND ISNULL(WOBI.[IsPerformaInvoice], 0) = 0 AND WOBI.[ModuleId] = @WOModuleId

							IF(@InvoiceId > 0)
							BEGIN
								SELECT TOP 1 @ExistingRMAHeaderId = [CreditMemoHeaderId] FROM [dbo].[CreditMemo] WITH(NOLOCK) WHERE [ReferenceId] = @WorkOrderId;
								IF(@ExistingRMAHeaderId > 0)
								BEGIN
									SET @IsWoadded = 0;
								END
								ELSE 
								BEGIN									
									SELECT TOP 1 @CreditMemoHeaderId = [CreditMemoHeaderId]
									FROM [dbo].[CreditMemo]	WHERE [ReferenceId] = @WorkOrderId;

									SET @IsWoadded = CASE WHEN @CreditMemoHeaderId > 0 THEN 0 ELSE 1 END;
								END
							END
							ELSE
							BEGIN
								SET @IsWoadded = 0;
							END
						END
						ELSE
						BEGIN
							SET @IsWoadded = 0;
						END					
					END
			
					UPDATE #TempWorkOrderPartNumberDetails SET 
					       [MasterPartId] = @ItemMasterId,
					       [CurrentSerialNumber] = CASE WHEN (@RevisedSerialNumber IS NOT NULL AND @RevisedSerialNumber !='') THEN @RevisedSerialNumber ELSE @CurrentSerialNumber END,
						   [isWorkflowTranfer] = @isWorkflowTranfer,
						   [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId,
						   [vendorName] = CASE WHEN @RepairOrderId > 0 THEN (SELECT [VendorName] FROM [dbo].[RepairOrder] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId) ELSE '' END,
						   [vendorCode]	= CASE WHEN @RepairOrderId > 0 THEN (SELECT [VendorCode] FROM [dbo].[RepairOrder] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId) ELSE '' END,
						   [vendorId] = CASE WHEN @RepairOrderId > 0 THEN (SELECT [VendorId] FROM [dbo].[RepairOrder] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId) ELSE 0 END,
						   [IsDeletable] = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND QuantityIssued > 0 AND IsDeleted = 0) THEN 0 ELSE 1 END,
                           [WorkFlowNo] = CASE WHEN @WorkflowId > 0 THEN (SELECT [WorkOrderNumber] + '_' + [Version] FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId) ELSE '' END,
						   [WorkflowExpirationDate] = CASE WHEN @WorkflowId > 0 THEN (SELECT [WorkflowExpirationDate] FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId) ELSE NULL END,
						   [IsAllowReopenWO] = @IsAllowReopenWO,
						   [RevisedPartId] = @RevisedPartId,
						   [RevisedPartNo] = @RevisedPartNo,
						   [TechnicianName] = @TechnicianName,
						   [Condition] = @Condition,
						   [RevisedCondition] = @RevisedCondition,
						   [ManufacturerName] = @ManufacturerName,
						   [SerialNumber] = @SerialNumber,
						   [StockLineNumber] = @StockLineNumber,
						   [PartDescription] = @PartDescription,
						   [PartNumber] = @PartNumber,
						   [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId,
						   [ReceivedDate] = @ReceivedDate,
                           [ReceivingNumber] = @ReceivingNumber,
                           [CustomerReference] = @Reference,
                           [ItemMasterId] = @ItemMasterId,                      
                           [ItemGroup] = @ItemGroup,
						   --[WorkOrderScopeId] = @WorkOrderScopeId,
						   [ManagementStructureId] = @ManagementStructureId,
						   [MasterCompanyId] = @MasterCompanyId,
                           [SiteId] = @SiteId,
                           [Site] = @Site,
                           [Warehouse] = @Warehouse,
                           [Location] = @Location,
                           [Shelf] = @Shelf,
                           [Bin] = @Bin,
                           [IsFinishGood] = @IsFinishedGood,
                           [AllMSlevels] = @AllMSlevels,
                           [LastMSLevel] = @LastMSLevel,
						   [IsWoadded] = @IsWoadded,
						   [IsRepairManagement] = @IsRepairManagement,
						   [StockLineUnitCost] = @StockLineUnitCost,
						   [MPNPartNumber] = @MPNPartNumber
					 WHERE [PKID] = @MinIds;

					SET @MinIds = @MinIds + 1;
				END

			    SELECT @CustName=[Name],@Email=[Email],@CustomerPhone=[CustomerPhone],@CustomerCode=[CustomerCode],@ContractReference=[ContractReference] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;

				SELECT TOP 1 @CustomerFinancialId=[CustomerFinancialId],@CreditLimit=[CreditLimit],@CreditTermsId=ISNULL([CreditTermsId],0),@CurrencyId=[CurrencyId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId;
				
				SELECT TOP 1 @ARBalance = ISNULL([ARBalance],0) FROM [dbo].[CustomerCreditTermsHistory] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId ORDER BY [CustomerCreditTermsHistoryId] DESC;
				
				SELECT TOP 1 @RCReference = [Reference] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;

				IF(@CustomerFinancialId > 0 AND @CreditTermsId > 0)
				BEGIN			
					SELECT @CreditTermName = [Name] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId;

					IF(@CreditTermName IS NOT NULL AND @CreditTermName <> '')
					BEGIN
						SET @CreditTermName = CASE WHEN @WorkOrderNum IS NOT NULL THEN @WOCreditTerms ELSE @CreditTermName END
					END
				END

				SELECT @ContactContactId=con.[ContactId],
				       @CustomerContact = con.[FirstName] + ' ' + con.[LastName],
				       @CustomerPhoneNo = con.[WorkPhone] + ' ' + con.[WorkPhoneExtn], 
					   @CustomerEmail = con.[Email]
				FROM [dbo].[CustomerContact] cc WITH(NOLOCK)
				INNER JOIN [dbo].[Contact] con WITH(NOLOCK) ON cc.[ContactId] = con.[ContactId] 
				WHERE cc.[CustomerContactId] = @CustomerContactId;	

				IF(@IsSinglePN = 1)
				BEGIN
					SELECT TOP 1 @WorkFlowWorkOrderId = [WorkFlowWorkOrderId],@WorkOrderPartNoId = [WorkOrderPartNoId] FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
				END	

				IF EXISTS(SELECT 1 FROM [dbo].[Work_ReleaseFrom_8130] WITH(NOLOCK) WHERE [WorkorderId] = @WorkOrderId AND [IsDeleted] = 0 AND [IsActive] = 1)
				BEGIN
					SET @AllowPrintReleaseForm = 1;
				END
				
				SELECT  @MasterCompanyId [MasterCompanyId],
				        @WOReceivingCustomerWorkId [ReceivingCustomerWorkId],
				        @SentDate [SentDate], 
				        @ApprovedDate [ApprovedDate],
						@PrimarySalesPersonId [SalesPersonId],
						@SalesPersonName [SalesPersonName],
						@EmployeeId [EmployeeId],
						@EmployeeName [EmployeeName],
				        @RCReference [CustomerReference],
				        @CustName [CustomerName],
						@WOCreditLimit [WoCreditLimit], 
						@CreditLimit [CreditLimit], 
						@CreditTermsId [CreditTermsId],
						@WOCreditTermsId [WoCreditTermsId],
						@WOCreditTerms [WOCreditTerms],
						@CustomerId [CustomerId],
						@Email [Email],
						@CustomerPhone [CustomerPhone],
						@CsrId [CsrId],
						@CSRName [CSRName],
						@CurrencyId [CurrencyId],						
						@CustomerCode [CustomerCode],
						@ContractReference [ContractReference],
						@ARBalance [AccountsReceivableBalance],
						@CreditTermName [CreditTerms],
						@CustomerContact [CustomerContact],
						@CustomerContactId [CustomerContactId],
						@CustomerPhoneNo [CustomerPhoneNo],
						@CustomerEmail [CustomerEmail],
						@WorkFlowWorkOrderId [WorkFlowWorkOrderId],
						@WorkOrderPartNoId [WorkOrderPartNoId],	
						@WorkOrderNum [WorkOrderNum],
						@WorkOrderTypeId [WorkOrderTypeId],
						@WorkOrderStatusId [WorkOrderStatusId],
						@WorkOrderFormTypeId [WorkOrderFormTypeId],
						@CreatedBy [CreatedBy],
						@UpdatedBy [UpdatedBy],
						@CreatedDate [CreatedDate],
						@UpdatedDate [UpdatedDate],
						@TearDownTypes [TearDownTypes],
						@FunctionalCurrencyId [FunctionalCurrencyId],
						@ReportCurrencyId [ReportCurrencyId],
				        @IsSinglePN  [IsSinglePN],
						@OpenDate [OpenDate],
						@IsActive [IsActive],
						@IsDeleted [IsDeleted],
						@IsWarranty [IsWarranty],
						@IsAccepted [IsAccepted],
						@IsManualForm [IsManualForm],
				        @IsWoAlwaysOrOndemandId [IsWoAlwaysOrOndemandId],
						@ReasonId [ReasonId],
						@PercentId [PercentId],
						@RMAHeaderId [RMAHeaderId],
						@Memo [Memo],
						@Notes [Notes],
				        @CustomerType [CustomerType],
						@Reason [Reason],
						@Days [Days],
						@NetDays [NetDays],
						@ForeignExchangeRate [ForeignExchangeRate],
						@AllowPrintReleaseForm [AllowPrintReleaseForm]

				SELECT * FROM #TempWOPartShippingDetails

				SELECT * FROM #TempWorkOrderPartNumberDetails
			END
	END

	IF(@Opr=5)
	BEGIN
		SELECT TOP 1 ISNULL([ReceivingCustomerWorkId],0) [ReceivingCustomerWorkId] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;
	END

    END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments VARCHAR(150)    = 'GetWorkOrderById'
		, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(250))
			   + '@Parameter2 = ''' + CAST(ISNULL(@ReceivingCustomerId, '') AS VARCHAR(250))
			   + '@Parameter3 = ''' + CAST(ISNULL(@RMAHeaderId, '') AS VARCHAR(250))
			   + '@Parameter4 = ''' + CAST(ISNULL(@StockLineId, '') AS VARCHAR(250))
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