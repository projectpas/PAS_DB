/*************************************************************           
 ** File:   [USP_CreateWorkOrder]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used to Create Work Order Quote
 ** Purpose:         
 ** Date:   24/02/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    24/02/2025   HEMANT SALIYA    Created
	2    11/03/2025   Moin Bloch       Updated
	3    24/03/2025   Moin Bloch       Added UpdatedBy and Updated date 
	4    14/04/2025   Devendra Shekh   handling null for @RequestedId
    5    15/04/2025   RAJESH GAMI      Implement the traverler Number logic 
	6    18/04/2025   Moin Bloch       Added For CREATING TRAVELER LABOUR HEADER
	7    19/05/2025   Abhishek Jirawla Added new History template to mention if cretaed form lot
	8    01/07/2025   Vishal Suthar	   Inserting EnforceMpnPickTicketConfirmation flag in WorkOrder table
	9    24/09/2025   RAJESH GAMI		Added MPN Notes
	10   15/10/2025   Moin Bloch        Added SalesPersion Details
	11   29/11/2025   Moin Bloch        Added TearDownTypes Removeal Reason If Not Exists
	12   13/11/2025   Moin Bloch        Removed TearDownTypes Condition For Removeal Reason If Not Exists 
	13	 20/01/2026   Priyansh Patel  	Added CSN, TSN, CSO, TSO fields from receiving customer
	14	 30/01/2026   Moin Bloch     	Added IncomingPartNumber
	15   10/02/2026   Moin Bloch        Added Accounting Entry For TearDown Work Order PN-15331
	16   12/02/2026   Moin Bloch        Added Stockline Issue Entry For TearDown Work Order PN-15435
	17   24/02/2026   Moin Bloch        Added Logic for IncomingPartNumber PN-15427
	18   26/03/2026   Moin Bloch	    Rename TearDown To Internal Teardown PN-15850
	19   30/04/2026   Nakul Chandigra   Added  [AircraftRegistryNumber] ,[IsFromAircraft],[AircraftInstalledPartDetailsId] for Work Order (PN-16150)
	20   21/05/2026   Moin Bloch        Added  [MtcCategoryId] PN-16469

--   EXEC [USP_CreateWorkOrder] 
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrder]
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
@IsFromLot BIT=NULL,
@MtcCategoryId BIGINT = NULL,
@tbl_WorkOrderPartNumberType WorkOrderMPNType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
    -- Declare variables
	DECLARE @Customer INT,@Internal INT,@TearDown INT,@ShopServices INT
    DECLARE @CurrentNo INT = 0,@CreditTermsId INT=NULL,@WorkOrderModuleID INT,@NPMStockQTY INT = 1
    DECLARE @CodePrefix NVARCHAR(50),@CodeSuffix NVARCHAR(50)	
	DECLARE @WorkOrderSettingId BIGINT,@CustomerFinancialId BIGINT=0,@ItemMasterId BIGINT=NULL,@ID BIGINT=NULL
	DECLARE @WorkOrderCodePrefix INT,@InternalWorkOrderCodePrefix INT,@TearDownWorkOrderCodePrefix INT,@ShopServiceWorkOrderCodePrefix INT,@RMANumberCodePrefix INT
	DECLARE @CreateWO VARCHAR(50)='CreateWorkOrder', @CreateWOFromLot VARCHAR(50)='CreateWorkOrderFromLot',@EmpExpCode VARCHAR(20)='TECHNICIAN',@EmployeeExpertiseId SMALLINT= NULL,@TemplateBody VARCHAR(MAX)=''
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1,@StocklineManagementStructureModule INT,@WorkOrderMPNManagementStructureModule INT
	DECLARE @CustomerRMAHeaderManagementStructureModule INT,@OpenRMAStatus INT,@CustomerRMAItemReturnedStatus INT
	DECLARE @CurrentNumber AS BIGINT,@TravelerCodeTypeId BIGINT = (SELECT  [CodeTypeId] FROM [dbo].[CodeTypes] WITH (NOLOCK) WHERE [CodeType] = 'TravelerId')
	DECLARE @TravelerName AS varchar(100) = 0,@WorkOrderScopeId BIGINT = NULL, @EnforceMpnPickTicketConfirmation BIT; 
	DECLARE @SecondarySalesPersonId BIGINT = NULL,@SalesAgentID BIGINT = NULL,@CommonTeardownTypeId BIGINT = NULL, @StocklineHistoryReserveActionEnum INT = 0, @StocklineHistoryIssueActionEnum INT = 0
	DECLARE @IsFromAircraft BIT = 0
	DECLARE @CSN VARCHAR(50) = NULL,@TSN VARCHAR(50) = NULL,@CSO VARCHAR(50) = NULL, @TSO VARCHAR(50) = NULL;

	-- From Receiving Customer 
	SELECT @CSN = [CSN], @TSN = [TSN], @CSO = [CSO], @TSO = [TSO] FROM [dbo].[ReceivingCustomerWork] WITH (NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;
	
	-- Work Order Type
	SELECT @Customer = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Customer';
	SELECT @Internal = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Repair';
	SELECT @TearDown = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Internal Teardown';
	SELECT @ShopServices = [Id] FROM [dbo].[WorkOrderType] WITH(NOLOCK) WHERE [Description]='Shop Services';

	-- Code Types Of CodePrefix	
	SELECT @WorkOrderCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='WorkOrder';	
	SELECT @InternalWorkOrderCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Internal WorkOrder';
	SELECT @TearDownWorkOrderCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='Teardown WorkOrder';	
	SELECT @ShopServiceWorkOrderCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='ShopService WorkOrder';
	SELECT @RMANumberCodePrefix = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType]='RMANumber';
	
	-- Modules
	SELECT @WorkOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';	

	-- STOCKLINE RESERVE ENUM			
	SELECT @StocklineHistoryReserveActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='Reserve';
					
	-- STOCKLINE ISSUE ENUM						
	SELECT @StocklineHistoryIssueActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='Issue';

	-- Management Structure Module
	SELECT @StocklineManagementStructureModule = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName]='Stockline';
	SELECT @WorkOrderMPNManagementStructureModule = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName]='WorkOrderMPN';
	SELECT @CustomerRMAHeaderManagementStructureModule = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName]='CustomerRMAHeader';
	
	-- RMA Status
	SELECT @OpenRMAStatus = [RMAStatusId] FROM [dbo].[RMAStatus] WITH(NOLOCK) WHERE [Description]='Open';
	SELECT @CustomerRMAItemReturnedStatus = [RMAStatusId] FROM [dbo].[RMAStatus] WITH(NOLOCK) WHERE [Description]='Item Returned';

	SELECT @IsFromAircraft = (SELECT TOP 1 ISNULL([IsFromAircraft],0) FROM @tbl_WorkOrderPartNumberType)	
		
	SET @CreatedDate = GETUTCDATE();
    SET @UpdatedDate = GETUTCDATE();

	IF OBJECT_ID(N'tempdb..#tmprCreateWorkOrderPartNumber') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCreateWorkOrderPartNumber
	END
	IF OBJECT_ID(N'tempdb..#tmprCreateWorkOrderCustomerRMADeatils') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCreateWorkOrderCustomerRMADeatils
	END
	IF OBJECT_ID(N'tempdb..#tmprCheckWorkOrderForSerialNumber') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCheckWorkOrderForSerialNumber
	END		
	IF OBJECT_ID(N'tempdb..#tmprOldWorkOrderForBillingInvoicedData') IS NOT NULL
	BEGIN
		DROP TABLE #tmprOldWorkOrderForBillingInvoicedData
	END
	IF OBJECT_ID(N'tempdb..#tmprGetCustomerRMAPartsDetails') IS NOT NULL
	BEGIN
		DROP TABLE #tmprGetCustomerRMAPartsDetails
	END
	IF OBJECT_ID(N'tempdb..#tbl_CustomerRMADeatilsType') IS NOT NULL
	BEGIN
		DROP TABLE #tbl_CustomerRMADeatilsType
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
		[Notes] [nvarchar](MAX) NULL,
		[CSN] [varchar](50) NULL,
		[TSN] [varchar](50) NULL,
		[CSO] [varchar](50) NULL,
		[TSO] [varchar](50) NULL,
		[AircraftRegistryNumber] [VARCHAR](30) NULL,
		[IsFromAircraft] [BIT] NULL,
		[AircraftInstalledPartDetailsId] [BIGINT] NULL,
		[AircraftSerialNumber] [VARCHAR](100)
	)

	CREATE TABLE #tmprCreateWorkOrderCustomerRMADeatils
	(
		[RMAID] [BIGINT] NOT NULL IDENTITY, 
		[RMADeatilsId] [BIGINT] NULL
	)

	CREATE TABLE #tmprCheckWorkOrderForSerialNumber
	(		
		[WorkOrderNum] VARCHAR(50) NULL,
		[WorkOrderId] [BIGINT] NULL,
	)

	CREATE TABLE #tmprOldWorkOrderForBillingInvoicedData
	(	
	    [InvoiceId] [BIGINT] NULL,
		[InvoiceNo] [VARCHAR](256) NULL,
		[InvoiceStatus] [VARCHAR](50) NULL,
		[InvoiceDate] [DATETIME2](7) NULL,
		[OrderNumber] [VARCHAR](50) NULL,
		[CustomerName] [VARCHAR](100) NULL,
		[CustomerType] [VARCHAR](256) NULL,
		[InvoiceAmt] [DECIMAL](20,2) NULL,
		[isWorkOrder] [BIT] NULL,
		[ReferenceId] [BIGINT] NULL,
		[ManagementStructureId] [BIGINT] NULL,
		[ContactInfo] [VARCHAR](150) NULL,
		[CustomerContactId] [BIGINT] NULL,
		[RMAReasonId] [INT] NULL,
		[RMAReason] [VARCHAR](50) NULL,
		[RMAStatusId] [BIGINT] NULL,
		[RMAStatus] [VARCHAR](50) NULL,
		[ValidDays] [INT] NULL,
		[MasterCompanyId] [INT] NULL,
		[CustomerId] [BIGINT] NULL,	
		[CustomerCode] [VARCHAR](100) NULL,
		[AddressCount] [INT] NULL,
		[PartCount] [INT] NULL
	)
	
	CREATE TABLE #tmprGetCustomerRMAPartsDetails
	(	
	    [RMADID] [BIGINT] NOT NULL IDENTITY, 
	    [InvoiceId] [BIGINT] NULL,
		[InvoiceNo] [VARCHAR](256) NULL,
		[BillingInvoicingItemId] [BIGINT] NULL,
		[InvoiceStatus] [VARCHAR](50) NULL,
		[InvoiceDate] [DATETIME2](7) NULL,
		[ReferenceNo] [VARCHAR](50) NULL,
		[ItemMasterId] [BIGINT] NULL,
		[PartNumber] [VARCHAR](200) NULL,
		[PartDescription] [NVARCHAR](MAX) NULL,		
		[CustPartNumber] [VARCHAR](200) NULL,
		[CustomerReference] [VARCHAR](256) NULL, 
		[SerialNumber] [VARCHAR](100) NULL,
		[StocklineNumber] [VARCHAR](50) NULL,
		[StocklineId] [BIGINT] NULL,
		[ControlNumber] [VARCHAR](200) NULL,
		[ControlId] [VARCHAR](100) NULL,
		[Qty] [INT] NULL,
		[UnitPrice] [DECIMAL](18,2) NULL,
		[Amount] [DECIMAL](18,2) NULL,
		[RMAReasonId] [INT] NULL,
		[RMAReason] [VARCHAR](50) NULL,
		[RMAStatusId] [INT] NULL,
		[RMAStatus] [VARCHAR](50) NULL,
		[RMAValiddate] [DATETIME2](7) NULL,
		[IsWorkOrder] [BIT] NULL,
		[ReferenceId] [BIGINT] NULL,
		[PartsUnitCost] [DECIMAL](18,2) NULL,
		[PartsRevenue] [DECIMAL](18,2) NULL,
		[LaborRevenue] [DECIMAL](18,2) NULL,
		[MiscRevenue] [DECIMAL](18,2) NULL,
		[FreightRevenue] [DECIMAL](18,2) NULL,
		[SubTotal] [DECIMAL](18,2) NULL,
		[SalesTax] [DECIMAL](18,2) NULL,
		[OtherTax] [DECIMAL](18,2) NULL,
		[GrandTotal] [DECIMAL](18,2) NULL,
		[InvoiceAmt] [DECIMAL](18,2) NULL,
		[COGSParts] [DECIMAL](18,2) NULL,
		[COGSLabor] [DECIMAL](18,2) NULL,
		[COGSOverHeadCost] [DECIMAL](18,2) NULL,
		[COGSInventory] [DECIMAL](18,2) NULL,
		[COGSPartsUnitCost] [DECIMAL](18,2) NULL,
		[RMADeatilsId] [BIGINT] NULL,
		[RMAHeaderId] [BIGINT] NULL,
		[Notes] [NVARCHAR](MAX) NULL,
		[MasterCompanyId] [INT] NULL,
		[CreatedBy] [VARCHAR](256) NULL,
		[UpdatedBy] [VARCHAR](256) NULL,
		[CreatedDate] [DATETIME2](7) NULL,
		[UpdatedDate] [DATETIME2](7) NULL,
		[IsActive] [BIT] NULL,
		[IsDeleted] [BIT] NULL,
		[isSerialized] [BIT] NULL,
		[InvoiceQty] [INT] NULL,
		[ManufacturerName] [VARCHAR](250) NULL,
		[AltPartNumber] [VARCHAR](200) NULL,
		[InvoiceTypeId] [INT] NULL														
	)
	
	CREATE TABLE #tbl_CustomerRMADeatilsType
	(	
	    [RMADeatilsId] [BIGINT] NULL,
		[RMAHeaderId] [BIGINT] NULL,
		[ItemMasterId] [BIGINT] NULL,
		[PartNumber] [VARCHAR](200) NULL,
		[PartDescription] [NVARCHAR](MAX) NULL,	
		[AltPartNumber] [VARCHAR](200) NULL,
		[CustPartNumber] [VARCHAR](200) NULL,
		[SerialNumber] [VARCHAR](100) NULL,
		[StocklineId] [BIGINT] NULL,
		[StocklineNumber] [VARCHAR](50) NULL,
		[ControlNumber] [VARCHAR](200) NULL,
		[ControlId] [VARCHAR](100) NULL,
		[ReferenceId] [BIGINT] NULL,
		[ReferenceNo] [VARCHAR](50) NULL,
		[Qty] [INT] NULL,
		[UnitPrice] [DECIMAL](18,2) NULL,
		[Amount] [DECIMAL](18,2) NULL,
		[RMAReasonId] [INT] NULL,
		[RMAReason] [VARCHAR](50) NULL,
		[Notes] [NVARCHAR](MAX) NULL,
		[isWorkOrder] [BIT] NULL,
		[MasterCompanyId] [INT] NULL,
		[CreatedBy] [VARCHAR](256) NULL,
		[UpdatedBy] [VARCHAR](256) NULL,
		[CreatedDate] [DATETIME2](7) NULL,
		[UpdatedDate] [DATETIME2](7) NULL,
		[IsActive] [BIT] NULL,
		[IsDeleted] [BIT] NULL,
		[InvoiceId] [BIGINT] NULL,
		[BillingInvoicingItemId] [BIGINT] NULL,
		[CustomerReference] [VARCHAR](256) NULL,
		[InvoiceQty] [INT] NULL,
		[ReturnDate] [DATETIME2](7) NULL,
		[WorkOrderNum] [VARCHAR](50) NULL,
		[ReceiverNum] [VARCHAR](50) NULL							
	)
	
	SELECT TOP 1 @SecondarySalesPersonId=[SecondarySalesPersonId],@SalesAgentID=[SaId] FROM [dbo].[CustomerSales] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	
	--SELECT @CommonTeardownTypeId = [CommonTeardownTypeId] FROM [dbo].[CommonTeardownType] WITH(NOLOCK) WHERE [TearDownCode] = 'RemovalReason' AND [MasterCompanyId] = @MasterCompanyId;

    -- Set CSRId and SalesPersonId to NULL if 0
    IF @CSRId = 0
        SET @CSRId = NULL;
    IF @SalesPersonId = 0
        SET @SalesPersonId = NULL;
	IF @SecondarySalesPersonId = 0
	    SET @SecondarySalesPersonId = NULL;
	IF @SalesAgentID = 0
	    SET @SalesAgentID = NULL;		

    -- Fetch WorkOrderSettings based on parameters
    SELECT TOP 1 @WorkOrderSettingId=[WorkOrderSettingId],
	             @TearDownTypes=[TearDownTypes],
				 @IsManualForm = CASE WHEN [IsManualForm] IS NULL THEN 0 ELSE [IsManualForm] END,
				 @IsTraveler = [IsTraveler],
				 @AllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping],
				 @EnforceMpnPickTicketConfirmation = [EnforceMpnPickTicketConfirmation]
      FROM [dbo].[WorkOrderSettings] WITH(NOLOCK) WHERE [WorkOrderTypeId] = @WorkOrderTypeId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

	--IF(ISNULL(@TearDownTypes,'') <> '') 
	--BEGIN
	--	IF(ISNULL(@CommonTeardownTypeId,0) <> 0)
	--	BEGIN		
	--		IF ',' + @TearDownTypes + ',' NOT LIKE '%,' + CAST(@CommonTeardownTypeId AS VARCHAR) + ',%'
	--		BEGIN
	--			SET @TearDownTypes = @TearDownTypes + ',' + CAST(@CommonTeardownTypeId AS VARCHAR); 
	--		END
	--	END
	--END

	SELECT TOP 1  @CustomerFinancialId=[CustomerFinancialId],@CreditTermsId=[CreditTermsId] FROM [dbo].[CustomerFinancial] WITH(NOLOCK) WHERE [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
	
    -- Determine WorkOrder Code Prefix and Number
    IF @WorkOrderTypeId = @Customer -- Customer
    BEGIN
        SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @WorkOrderCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
    END
    ELSE IF @WorkOrderTypeId = @Internal -- Internal
    BEGIN
        SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @InternalWorkOrderCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
    END
	ELSE IF @WorkOrderTypeId = @TearDown -- TearDown
    BEGIN
        SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @TearDownWorkOrderCodePrefix AND MasterCompanyId = @MasterCompanyId;
    END
	ELSE IF @WorkOrderTypeId = @ShopServices -- ShopServices
    BEGIN
        SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @ShopServiceWorkOrderCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
    END
    -- Repeat for other WorkOrderTypes...

    -- Check for current number and increment
    IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
    BEGIN
        SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
        IF @CurrentNo > 0
        BEGIN
            SET @CurrentNo = @CurrentNo + 1;
            UPDATE [dbo].[CodePrefixes] 
            SET [CurrentNummber] = @CurrentNo
            WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
        END
        ELSE
        BEGIN
            SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0)  FROM [dbo].[CodePrefixes] WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
            UPDATE [dbo].[CodePrefixes]
            SET [CurrentNummber] = @CurrentNo 
            WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
        END
		-- Generate Work Order Number
		SET @WorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
    END
	ELSE
	BEGIN
		-- Generate Work Order Number
		SET @WorkOrderNum = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
	END

	IF(@CustomerFinancialId > 0 AND @CreditTermsId > 0)
	BEGIN			
		SELECT @PercentId=[PercentId],@Days=[Days],@NetDays=[NetDays] FROM [dbo].[CreditTerms] WITH(NOLOCK) WHERE [CreditTermsId]=@CreditTermsId AND [MasterCompanyId]=@MasterCompanyId AND [IsActive]=1 AND [IsDeleted]=0;
	END

    -- Insert or Update WorkOrder table (simplified)   

	INSERT INTO [dbo].[WorkOrder]([WorkOrderNum],[IsSinglePN],[WorkOrderTypeId],[OpenDate],[CustomerId],[WorkOrderStatusId],[EmployeeId],[MasterCompanyId],[CreatedBy],[UpdatedBy],
	            [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[SalesPersonId],[CSRId],[ReceivingCustomerWorkId],[Memo],[Notes],[CustomerContactId],[CustomerName],[CustomerType],
                [CreditLimit],[CreditTerms],[TearDownTypes],[RMAHeaderId],[IsWarranty],[IsAccepted],[ReasonId],[Reason],[CreditTermId],[IsManualForm],[PercentId],[Days],[NetDays],
                [WorkOrderType],[FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate],[WorkOrderFormTypeId],[IsWoAlwaysOrOndemandId],[EnforceMpnPickTicketConfirmation],
				[SecondarySalesPersonId],[SalesAgentID],[IsFromAircraft],[MtcCategoryId])
         VALUES (@WorkOrderNum,@IsSinglePN,@WorkOrderTypeId,GETUTCDATE(),@CustomerId,@WorkOrderStatusId,@EmployeeId,@MasterCompanyId,@CreatedBy,@UpdatedBy,
				 @CreatedDate,@UpdatedDate,1,0,@SalesPersonId,@CSRId,@ReceivingCustomerWorkId,@Memo,@Notes,@CustomerContactId,@CustomerName,@CustomerType,
				 @CreditLimit,@CreditTerms,@TearDownTypes,@RMAHeaderId,@IsWarranty,@IsAccepted,@ReasonId,@Reason,@CreditTermId,@IsManualForm,@PercentId,@Days,@NetDays,
				 @WorkOrderType,@FunctionalCurrencyId,@ReportCurrencyId,@ForeignExchangeRate,@WorkOrderFormTypeId,@IsWoAlwaysOrOndemandId,@EnforceMpnPickTicketConfirmation,
				 @SecondarySalesPersonId,@SalesAgentID,@IsFromAircraft,@MtcCategoryId)

	SET @WorkOrderId = SCOPE_IDENTITY();	
	
	EXEC [dbo].[USP_UpdateSalesPersonDetails] @WorkOrderId,@CustomerId,@MasterCompanyId,@WorkOrderModuleID;
	
	SELECT TOP 1 @EmployeeExpertiseId = [EmployeeExpertiseId] FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE [EmpExpCode] = @EmpExpCode AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;

	INSERT INTO #tmprCreateWorkOrderPartNumber([ID],[WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId],Notes,[AircraftRegistryNumber],
		   [IsFromAircraft],[AircraftInstalledPartDetailsId],[CSN],[TSN],[CSO],[TSO],[AircraftSerialNumber])
	SELECT [ID],@WorkOrderId,[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
		   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
		   [UpdatedBy],@CreatedDate,@UpdatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
		   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
		   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
		   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
		   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId],Notes,[AircraftRegistryNumber],
		   [IsFromAircraft],[AircraftInstalledPartDetailsId],
		   @CSN,@TSN,@CSO,@TSO,[AircraftSerialNumber] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber    

	WHILE @MinId <= @TotalRecord
	BEGIN
		DECLARE @WorkflowId BIGINT = NULL,@TechnicianId BIGINT = NULL,@TechStationId BIGINT = NULL,@RevisedPartId BIGINT = NULL,@RevisedConditionId BIGINT = NULL,@ConditionId BIGINT = NULL
		DECLARE @RevisedItemmasterid BIGINT = NULL,@RevisedSerialNumber VARCHAR(50)=NULL,@SerialNumber VARCHAR(50)=NULL,@CurrentSerialNumber VARCHAR(100) = NULL
		DECLARE @RevisedPartNumber VARCHAR(50)=NULL,@PartNumber VARCHAR(200) = NULL,@PartAllowInvoiceBeforeShipping BIT = NULL,@StocklineCost DECIMAL(18,2) = 0
		DECLARE @IncomingPartNumber VARCHAR(50)=NULL,@OutGoingItemMasterId BIGINT = NULL,@OutGoingPartNumber VARCHAR(50)=NULL
		
		SELECT @WorkflowId = [WorkflowId],
			   @TechnicianId = [TechnicianId],
			   @TechStationId = [TechStationId],
			   @RevisedPartId = [RevisedPartId],
			   @RevisedConditionId = [RevisedConditionId],
			   @ConditionId = [ConditionId],
			   @RevisedItemmasterid = [RevisedItemmasterid],
			   @ItemMasterId = [ItemMasterId],
			   @RevisedSerialNumber = [RevisedSerialNumber],
			   @SerialNumber = [SerialNumber],
			   @CurrentSerialNumber = [CurrentSerialNumber],
			   @RevisedPartNumber = [RevisedPartNumber],			   
			   @PartNumber = [PartNumber],			 			  
			   @PartAllowInvoiceBeforeShipping = [AllowInvoiceBeforeShipping],
			   @StockLineId = [StockLineId],
			   @WorkOrderScopeId = [WorkOrderScopeId],
			   @ReceivingCustomerWorkId = [ReceivingCustomerWorkId]
		FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId
			   		
		SELECT @StocklineCost = [UnitCost] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

		IF(@ReceivingCustomerWorkId > 0)
		BEGIN
			SELECT @IncomingPartNumber = [PartNumber],@OutGoingItemMasterId = [OutGoingItemMasterId],@OutGoingPartNumber = [OutGoingPartNumber] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [ReceivingCustomerWorkId] = @ReceivingCustomerWorkId;
		END
		
		UPDATE #tmprCreateWorkOrderPartNumber 
		   SET [WorkflowId] =  CASE WHEN @WorkflowId = 0 THEN NULL ELSE @WorkflowId END,
			   [TechnicianId] = CASE WHEN @TechnicianId = 0 THEN NULL ELSE @TechnicianId END,
			   [TechStationId] = CASE WHEN @TechStationId = 0 THEN NULL ELSE @TechStationId END,
			   [RevisedPartId] = CASE WHEN @RevisedPartId = 0 THEN NULL ELSE @RevisedPartId END,
			   [RevisedConditionId] = CASE WHEN @RevisedConditionId > 0 THEN @RevisedConditionId ELSE @ConditionId END,
			   [RevisedItemmasterid] = CASE WHEN @RevisedItemmasterid > 0 THEN @RevisedItemmasterid ELSE CASE WHEN @ReceivingCustomerWorkId > 0 THEN @OutGoingItemMasterId ELSE @ItemMasterId END END,
			   [RevisedSerialNumber] = CASE WHEN  COALESCE(@RevisedSerialNumber, '') != '' THEN @RevisedSerialNumber ELSE @SerialNumber END,
			   [CurrentSerialNumber] = CASE WHEN COALESCE(@CurrentSerialNumber, '') != '' THEN @CurrentSerialNumber ELSE @SerialNumber END,
			   [RevisedPartNumber] = CASE WHEN COALESCE(@RevisedPartNumber, '') != '' THEN @RevisedPartNumber ELSE CASE WHEN @ReceivingCustomerWorkId > 0 THEN @OutGoingPartNumber ELSE @PartNumber END END,
			   [CreatedBy] = @CreatedBy,
			   [UpdatedBy] = @CreatedBy,
			   [CreatedDate] = @CreatedDate,
			   [UpdatedDate] = @UpdatedDate,
			   [AssignDate] =  CASE WHEN @TechnicianId > 0 THEN GETUTCDATE() ELSE NULL END,
			   [IsActive] = 1,
			   [IsDeleted] = 0,
			   [MasterCompanyId] = @MasterCompanyId,
			   [ExpertiseId] = CASE WHEN @EmployeeExpertiseId > 0 THEN @EmployeeExpertiseId ELSE NULL END,
			   [IsTraveler] = CASE WHEN  @IsTraveler IS NULL THEN 0 ELSE @IsTraveler END,
			   [AllowInvoiceBeforeShipping] = CASE WHEN @PartAllowInvoiceBeforeShipping IS NULL THEN @AllowInvoiceBeforeShipping ELSE @PartAllowInvoiceBeforeShipping END,	
			   [StocklineCost] = CASE WHEN @StockLineId > 0 THEN @StocklineCost ELSE [StocklineCost] END
		 WHERE [PKID] = @MinId
			
			IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ItemMasterId=@ItemMasterId and ISNULL(IsVersionIncrease,0)=0))            
			BEGIN            
				SELECT top 1 @TravelerName= CONVERT(varchar(250),ISNULL(TravelerId,'')) FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ItemMasterId=@ItemMasterId and ISNULL(IsVersionIncrease,0)=0            
			END            
			ELSE IF(EXISTS (SELECT 1 FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ISNULL(IsVersionIncrease,0)=0))            
			BEGIN            
				SELECT top 1 @TravelerName= CONVERT(varchar(250),ISNULL(TravelerId,'')) FROM dbo.Traveler_Setup WITH(NOLOCK) WHERE WorkScopeId = @WorkOrderScopeId and ISNULL(ItemMasterId,0)=0 and ISNULL(IsVersionIncrease,0)=0            
			END 
				IF((@IsSinglePN = 1 AND (@TravelerName = '' OR @TravelerName = '0')) OR @IsSinglePN = 0)
				BEGIN
					/***** Prefixes : Reference Number*******/		   			
					IF OBJECT_ID(N'tempdb..#tmpCodePrefixesWPNUInserted') IS NOT NULL
					BEGIN
						DROP TABLE #tmpCodePrefixesWPNUInserted
					END
	
					CREATE TABLE #tmpCodePrefixesWPNUInserted
					(
							ID BIGINT NOT NULL IDENTITY, 
							CodePrefixId BIGINT NULL,
							CodeTypeId BIGINT NULL,
							CurrentNumber BIGINT NULL,
							CodePrefix VARCHAR(50) NULL,
							CodeSufix VARCHAR(50) NULL,
							StartsFrom BIGINT NULL,
					)

					INSERT INTO #tmpCodePrefixesWPNUInserted (CodePrefixId,CodeTypeId,CurrentNumber, CodePrefix, CodeSufix, StartsFrom) 
					SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom 
					FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT WITH (NOLOCK) ON CP.CodeTypeId = CT.CodeTypeId
					WHERE CT.CodeTypeId = @TravelerCodeTypeId
					AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;
					IF (EXISTS (SELECT 1 FROM #tmpCodePrefixesWPNUInserted WHERE CodeTypeId = @TravelerCodeTypeId))
					BEGIN
						SET @CurrentNumber = (SELECT CASE WHEN CurrentNumber > 0 THEN CAST(CurrentNumber AS BIGINT) ELSE CAST(StartsFrom AS BIGINT) END 
						FROM #tmpCodePrefixesWPNUInserted WHERE CodeTypeId = @TravelerCodeTypeId)
					
						SET @TravelerName = (SELECT * FROM dbo.[udfGenerateCodeNumberWithOutDash](
										ISNULL(@CurrentNumber,0)+1,
										(SELECT CodePrefix FROM #tmpCodePrefixesWPNUInserted WHERE CodeTypeId = @TravelerCodeTypeId),
										(SELECT CodeSufix FROM #tmpCodePrefixesWPNUInserted WHERE CodeTypeId = @TravelerCodeTypeId)))
						UPDATE dbo.CodePrefixes SEt CurrentNummber = ISNULL(@CurrentNumber,0)+1 WHERE CodePrefixId = (SELECT TOP 1 CodePrefixId FROM #tmpCodePrefixesWPNUInserted)
					END
					/******End Prefixes******/	

				END

		INSERT INTO [dbo].[WorkOrderPartNumber]([WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
	            [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],
				[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],
				[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],
				[Level1],[Level2],[Level3],[Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],
				[AllowInvoiceBeforeShipping],[WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],
				[PartNumber],[PartDescription],[WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],TravelerNumber,Notes,
				[CSN],[TSN],[CSO],[TSO],[IncomingPartNumber],[AircraftRegistryNumber],[IsFromAircraft],[AircraftInstalledPartDetailsId],[AircraftSerialNumber])
		 SELECT [WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
	            [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],
				[CreatedBy],[UpdatedBy],@CreatedDate,@UpdatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],
				[IsMPNContract],[ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],
				[Level1],[Level2],[Level3],[Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],
				[AllowInvoiceBeforeShipping],[WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],
				[PartNumber],[PartDescription],[WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],@TravelerName,Notes,
				[CSN],[TSN],[CSO],[TSO],CASE WHEN @IncomingPartNumber IS NOT NULL THEN @IncomingPartNumber ELSE [PartNumber] END,[AircraftRegistryNumber],[IsFromAircraft],[AircraftInstalledPartDetailsId],[AircraftSerialNumber]
		   FROM #tmprCreateWorkOrderPartNumber 
		  WHERE [PKID] = @MinId

		SET @ID = SCOPE_IDENTITY();	

		UPDATE #tmprCreateWorkOrderPartNumber SET [ID] = @ID WHERE [PKID] = @MinId
		   			 
		SET @MinId = @MinId + 1
	END

	SELECT TOP 1 @ItemMasterId=[ItemMasterId],@ID=[ID] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
	
	SELECT @PartNumber = [PartNumber] FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId] = @ItemMasterId;

	IF ISNULL(@IsFromLot, 0) = 0
	BEGIN
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @CreateWO;
	END
	ELSE IF ISNULL(@IsFromLot, 0) = 1 
	BEGIN
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @CreateWOFromLot;
	END
	ELSE 
	BEGIN
		SELECT TOP 1 @TemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @CreateWO;
	END

	SET @TemplateBody = REPLACE(@TemplateBody, '##WONum##', @WorkOrderNum)
	SET @TemplateBody = REPLACE(@TemplateBody, '#MPN#', @PartNumber)
	
	SET @CreatedDate = GETUTCDATE()
	
	EXEC [dbo].[USP_History] @WorkOrderModuleID,@WorkOrderId,0,@ID,'',@WorkOrderNum,@TemplateBody,'CreateWorkOrder',@MasterCompanyId,@CreatedBy,@CreatedDate,@CreatedBy,@CreatedDate

	IF(@RMAHeaderId > 0)
	BEGIN
		UPDATE [dbo].[CustomerRMAHeader] SET [WorkOrderId]=@WorkOrderId,[WorkOrderNum]=@WorkOrderNum,[ReturnDate]=GETUTCDATE() WHERE [RMAHeaderId] = @RMAHeaderId;
	END

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkOrderPartNumber   
	WHILE @MinId <= @TotalRecord
	BEGIN	    
		DECLARE @MasterPartId BIGINT = NULL,@QuantityAvailable INT=0,@QuantityReserved INT=0,@InvoiceId INT=0,@ValidDate DATETIME2(7)=NULL,@ValidDays INT=0,@WorkOrderStageId BIGINT=NULL
		DECLARE @PartStockLineId BIGINT = NULL,@WorkOrderPartNumberId BIGINT = NULL,@RMANumber VARCHAR(50)=NULL,@MSDetailsId BIGINT=NULL
		DECLARE @WorkScopeDescription VARCHAR(500)=NULL,@ReceiverNumber VARCHAR(50),@PartSerialNumber VARCHAR(100)=''
		DECLARE @PartReceivingCustomerWorkId BIGINT = NULL,@PartRMAHeaderId BIGINT = NULL,@QuantityOnHand INT=0,@QuantityIssued INT=0
		DECLARE @InvoiceNo VARCHAR(256) = NULL,@InvoiceDate DATETIME2(7)=NULL,@RMACustomerId BIGINT = NULL,@RMACustomerName VARCHAR(100)=NULL,@RMACustomerCode VARCHAR(100)=NULL
		DECLARE @ContactInfo VARCHAR(150)=NULL,@RMACustomerContactId BIGINT=NULL,@RequestedId BIGINT = NULL,@Requestedby VARCHAR(50)=NULL,@ApprovedbyId BIGINT=NULL
		DECLARE @Approvedby VARCHAR(50)=NULL,@ApprovedDate DATETIME2(7)=NULL,@ReturnDate DATETIME2(7)=NULL,@ManagementStructureId BIGINT=NULL,@ReferenceId BIGINT=NULL,@Result BIGINT=0
		DECLARE @WorkOrderCustomerInvoiceTypeEnum INT=1

		SELECT @WorkOrderPartNumberId = [ID],
		       @MasterPartId = [MasterPartId],
			   @ItemMasterId = [MasterPartId],
		       @WorkOrderScopeId = [WorkOrderScopeId],
			   @PartReceivingCustomerWorkId = [ReceivingCustomerWorkId],
			   @PartStockLineId = [StockLineId],
			   @PartSerialNumber = [SerialNumber],
			   @WorkOrderStageId = [WorkOrderStageId],
			   @ManagementStructureId = [ManagementStructureId],
			   @WorkflowId = [WorkflowId]
 		FROM #tmprCreateWorkOrderPartNumber WHERE [PKID] = @MinId		

		SELECT @WorkScopeDescription = [Description] FROM [dbo].[WorkScope] WITH(NOLOCK) WHERE [WorkScopeId] = @WorkOrderScopeId;

		UPDATE #tmprCreateWorkOrderPartNumber 
		   SET [ItemMasterId] =  @ItemMasterId,
		       [WorkScope] = @WorkScopeDescription
		 WHERE [PKID] = @MinId

		IF(@PartReceivingCustomerWorkId > 0) 
		BEGIN
			-- Updating Work Order Id in Stockline Table
			
			SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),@QuantityReserved = [QuantityReserved],@QuantityOnHand=[QuantityOnHand],@QuantityIssued=[QuantityIssued] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;
			
			UPDATE [dbo].[StockLine]
			   SET [WorkOrderId] = @WorkOrderId,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy,
				   [WorkOrderPartNoId] = @WorkOrderPartNumberId,
				   [QuantityAvailable] = @QuantityAvailable - @NPMStockQTY,
				   [QuantityReserved] = @QuantityReserved + @NPMStockQTY 
			 WHERE [StockLineId] = @PartStockLineId;

			-- -- STOCKLINE RESERVE HISTORY
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @PartStockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryReserveActionEnum,@NPMStockQTY,@CreatedBy;

			-- TEARDOWN WORK ORDER ACCOUNTING ENTRY
			IF @WorkOrderTypeId = @TearDown -- TEARDOWN
			BEGIN
				SELECT @QuantityReserved = [QuantityReserved] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;

				UPDATE [dbo].[StockLine]
				   SET [QuantityReserved] = @QuantityReserved - @NPMStockQTY,
				       [QuantityOnHand] = @QuantityOnHand - @NPMStockQTY,
					   [QuantityIssued] = @QuantityIssued + @NPMStockQTY
				 WHERE [StockLineId] = @PartStockLineId;				

				 -- STOCKLINE ISSUE HISTORY
				 EXEC [dbo].[USP_AddUpdateStocklineHistory] @PartStockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryIssueActionEnum,@NPMStockQTY,@CreatedBy;
			END

			EXEC [dbo].[UpdateStocklineColumnsWithId] @PartStockLineId;

           -- Updating Work Order Id in Receiving Customer Table

			UPDATE [dbo].[ReceivingCustomerWork]
			   SET [WorkOrderId] = @WorkOrderId,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy
             WHERE [ReceivingCustomerWorkId] = @PartReceivingCustomerWorkId		 			 
			
		END
		ELSE IF(@PartStockLineId > 0)
		BEGIN
		 -- Updating Work Order Id in Stockline Table
			DECLARE @TotalRecordRMA INT = 0,@MinIdRMA BIGINT = 1,@RMADeatilsId BIGINT = NULL

			SELECT @QuantityAvailable = ISNULL([QuantityAvailable],0),@QuantityReserved = [QuantityReserved],@QuantityOnHand=[QuantityOnHand],@QuantityIssued=[QuantityIssued],@ReceiverNumber = [ReceiverNumber] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;
			
			UPDATE [dbo].[StockLine]
			   SET [WorkOrderId] = @WorkOrderId,
			       [UpdatedDate] = @UpdatedDate,
				   [UpdatedBy] = @UpdatedBy,
				   [WorkOrderPartNoId] = @WorkOrderPartNumberId,
				   [QuantityAvailable] = @QuantityAvailable - @NPMStockQTY,
				   [QuantityReserved] = @QuantityReserved + @NPMStockQTY
			 WHERE [StockLineId] = @PartStockLineId;

		    -- STOCKLINE RESERVE HISTORY
			EXEC [dbo].[USP_AddUpdateStocklineHistory] @PartStockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryReserveActionEnum,@NPMStockQTY,@CreatedBy;

			-- TEARDOWN WORK ORDER ACCOUNTING ENTRY
			IF @WorkOrderTypeId = @TearDown -- TEARDOWN
			BEGIN
				SELECT @QuantityReserved = [QuantityReserved] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;

				UPDATE [dbo].[StockLine]
				   SET [QuantityReserved] = @QuantityReserved - @NPMStockQTY,
				       [QuantityOnHand] = @QuantityOnHand - @NPMStockQTY,
					   [QuantityIssued] = @QuantityIssued + @NPMStockQTY
				 WHERE [StockLineId] = @PartStockLineId;
				 
				 -- STOCKLINE ISSUE HISTORY
				 EXEC [dbo].[USP_AddUpdateStocklineHistory] @PartStockLineId,@WorkOrderModuleID,@WorkOrderId,NULL,NULL,@StocklineHistoryIssueActionEnum,@NPMStockQTY,@CreatedBy;
			END

			EXEC [dbo].[UpdateStocklineColumnsWithId] @PartStockLineId;

			SELECT TOP 1 @PartReceivingCustomerWorkId = [ReceivingCustomerWorkId] FROM [dbo].[ReceivingCustomerWork] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;

			-- Updating Work Order Id in Receiving Customer Table

			IF(@PartReceivingCustomerWorkId > 0) 
			BEGIN
				UPDATE [dbo].[ReceivingCustomerWork]
				   SET [WorkOrderId] = @WorkOrderId,
					   [UpdatedDate] = @UpdatedDate,
					   [UpdatedBy] = @UpdatedBy
				 WHERE [ReceivingCustomerWorkId] = @PartReceivingCustomerWorkId
			END
					   
		    INSERT INTO #tmprCreateWorkOrderCustomerRMADeatils([RMADeatilsId])
	        SELECT [RMADeatilsId] FROM [dbo].[CustomerRMADeatils] WITH(NOLOCK) WHERE [RMAHeaderId] = @RMAHeaderId AND [ItemMasterId] = @MasterPartId;
			
			SELECT @TotalRecordRMA = COUNT(*), @MinIdRMA = MIN([RMAID]) FROM #tmprCreateWorkOrderCustomerRMADeatils

			WHILE @MinIdRMA <= @TotalRecordRMA
			BEGIN	
				SELECT @RMADeatilsId = [RMADeatilsId] FROM #tmprCreateWorkOrderCustomerRMADeatils WHERE [RMAID] = @MinId

				UPDATE [dbo].[CustomerRMADeatils]
				   SET [WorkOrderNum] = @WorkOrderNum,
				       [ReturnDate] = @UpdatedDate,
					   [ReceiverNum] = @ReceiverNumber
				 WHERE [RMADeatilsId] = @RMADeatilsId;

				SET @MinIdRMA = @MinIdRMA + 1
			END
			
			DELETE FROM #tmprCreateWorkOrderCustomerRMADeatils
		END
		
		-- Checking is Possible Warranty & Accepted Warranty
		IF (@ReasonId = 0 AND @IsWarranty = 1)
		BEGIN
			-- START Check for RMA is exist or not if not will add new RMA otherwise update wonumber.
			SELECT @ReceiverNumber = [ReceiverNumber] FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @PartStockLineId;

			SELECT TOP(1) @PartRMAHeaderId = [RMAHeaderId] FROM [dbo].[CustomerRMADeatils] WITH(NOLOCK) WHERE [SerialNumber] = @PartSerialNumber AND [ItemMasterId] = @ItemMasterId;

			SELECT @RMANumber = [RMANumber],@RequestedId = [RequestedId],@Requestedby=[Requestedby], 
			       @ApprovedbyId=[ApprovedbyId],@Approvedby=[Approvedby],@ApprovedDate=[ApprovedDate],@ReturnDate = [ReturnDate]				   
			  FROM [dbo].[CustomerRMAHeader] WITH(NOLOCK) WHERE [RMAHeaderId] = @PartRMAHeaderId AND [RMAStatusId] = @OpenRMAStatus
			
			SET @RequestedId = ISNULL(@RequestedId, 0);

			IF(@RMANumber IS NOT NULL AND @RMANumber <> '')
			BEGIN
			    -- Update Rma Header Data
				UPDATE [dbo].[CustomerRMAHeader]
				   SET [WorkOrderId] = @WorkOrderId,
					   [WorkOrderNum] = @WorkOrderNum,
					   [ReturnDate] = @UpdatedDate,
                       [ReceiverNum] = @ReceiverNumber,
                       [RMAStatusId] = @CustomerRMAItemReturnedStatus,
                       [RMAStatus] = 'Item Returned'
			     WHERE [RMAHeaderId] = @PartRMAHeaderId
				 -- Update RMA Detail Data
				INSERT INTO #tmprCreateWorkOrderCustomerRMADeatils([RMADeatilsId])
				SELECT [RMADeatilsId] FROM [dbo].[CustomerRMADeatils] WITH(NOLOCK) WHERE [RMAHeaderId] = @PartRMAHeaderId;

				SELECT @TotalRecordRMA = COUNT(*), @MinIdRMA = MIN([RMAID]) FROM #tmprCreateWorkOrderCustomerRMADeatils

				WHILE @MinIdRMA <= @TotalRecordRMA
				BEGIN	
					SELECT @RMADeatilsId = [RMADeatilsId] FROM #tmprCreateWorkOrderCustomerRMADeatils WHERE [RMAID] = @MinId

					UPDATE [dbo].[CustomerRMADeatils]
					   SET [WorkOrderNum] = @WorkOrderNum,
						   [ReturnDate] = @UpdatedDate,
						   [ReceiverNum] = @ReceiverNumber,
						   [UpdatedBy] = @UpdatedBy,
						   [CreatedBy] = @CreatedBy
					 WHERE [RMADeatilsId] = @RMADeatilsId;

					SET @MinIdRMA = @MinIdRMA + 1
				END
				DELETE FROM #tmprCreateWorkOrderCustomerRMADeatils
			END
			ELSE
			BEGIN
				IF(@PartSerialNumber <> '' AND @PartSerialNumber IS NOT NULL)
				BEGIN
				    DECLARE @OLDWorkOrderId BIGINT=0

					INSERT INTO #tmprCheckWorkOrderForSerialNumber
					EXEC [dbo].[USP_CheckWorkOrderForSerialNumber] @ItemMasterId,@PartSerialNumber,@MasterCompanyId		
					
					SELECT @OLDWorkOrderId = [WorkOrderId] FROM #tmprCheckWorkOrderForSerialNumber
					IF(@OLDWorkOrderId > 0)
					BEGIN
						INSERT INTO #tmprOldWorkOrderForBillingInvoicedData([InvoiceId],[InvoiceNo],[InvoiceStatus],[InvoiceDate],[OrderNumber],[CustomerName],[CustomerType],[InvoiceAmt],
						       [isWorkOrder],[ReferenceId],[ManagementStructureId],[ContactInfo],[CustomerContactId],[RMAReasonId],[RMAReason],[RMAStatusId],[RMAStatus],[ValidDays],
							   [MasterCompanyId],[CustomerId],[CustomerCode],[AddressCount],[PartCount])
						EXEC [dbo].[USP_GetOldWorkOrderForBillingInvoicedData] @OLDWorkOrderId

						-- Add new Customer RMA & Part Data
						
						SELECT TOP 1 @InvoiceId=[InvoiceId],@ValidDays=[ValidDays],@InvoiceNo=[InvoiceNo],@InvoiceDate=[InvoiceDate],@RMACustomerId=[CustomerId],@RMACustomerName=[CustomerName],
						             @RMACustomerCode=[CustomerCode],@ContactInfo=[ContactInfo],@RMACustomerContactId=[CustomerContactId],@ReferenceId=[ReferenceId] 
									 FROM #tmprOldWorkOrderForBillingInvoicedData

						IF(@InvoiceId > 0)
						BEGIN							
							SET @ValidDate = GETUTCDATE();
							IF(@ValidDays > 0)
							BEGIN									
								SET @ValidDate = DATEADD(DAY, @ValidDays, @ValidDate)
							END
							-- Add header Data
							IF(@PartRMAHeaderId > 0)
							BEGIN
								EXEC [dbo].[CreateUpdateCustomerRMAHeader] @PartRMAHeaderId,@RMANumber,@InvoiceId,@InvoiceNo,@InvoiceDate,@CustomerRMAItemReturnedStatus,'Item Returned',@RMACustomerId,@RMACustomerName,@RMACustomerCode,
								     @ContactInfo,@RMACustomerContactId,1,@ValidDate,@RequestedId,@Requestedby,@ApprovedbyId,@Approvedby,@ApprovedDate,@ReturnDate,@WorkOrderId,@WorkOrderNum,@ReceiverNumber,'','',
									 @ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@UpdatedDate,1,@ReferenceId,0,@Result OUTPUT

								EXEC dbo.[PROCAddUpdateCustomerRMAMSData] @PartRMAHeaderId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CustomerRMAHeaderManagementStructureModule,2,@MSDetailsId OUTPUT
                            END   
							ELSE
							BEGIN
								SELECT TOP 1 @CodePrefix = [CodePrefix], @CodeSuffix = [CodeSufix] FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [CodeTypeId] = @RMANumberCodePrefix AND [MasterCompanyId] = @MasterCompanyId;
								-- Check for current number and increment
								IF @CodePrefix IS NOT NULL AND @CodePrefix <> ''
								BEGIN
										SELECT @CurrentNo = ISNULL([CurrentNummber], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;        
										IF @CurrentNo > 0
										BEGIN
											SET @CurrentNo = @CurrentNo + 1;
											UPDATE [dbo].[CodePrefixes] 
											SET [CurrentNummber] = @CurrentNo
											WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
										END
										ELSE
										BEGIN
											SET @CurrentNo = (SELECT ISNULL([StartsFrom], 0) FROM [dbo].[CodePrefixes] WITH(NOLOCK) WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId) + 1;
											UPDATE [dbo].[CodePrefixes]
											SET [CurrentNummber] = @CurrentNo 
											WHERE [CodePrefix] = @CodePrefix AND [MasterCompanyId] = @MasterCompanyId;
										END
										-- Generate RMA Number
										SET @RMANumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, ISNULL(@CodePrefix,''),ISNULL(@CodeSuffix, '')))
								END
								ELSE
								BEGIN
									-- Generate RMA Number
									SET @RMANumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(@CurrentNo, '',''))
								END

								EXEC [dbo].[CreateUpdateCustomerRMAHeader] 0,@RMANumber,@InvoiceId,@InvoiceNo,@InvoiceDate,@CustomerRMAItemReturnedStatus,'Item Returned',@RMACustomerId,@RMACustomerName,@RMACustomerCode,
								      @ContactInfo,@RMACustomerContactId,1,@ValidDate,@RequestedId,@Requestedby,@ApprovedbyId,@Approvedby,@ApprovedDate,@ReturnDate,@WorkOrderId,@WorkOrderNum,@ReceiverNumber,'','',
								      @ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@UpdatedDate,1,@ReferenceId,0,@Result OUTPUT
							    SET @PartRMAHeaderId = @Result;
								EXEC [dbo].[PROCAddUpdateCustomerRMAMSData] @PartRMAHeaderId,@ManagementStructureId,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CustomerRMAHeaderManagementStructureModule,1,@MSDetailsId OUTPUT									
							END	
							
							INSERT INTO #tmprGetCustomerRMAPartsDetails([InvoiceId],[InvoiceNo],[BillingInvoicingItemId],[InvoiceStatus],[InvoiceDate],[ReferenceNo],[ItemMasterId],
								   [PartNumber],[PartDescription],[CustPartNumber],[CustomerReference],[SerialNumber],[StocklineNumber],[StocklineId],[ControlNumber],[ControlId],[Qty],
								   [UnitPrice],[Amount],[RMAReasonId],[RMAReason],[RMAStatusId],[RMAStatus],[RMAValiddate],[IsWorkOrder],[ReferenceId],[PartsUnitCost],[PartsRevenue],
								   [LaborRevenue],[MiscRevenue],[FreightRevenue],[SubTotal],[SalesTax],[OtherTax],[GrandTotal],[InvoiceAmt],[COGSParts],[COGSLabor],[COGSOverHeadCost],
								   [COGSInventory],[COGSPartsUnitCost],[RMADeatilsId],[RMAHeaderId],[Notes],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],
								   [IsDeleted],[isSerialized],[InvoiceQty],[ManufacturerName],[AltPartNumber],[InvoiceTypeId])
							  EXEC [dbo].[sp_GetCustomerRMAPartsDetails] @InvoiceId,1,@PartRMAHeaderId,1,@WorkOrderCustomerInvoiceTypeEnum			
								
							DECLARE @RMAReasonId INT=0
								
							SELECT TOP 1 @RMAReasonId = [RMAReasonId] FROM [dbo].[RMACreditMemoSettings] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1
							 
							IF(@RMAReasonId > 0)
								SET @RMAReasonId = @RMAReasonId;
							ELSE 
								SET @RMAReasonId = 1;
								
							INSERT INTO #tbl_CustomerRMADeatilsType([RMADeatilsId],[RMAHeaderId],[ItemMasterId],[PartNumber],[PartDescription],[AltPartNumber],[CustPartNumber],[SerialNumber],
		                               [StocklineId],[StocklineNumber],[ControlNumber],[ControlId],[ReferenceId],[ReferenceNo],[Qty],[UnitPrice],[Amount],[RMAReasonId],[RMAReason],[Notes],[isWorkOrder],
		                               [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InvoiceId],[BillingInvoicingItemId],[CustomerReference],[InvoiceQty],
		                               [ReturnDate],[WorkOrderNum],[ReceiverNum])
							SELECT [RMADeatilsId],@PartRMAHeaderId,[ItemMasterId],[PartNumber],[PartDescription],[AltPartNumber],[CustPartNumber],[SerialNumber],
     		                       [StocklineId],[StocklineNumber],[ControlNumber],[ControlId],[ReferenceId],[ReferenceNo],[Qty],[UnitPrice],[Amount],@RMAReasonId,[RMAReason],[Notes],[IsWorkOrder],
							       [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InvoiceId],[BillingInvoicingItemId],[CustomerReference],[InvoiceQty],
								   GETUTCDATE(),@WorkOrderNum,@ReceiverNumber								
							FROM #tmprGetCustomerRMAPartsDetails WHERE [RMADID] = 1;

							DECLARE @CustomerRMADeatils CustomerRMADeatilsType;
							
							INSERT INTO @CustomerRMADeatils([RMADeatilsId],[RMAHeaderId],[ItemMasterId],[PartNumber],[PartDescription],[AltPartNumber],[CustPartNumber],[SerialNumber],
		                               [StocklineId],[StocklineNumber],[ControlNumber],[ControlId],[ReferenceId],[ReferenceNo],[Qty],[UnitPrice],[Amount],[RMAReasonId],[RMAReason],[Notes],[isWorkOrder],
		                               [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InvoiceId],[BillingInvoicingItemId],[CustomerReference],[InvoiceQty],
		                               [ReturnDate],[WorkOrderNum],[ReceiverNum])
							SELECT [RMADeatilsId],@PartRMAHeaderId,[ItemMasterId],[PartNumber],[PartDescription],[AltPartNumber],[CustPartNumber],[SerialNumber],
     		                       [StocklineId],[StocklineNumber],[ControlNumber],[ControlId],[ReferenceId],[ReferenceNo],[Qty],[UnitPrice],[Amount],@RMAReasonId,[RMAReason],[Notes],[IsWorkOrder],
							       [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[InvoiceId],[BillingInvoicingItemId],[CustomerReference],[InvoiceQty],
								   GETUTCDATE(),@WorkOrderNum,@ReceiverNumber								
							FROM #tmprGetCustomerRMAPartsDetails WHERE [RMADID] = 1;
																								
							EXEC [dbo].[usp_SaveRMAPartDetails] @CustomerRMADeatils,@StocklineManagementStructureModule
							
							DELETE FROM #tbl_CustomerRMADeatilsType
							
							DELETE FROM #tmprGetCustomerRMAPartsDetails
						END	
						
						DELETE FROM #tmprOldWorkOrderForBillingInvoicedData
					END
					DELETE FROM #tmprCheckWorkOrderForSerialNumber
				END
			END
		END

		EXEC [dbo].[UpdateWorkOrderPartNumberColumnsWithId] @WorkOrderPartNumberId;

		EXEC [dbo].[USP_AddEdit_WorkOrderTurnArroundTime] @WorkOrderPartNumberId,@WorkOrderStageId,@CreatedBy

		EXEC [dbo].[USP_SaveWOMSDetails] @WorkOrderMPNManagementStructureModule,@WorkOrderPartNumberId, @ManagementStructureId, @MasterCompanyId, @UpdatedBy, @MSDetailsId OUTPUT

		IF(@WorkflowId > 0)
		BEGIN
		    DECLARE @NewWorkFlowName VARCHAR(50)='',@AddWorkFlow VARCHAR(20)='AddWorkFlow',@WorkFlowTemplateBody VARCHAR(MAX)=''
			
			SELECT @PartNumber=ISNULL([PartNumber],'') FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE [ItemMasterId]=@ItemMasterId;
			SELECT @NewWorkFlowName=ISNULL([WorkOrderNumber],'') FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId;
			
			SELECT TOP 1 @WorkFlowTemplateBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @AddWorkFlow;

	        SET @WorkFlowTemplateBody = REPLACE(@WorkFlowTemplateBody, '##MPN##', @PartNumber)
	        SET @WorkFlowTemplateBody = REPLACE(@WorkFlowTemplateBody, '##NewWorkFlow##', @NewWorkFlowName)

			EXEC USP_History @WorkOrderModuleID,@WorkOrderId,0,@WorkOrderPartNumberId,'',@NewWorkFlowName,@WorkFlowTemplateBody,'AddWorkFlow',@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate;
			
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
		   		   
	-- CREATING WORKFLOWWORKORDER FROM WORK FLOW
	EXEC [dbo].[CreateWorkFlowWorkOrderFromWorkFlow] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,@MasterCompanyId;

	-- CREATING WORK ORDER SETTLEMENTDETAILS
	EXEC [dbo].[CreateWorkOrderSettlementDetails] @WorkOrderParts,@WorkOrderId,@WorkOrderTypeId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	-- CREATING WORK ORDER TEARDOWN FO REMOVAL REASON
	EXEC [dbo].[CreateCommonWorkOrderRemovalTearDown] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,@MasterCompanyId;

	-- COMPANY NOT AVAIALABLE WITH MASTERCOMPANYCODE LIKE 'AIR'
	-- CreateCommonWorkOrderCustomerInspecionTearDown(workOrder.PartNumbers, workOrder.WorkOrderId, workOrder.CreatedBy);

	-- CREATING TRAVELER LABOUR HEADER
	EXEC [dbo].[USP_CreateWorkOrderLaborHeader] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@MasterCompanyId;
	
	-- CREATING TRAVELER LABOUR TASK
	EXEC [dbo].[CreateTravelerLabourTask] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	-- UPDATING WORK ORDER FIELDS NAMES
	EXEC [dbo].[UpdateWorkOrderColumnsWithId] @WorkOrderId;

	-- CREATING WORK ORDER TASKS
	EXEC [dbo].[CreateWorkOrderTasks] @WorkOrderParts,@WorkOrderId,@WorkOrderTypeId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	-- CREATING STOCK LINE HISTORY TO RESERVE STOCKLINE 
	-- EXEC [dbo].[CreateStockLineHistory] @WorkOrderParts,@WorkOrderId,@CreatedBy,@CreatedDate,@MasterCompanyId;

	--*************** CREATE A WORK ORDER MATERIALS FOR SUB ASSY : BY RAJESH ***************
	EXEC [dbo].[CreateWorkOrderMaterialsforSubAssy] @WorkOrderParts,@WorkOrderId,@WorkOrderTypeId,@CreatedBy,@CreatedDate,@MasterCompanyId,@WorkOrderFormTypeId

	-- TEARDOWN WORK ORDER ACCOUNTING ENTRY
	IF @WorkOrderTypeId = @TearDown -- TearDown
    BEGIN
		DECLARE @DistributionMasterId BIGINT=NULL,@TotalParts INT = 0,@MinPartId BIGINT = 1

		SELECT TOP 1 @DistributionMasterId = [ID] FROM [dbo].[DistributionMaster] WITH(NOLOCK) WHERE [DistributionCode] = 'CREATETEARDOWNWO'

		IF(@DistributionMasterId > 0)
		BEGIN	
			IF OBJECT_ID(N'tempdb..#tmprTearDownWorkOrderAccounting') IS NOT NULL
			BEGIN
				DROP TABLE #tmprTearDownWorkOrderAccounting
			END

			CREATE TABLE #tmprTearDownWorkOrderAccounting
			(
				[PKID] [BIGINT] NOT NULL IDENTITY, 			
				[ID] [BIGINT] NULL,
				[StocklineId] [BIGINT] NULL			
			)

			INSERT INTO #tmprTearDownWorkOrderAccounting([ID],[StocklineId])
			SELECT [ID],[StocklineId] FROM @WorkOrderParts

			SELECT @TotalParts = COUNT(*), @MinPartId = MIN([PKID]) FROM #tmprTearDownWorkOrderAccounting  

			WHILE @MinPartId <= @TotalParts 
			BEGIN			
				SELECT @ID=[ID],@StocklineId=[StocklineId] FROM #tmprTearDownWorkOrderAccounting WHERE [PKID] = @MinPartId

				EXEC [dbo].[USP_TearDownWOBatchTriggerBasedonDistribution] @DistributionMasterId,@WorkOrderId,@ID,@StocklineId,@MasterCompanyId,@CreatedBy

				SET @MinPartId = @MinPartId + 1
			END

			IF OBJECT_ID(N'tempdb..#tmprTearDownWorkOrderAccounting') IS NOT NULL
			BEGIN
				DROP TABLE #tmprTearDownWorkOrderAccounting
			END
		END
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