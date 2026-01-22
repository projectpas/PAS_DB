/*************************************************************           
 ** File:   [dbo].[CreateWorkFlowWorkOrderFromWorkFlow]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Work Flow Work Order From WorkFlow
 ** Purpose:         
 ** Date:   17/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/03/2025   Moin Bloch    Created
	2    24/03/2025   Moin Bloch    ADDED CONDITION FOR UPDATE
	3    04/04/2025   Moin Bloch    Updated Fixed for WOQ Issue
     
--   EXEC [dbo].[CreateWorkFlowWorkOrderFromWorkFlow]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateWorkFlowWorkOrderFromWorkFlow]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@UpdatedBy VARCHAR(256),
@UpdatedDate DATETIME2(7),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
	
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
	
	IF OBJECT_ID(N'tempdb..#tmprCreateWorkFlowWorkOrderFromWorkFlow') IS NOT NULL
	BEGIN
		DROP TABLE #tmprCreateWorkFlowWorkOrderFromWorkFlow
	END

	CREATE TABLE #tmprCreateWorkFlowWorkOrderFromWorkFlow
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL,
		[WorkflowId] [BIGINT] NULL
	)

	--CREATE TABLE #tmprCreateWorkFlowWorkOrderFromWorkFlow
	--(
	--	[PKID] [BIGINT] NOT NULL IDENTITY, 
	--	[ID] [BIGINT] NULL,
	--	[WorkOrderId] [BIGINT] NULL,    
	--	[WorkOrderScopeId] [BIGINT] NULL,
	--	[EstimatedShipDate] [DATETIME2](7) NULL,
	--	[CustomerRequestDate] [DATETIME2](7) NULL,
	--	[PromisedDate] [DATETIME2](7) NULL,
	--	[EstimatedCompletionDate] [DATETIME2](7) NULL,
	--	[NTE] [VARCHAR](30),
	--	[Quantity] [INT] NULL,
	--	[StockLineId] [BIGINT] NULL,
	--	[CMMIds] [VARCHAR](256) NULL,
	--	[WorkflowId] [BIGINT] NULL,
	--	[WorkOrderStageId] [BIGINT] NULL,
	--	[WorkOrderStatusId] [BIGINT] NULL,
	--	[WorkOrderPriorityId] [BIGINT] NULL,
	--	[IsPMA] [BIT] NULL,
	--	[IsDER] [BIT] NULL,
	--	[TechStationId] [BIGINT] NULL,
	--	[TATDaysStandard] [INT] NULL,
	--	[MasterCompanyId] [INT] NULL,
	--	[CreatedBy] [VARCHAR](256) NULL,
	--	[UpdatedBy] [VARCHAR](256) NULL,
	--	[CreatedDate] [DATETIME2](7) NULL,
	--	[UpdatedDate] [DATETIME2](7) NULL,
	--	[IsActive] [BIT] NULL,
	--	[IsDeleted] [BIT] NULL,
	--	[ItemMasterId] [BIGINT] NULL,
	--	[TechnicianId] [BIGINT] NULL,  
	--	[ConditionId] [BIGINT] NULL,
	--	[TATDaysCurrent] [INT] NULL,
	--	[RevisedPartId] [BIGINT] NULL,
	--	[ManagementStructureId] [BIGINT] NULL,
	--	[IsMPNContract] [BIT] NULL,
	--	[ContractNo] [VARCHAR](20) NULL,
	--	[WorkScope] [VARCHAR](200) NULL,
	--	[isLocked] [BIT] NULL,
	--	[ReceivedDate] [DATETIME] NULL,
	--	[IsClosed] [BIT] NULL,
	--	[ACTailNum] [NVARCHAR](500) NULL,
	--	[ClosedDate] [DATETIME] NULL,
	--	[PDFPath] [NVARCHAR](MAX) NULL,
	--	[IsFinishGood] [BIT] NULL,
	--	[RevisedConditionId] [BIGINT] NULL,
	--	[CustomerReference] [VARCHAR](256) NULL,
	--	[Level1] [VARCHAR](200) NULL,
	--	[Level2] [VARCHAR](200) NULL,
	--	[Level3] [VARCHAR](200) NULL,
	--	[Level4] [VARCHAR](200) NULL,
	--	[AssignDate] [DATETIME2](7) NULL,
	--	[ReceivingCustomerWorkId] [BIGINT] NULL,
	--	[ExpertiseId] [SMALLINT] NULL,
	--	[RevisedItemmasterid] [BIGINT] NULL,
	--	[RevisedPartNumber] [VARCHAR](50) NULL,
	--	[RevisedPartDescription] [VARCHAR](MAX) NULL,
	--	[IsTraveler] [BIT] NULL,
	--	[AllowInvoiceBeforeShipping] [BIT] NULL,
	--	[WOFPrintDate] [DATETIME] NULL,
	--	[CurrentSerialNumber] [VARCHAR](100) NULL,
	--	[StocklineCost] [DECIMAL](18,2) NULL,
	--	[TendorStocklineCost] [DECIMAL](18,2) NULL,
	--	[RepairOrderId] [BIGINT] NULL,
	--	[RONumber] [VARCHAR](50) NULL,
	--	[RevisedSerialNumber] [VARCHAR](50) NULL,
	--	[IsROCreated] [BIT] NULL,
	--	[PartNumber] [VARCHAR](200) NULL,
	--	[PartDescription] [NVARCHAR](MAX) NULL,
	--	[WorkOrderStatus] [VARCHAR](MAX) NULL,
	--	[Priority] [VARCHAR](100) NULL,
	--	[WorkOrderStage] [VARCHAR](150) NULL,
	--	[ManufacturerName] [VARCHAR](250) NULL, 
	--	[TechName] [VARCHAR](100) NULL, 
	--	[EmployeeStation] [VARCHAR](100) NULL, 
	--	[PublicationNo] [VARCHAR](MAX) NULL,
	--	[SerialNumber] [VARCHAR](100) NULL,
	--	[MasterPartId] [BIGINT] NULL
	--)

	--IF OBJECT_ID(N'tempdb..#tmprWorkflowPublicationDashNumberForCreateWO') IS NOT NULL
	--BEGIN
	--	DROP TABLE #tmprWorkflowPublicationDashNumberForCreateWO
	--END

	--CREATE TABLE #tmprWorkflowPublicationDashNumberForCreateWO
	--(
	--	[WorkflowPublicationDashNumberId] [BIGINT] NULL,
	--	[WorkflowId] [BIGINT] NULL,
	--	[AircraftDashNumberId] [BIGINT] NULL,
	--	[TaskId] [BIGINT] NULL,
	--	[WorkflowPublicationsId] [BIGINT] NULL
	--)
		
	--CREATE TABLE #tmprWorkOrderChargesForCreateWO
	--(
	--	[WorkOrderChargesId] [bigint] IDENTITY(1,1) NOT NULL,
	--	[WorkOrderId] [bigint] NULL,
	--	[WorkFlowWorkOrderId] [bigint] NULL,
	--	[ChargesTypeId] [bigint] NULL,
	--	[VendorId] [bigint] NULL,
	--	[Quantity] [int] NULL,
	--	[MasterCompanyId] [int] NULL,
	--	[CreatedBy] [varchar](256) NULL,
	--	[UpdatedBy] [varchar](256) NULL,
	--	[CreatedDate] [datetime2](7) NULL,
	--	[UpdatedDate] [datetime2](7) NULL,
	--	[IsActive] [bit] NULL,
	--	[IsDeleted] [bit] NULL,
	--	[TaskId] [bigint] NULL,
	--	[Description] [varchar](256) NULL,
	--	[UnitCost] [decimal](20, 2) NULL,
	--	[ExtendedCost] [decimal](20, 2) NULL,
	--	[IsFromWorkFlow] [bit] NULL,
	--	[ReferenceNo] [varchar](20) NULL,
	--	[WOPartNoId] [bigint] NULL,
	--	[UOMId] [bigint] NULL
	--)
	
	--CREATE TABLE #tmprWorkOrderAssetsForCreateWO
	--(
	--	[WorkOrderAssetId] [bigint] IDENTITY(1,1) NOT NULL,
	--	[WorkOrderId] [bigint] NULL,
	--	[WorkFlowWorkOrderId] [bigint] NULL,
	--	[AssetRecordId] [bigint] NULL,
	--	[Quantity] [int] NULL,
	--	[MasterCompanyId] [int] NULL,
	--	[CreatedBy] [varchar](256) NULL,
	--	[UpdatedBy] [varchar](256) NULL,
	--	[CreatedDate] [datetime2](7) NULL,
	--	[UpdatedDate] [datetime2](7) NULL,
	--	[IsActive] [bit] NULL,
	--	[IsDeleted] [bit] NULL,
	--	[IsFromWorkFlow] [bit] NULL,
	--	[WOPartNoId] [bigint] NULL,
	--	[TaskId] [bigint] NULL
	--)
	
	--CREATE TABLE #tmprWorkOrderExclusionsForCreateWO
	--(
	--	[WorkOrderExclusionsId] [bigint] IDENTITY(1,1) NOT NULL,
	--	[WorkOrderId] [bigint] NOT NULL,
	--	[WorkFlowWorkOrderId] [bigint] NOT NULL,
	--	[ItemMasterId] [bigint] NOT NULL,
	--	[EstimtPercentOccurranceId] [int] NULL,
	--	[Memo] [nvarchar](max) NULL,
	--	[Quantity] [int] NOT NULL,
	--	[UnitCost] [decimal](20, 3) NOT NULL,
	--	[ExtendedCost] [decimal](20, 3) NOT NULL,
	--	[MasterCompanyId] [int] NOT NULL,
	--	[CreatedBy] [varchar](256) NOT NULL,
	--	[UpdatedBy] [varchar](256) NOT NULL,
	--	[CreatedDate] [datetime2](7) NOT NULL,
	--	[UpdatedDate] [datetime2](7) NOT NULL,
	--	[IsActive] [bit] NOT NULL,
	--	[IsDeleted] [bit] NOT NULL,
	--	[TaskId] [bigint] NOT NULL,
	--	[IsFromWorkFlow] [bit] NULL,
	--	[ConditionCodeId] [bigint] NOT NULL,
	--	[ItemClassificationId] [bigint] NULL
	--)

	--CREATE TABLE #tmprWorkOrderExpertiseForCreateWO
	--(
	--	[WorkOrderExpertiseId] [bigint] IDENTITY(1,1) NOT NULL,
	--	[WorkOrderId] [bigint] NOT NULL,
	--	[WorkFlowWorkOrderId] [bigint] NOT NULL,
	--	[ExpertiseTypeId] [smallint] NULL,
	--	[EstimatedHours] [decimal](18, 2) NULL,
	--	[StandardRate] [decimal](18, 2) NULL,
	--	[TaskId] [bigint] NOT NULL,
	--	[MasterCompanyId] [int] NOT NULL,
	--	[CreatedBy] [varchar](256) NOT NULL,
	--	[UpdatedBy] [varchar](256) NOT NULL,
	--	[CreatedDate] [datetime2](7) NOT NULL,
	--	[UpdatedDate] [datetime2](7) NOT NULL,
	--	[IsActive] [bit] NOT NULL,
	--	[IsDeleted] [bit] NOT NULL,
	--	[LaborDirectRate] [decimal](20, 2) NULL,
	--	[DirectLaborRate] [decimal](20, 2) NULL,
	--	[OverHeadBurden] [decimal](20, 2) NULL,
	--	[OverHeadCost] [decimal](20, 2) NULL,
	--	[LaborOverHeadCost] [decimal](20, 2) NULL,
	--	[IsFromWorkFlow] [bit] NULL
	--)

	--CREATE TABLE #tmprWorkOrderMaterialsForCreateWO
	--(
	--	[WorkOrderMaterialsId] [bigint] IDENTITY(1,1) NOT NULL,
	--	[WorkOrderId] [bigint] NOT NULL,
	--	[WorkFlowWorkOrderId] [bigint] NOT NULL,
	--	[ItemMasterId] [bigint] NOT NULL,
	--	[MasterCompanyId] [int] NOT NULL,
	--	[CreatedBy] [varchar](256) NOT NULL,
	--	[UpdatedBy] [varchar](256) NOT NULL,
	--	[CreatedDate] [datetime2](7) NOT NULL,
	--	[UpdatedDate] [datetime2](7) NOT NULL,
	--	[IsActive] [bit] NOT NULL,
	--	[IsDeleted] [bit] NOT NULL,
	--	[TaskId] [bigint] NOT NULL,
	--	[ConditionCodeId] [bigint] NOT NULL,
	--	[ItemClassificationId] [bigint] NOT NULL,
	--	[Quantity] [int] NOT NULL,
	--	[UnitOfMeasureId] [bigint] NOT NULL,
	--	[UnitCost] [decimal](20, 2) NOT NULL,
	--	[ExtendedCost] [decimal](20, 2) NOT NULL,
	--	[Memo] [nvarchar](max) NULL,
	--	[IsDeferred] [bit] NULL,
	--	[QuantityReserved] [int] NULL,
	--	[QuantityIssued] [int] NULL,
	--	[IssuedDate] [datetime2](7) NULL,
	--	[ReservedDate] [datetime2](7) NULL,
	--	[IsAltPart] [bit] NULL,
	--	[AltPartMasterPartId] [bigint] NULL,
	--	[IsFromWorkFlow] [bit] NULL,
	--	[PartStatusId] [int] NULL,
	--	[UnReservedQty] [int] NULL,
	--	[UnIssuedQty] [int] NULL,
	--	[IssuedById] [bigint] NULL,
	--	[ReservedById] [bigint] NULL,
	--	[IsEquPart] [bit] NULL,
	--	[ParentWorkOrderMaterialsId] [bigint] NULL,
	--	[ItemMappingId] [bigint] NULL,
	--	[TotalReserved] [int] NULL,
	--	[TotalIssued] [int] NULL,
	--	[TotalUnReserved] [int] NULL,
	--	[TotalUnIssued] [int] NULL,
	--	[ProvisionId] [int] NOT NULL,
	--	[MaterialMandatoriesId] [int] NULL,
	--	[WOPartNoId] [bigint] NOT NULL,
	--	[TotalStocklineQtyReq] [int] NOT NULL,
	--	[QtyOnOrder] [int] NULL,
	--	[QtyOnBkOrder] [int] NULL,
	--	[POId] [bigint] NULL,
	--	[PONum] [varchar](100) NULL,
	--	[PONextDlvrDate] [datetime] NULL,
	--	[QtyToTurnIn] [int] NULL,
	--	[Figure] [nvarchar](50) NULL,
	--	[Item] [nvarchar](50) NULL,
	--	[EquPartMasterPartId] [bigint] NULL,
	--	[isfromsubWorkOrder] [bit] NULL,
	--	[ExpectedSerialNumber] [varchar](30) NULL
	--)
		
	--INSERT INTO #tmprCreateWorkFlowWorkOrderFromWorkFlow([ID],[WorkOrderId],[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
	--	   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
	--	   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
	--	   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
	--	   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
	--	   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
	--	   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId])
	--SELECT [ID],@WorkOrderId,[WorkOrderScopeId],[EstimatedShipDate],[CustomerRequestDate],[PromisedDate],[EstimatedCompletionDate],[NTE],[Quantity],
	--	   [StockLineId],[CMMIds],[WorkflowId],[WorkOrderStageId],[WorkOrderStatusId],[WorkOrderPriorityId],[IsPMA],[IsDER],[TechStationId],[TATDaysStandard],[MasterCompanyId],[CreatedBy],
	--	   [UpdatedBy],@CreatedDate,@CreatedDate,[IsActive],[IsDeleted],[ItemMasterId],[TechnicianId],[ConditionId],[TATDaysCurrent],[RevisedPartId],[ManagementStructureId],[IsMPNContract],
	--	   [ContractNo],[WorkScope],[isLocked],[ReceivedDate],[IsClosed],[ACTailNum],[ClosedDate],[PDFPath],[IsFinishGood],[RevisedConditionId],[CustomerReference],[Level1],[Level2],[Level3],
	--	   [Level4],[AssignDate],[ReceivingCustomerWorkId],[ExpertiseId],[RevisedItemmasterid],[RevisedPartNumber],[RevisedPartDescription],[IsTraveler],[AllowInvoiceBeforeShipping],
	--	   [WOFPrintDate],[CurrentSerialNumber],[StocklineCost],[TendorStocklineCost],[RepairOrderId],[RONumber],[RevisedSerialNumber],[IsROCreated],[PartNumber],[PartDescription],
	--	   [WorkOrderStatus],[Priority],[WorkOrderStage],[ManufacturerName],[TechName],[EmployeeStation],[PublicationNo],[SerialNumber],[MasterPartId] FROM @tbl_WorkOrderPartNumberType

	INSERT INTO #tmprCreateWorkFlowWorkOrderFromWorkFlow([ID],[WorkflowId])
	SELECT [ID],[WorkflowId] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tmprCreateWorkFlowWorkOrderFromWorkFlow  

	WHILE @MinId <= @TotalRecord
	BEGIN
	    DECLARE @WorkflowId BIGINT=0,@ID BIGINT=NULL,@WorkFlowWorkOrderId BIGINT=NULL

		SELECT @ID=[ID],@WorkflowId=[WorkflowId] FROM #tmprCreateWorkFlowWorkOrderFromWorkFlow WHERE [PKID] = @MinId

		SELECT @WorkFlowWorkOrderId=ISNULL([WorkFlowWorkOrderId],0) FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId]=@ID;
				
		IF(@WorkflowId > 0)
		BEGIN
			DECLARE @BERThresholdAmount  [NUMERIC](18, 2)=NULL,@ChangedPartNumberId [BIGINT]=NULL
			DECLARE @CostOfNew [NUMERIC](18, 2)=NULL,@CostOfReplacement [NUMERIC](18, 2)=NULL,@CurrencyId [BIGINT]=NULL,@CustomerId [BIGINT]=NULL,@FixedAmount [NUMERIC](18, 2)=NULL
			DECLARE @IsCalculatedBERThreshold [BIT]=NULL,@IsFixedAmount [BIT]=NULL,@IsPercentageOfNew [BIT]=NULL,@IsPercentageOfReplacement [BIT]=NULL,@ItemMasterId [BIGINT]=NULL
			DECLARE @Memo [NVARCHAR](MAX)=NULL,@OtherCost [NUMERIC](18, 2)=NULL,@PercentageOfNew [INT]=NULL,@PercentageOfReplacement [INT]=NULL,@Version [VARCHAR](10)=NULL
			DECLARE @WorkflowDescription [varchar](500)=NULL,@WorkflowCreateDate [datetime2](7)=NULL,@WorkflowExpirationDate [datetime2](7)=NULL
											
			--DECLARE @WorkFlowWorkOrderWorkOrderId [BIGINT]=NULL,@WorkFlowWorkOrderCreatedDate [DATETIME2](7)=NULL,@WorkFlowWorkOrderUpdatedDate [DATETIME2](7)=NULL
			--DECLARE @WorkFlowWorkOrderCreatedBy [VARCHAR](256)=NULL,@WorkFlowWorkOrderUpdatedBy [VARCHAR](256)=NULL
			--DECLARE @WorkFlowWorkOrderIsActive [BIT]=NULL,@WorkFlowWorkOrderIsDeleted [BIT]=NULL,@WorkFlowWorkOrderMasterCompanyId [INT]=NULL
			--DECLARE @WorkFlowWorkOrderBERThresholdAmount [NUMERIC](18, 2)=NULL,@WorkFlowWorkOrderChangedPartNumberId [BIGINT]=NULL
			--DECLARE @WorkFlowWorkOrderCostOfNew [NUMERIC](18, 2)=NULL,@WorkFlowWorkOrderCostOfReplacement [NUMERIC](18, 2)=NULL
			--DECLARE @WorkFlowWorkOrderCurrencyId [BIGINT]=NULL,@WorkFlowWorkOrderCustomerId [BIGINT]=NULL,@WorkFlowWorkOrderFixedAmount [NUMERIC](18, 2)=NULL
			--DECLARE @WorkFlowWorkOrderIsCalculatedBERThreshold [BIT]=NULL,@WorkFlowWorkOrderIsFixedAmount [BIT]=NULL,@WorkFlowWorkOrderIsPercentageOfNew [BIT]=NULL
			--DECLARE @WorkFlowWorkOrderIsPercentageOfReplacement [BIT]=NULL,@WorkFlowWorkOrderItemMasterId [BIGINT]=NULL,@WorkFlowWorkOrderMemo [NVARCHAR](MAX)=NULL
			--DECLARE @WorkFlowWorkOrderOtherCost [NUMERIC](18, 2)=NULL,@WorkFlowWorkOrderPercentageOfNew [INT]=NULL,@WorkFlowWorkOrderPercentageOfReplacement [INT]=NULL
			--DECLARE @WorkFlowWorkOrderVersion [VARCHAR](10)=NULL,@WorkFlowWorkOrderWorkflowDescription [varchar](500)=NULL,@WorkFlowWorkOrderWorkflowCreateDate [datetime2](7)=NULL
			--DECLARE @WorkFlowWorkOrderWorkflowExpirationDate [datetime2](7)=NULL,@WorkFlowWorkOrderWorkflowId [BIGINT]=NULL

			--DECLARE @ProvisionId INT=NULL
			
			SELECT @BERThresholdAmount=[BERThresholdAmount],
			       @ChangedPartNumberId=[ChangedPartNumberId],
				   @CostOfNew=[CostOfNew],
				   @CostOfReplacement=[CostOfReplacement],
				   @CurrencyId=[CurrencyId],
				   @CustomerId=[CustomerId],
				   @FixedAmount=[FixedAmount],
				   @IsCalculatedBERThreshold=[IsCalculatedBERThreshold],
				   @IsFixedAmount=[IsFixedAmount],
				   @IsPercentageOfNew=[IsPercentageOfNew],
				   @IsPercentageOfReplacement=[IsPercentageOfReplacement],
				   @ItemMasterId=[ItemMasterId],
				   @Memo=[Memo],
				   @OtherCost=[OtherCost], 
				   @PercentageOfNew=[PercentageOfNew],
				   @PercentageOfReplacement=[PercentageOfReplacement],
				   @Version=[Version],
				   @WorkflowDescription=[WorkflowDescription], 
				   @WorkflowCreateDate=[WorkflowCreateDate],
				   @WorkflowExpirationDate=[WorkflowExpirationDate] 
			  FROM [dbo].[Workflow] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId

			--IF EXISTS(SELECT [WorkflowPublicationsId] FROM [dbo].[WorkflowPublications] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN
			--    INSERT INTO #tmprWorkflowPublicationDashNumberForCreateWO([WorkflowPublicationDashNumberId],[WorkflowId],[AircraftDashNumberId],[TaskId],[WorkflowPublicationsId])
			--	SELECT wpdn.[WorkflowPublicationDashNumberId],wpdn.[WorkflowId],wpdn.[AircraftDashNumberId],wpdn.[TaskId],wpdn.[WorkflowPublicationsId]
			--	FROM [dbo].[WorkflowPublicationDashNumber] wpdn WITH(NOLOCK)
			--	INNER JOIN [dbo].[WorkflowPublications] wp WITH(NOLOCK) ON wpdn.[WorkflowPublicationsId] = wp.[WorkflowPublicationsId]
			--	WHERE wp.[WorkflowId] = @workFlowId;
			--END

			--SET @WorkFlowWorkOrderWorkOrderId = @WorkOrderId;
			--SET @WorkFlowWorkOrderCreatedDate = @CreatedDate;
			--SET @WorkFlowWorkOrderUpdatedDate = @CreatedDate;
			--SET @WorkFlowWorkOrderCreatedBy = @CreatedBy;
			--SET @WorkFlowWorkOrderUpdatedBy = @CreatedBy;
			--SET @WorkFlowWorkOrderIsActive = 1;
			--SET @WorkFlowWorkOrderIsDeleted = 0;
			--SET @WorkFlowWorkOrderMasterCompanyId = @MasterCompanyId;

			--SET @WorkFlowWorkOrderBERThresholdAmount = @BERThresholdAmount;
            --SET @WorkFlowWorkOrderChangedPartNumberId = @ChangedPartNumberId;
            --SET @WorkFlowWorkOrderCostOfNew = @CostOfNew;
            --SET @WorkFlowWorkOrderCostOfReplacement = @CostOfReplacement;
            --SET @WorkFlowWorkOrderCurrencyId = @CurrencyId;
            --SET @WorkFlowWorkOrderCustomerId = @CustomerId;
            --SET @WorkFlowWorkOrderFixedAmount = @FixedAmount;
            --SET @WorkFlowWorkOrderIsCalculatedBERThreshold = @IsCalculatedBERThreshold;
            --SET @WorkFlowWorkOrderIsFixedAmount = @IsFixedAmount;
            --SET @WorkFlowWorkOrderIsPercentageOfNew = @IsPercentageOfNew;
            --SET @WorkFlowWorkOrderIsPercentageOfReplacement = @IsPercentageOfReplacement;
            --SET @WorkFlowWorkOrderItemMasterId = @ItemMasterId;
            --SET @WorkFlowWorkOrderMemo = @Memo;
            --SET @WorkFlowWorkOrderOtherCost = @OtherCost;
            --SET @WorkFlowWorkOrderPercentageOfNew = @PercentageOfNew;
            --SET @WorkFlowWorkOrderPercentageOfReplacement = @PercentageOfReplacement;
            --SET @WorkFlowWorkOrderVersion = @Version;
            --SET @WorkFlowWorkOrderWorkflowDescription = @WorkflowDescription;
            --SET @WorkFlowWorkOrderWorkflowCreateDate = @WorkflowCreateDate;
            --SET @WorkFlowWorkOrderWorkflowExpirationDate = @WorkflowExpirationDate;
            --SET @WorkFlowWorkOrderWorkflowId = @WorkflowId
			
			--Charges
			--IF EXISTS(SELECT [WorkflowChargesListId] FROM [dbo].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN					   
			--	INSERT INTO #tmprWorkOrderChargesForCreateWO([WorkOrderId],[WorkFlowWorkOrderId],[ChargesTypeId],[VendorId],[Quantity],[MasterCompanyId],[CreatedBy],[UpdatedBy],
			--	            [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[Description],[UnitCost],[ExtendedCost],[IsFromWorkFlow],[ReferenceNo],[WOPartNoId],[UOMId])
			--		 SELECT @WorkOrderId,@WorkFlowWorkOrderId,[WorkflowChargeTypeId],[VendorId],ISNULL([Quantity],0),@MasterCompanyId,@CreatedBy,@CreatedBy,
			--	            @CreatedDate,@CreatedDate,1,0,[TaskId],[Description],ISNULL([UnitCost],0),ISNULL(ExtendedCost,0),1,'',@ID,NULL					 
			--	       FROM [dbo].[WorkflowChargesList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;	
			--END
			-- Equipments
			--IF EXISTS(SELECT [WorkflowEquipmentListId] FROM [dbo].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN
			--	INSERT INTO #tmprWorkOrderAssetsForCreateWO([WorkOrderId],[WorkFlowWorkOrderId],[AssetRecordId],[Quantity],[MasterCompanyId],[CreatedBy],[UpdatedBy],
			--	            [CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsFromWorkFlow],[WOPartNoId],[TaskId])
			--		 SELECT @WorkOrderId,@WorkFlowWorkOrderId,[AssetId],ISNULL([Quantity],0),@MasterCompanyId,@CreatedBy,@CreatedBy,
			--		        @CreatedDate,@CreatedDate,1,0,1,@ID,[TaskId]     
			--		   FROM [dbo].[WorkflowEquipmentList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;	
			--END
			-- Exclusions
			--IF EXISTS(SELECT [WorkflowExclusionId] FROM [dbo].[WorkFlowExclusion] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN				
			--	INSERT INTO #tmprWorkOrderExclusionsForCreateWO([WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[EstimtPercentOccurranceId],[Memo],[Quantity],[UnitCost],[ExtendedCost],
			--			    [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[TaskId],[IsFromWorkFlow],[ConditionCodeId],[ItemClassificationId])
			--	     SELECT @WorkOrderId,@WorkFlowWorkOrderId,ISNULL([ItemMasterId],0),NULL,[Memo],ISNULL([Quantity],0),ISNULL([UnitCost],0),ISNULL(ExtendedCost,0),
			--		   	    @MasterCompanyId,@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,1,0,[TaskId],1,[ConditionId],[ItemClassificationId]
			--		   FROM [dbo].[WorkflowExclusion] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;	
			--END
			-- Expertise
			--IF EXISTS(SELECT [WorkflowExpertiseListId] FROM [dbo].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN	
			--	INSERT INTO #tmprWorkOrderExpertiseForCreateWO([WorkOrderId],[WorkFlowWorkOrderId],[ExpertiseTypeId],[EstimatedHours],[StandardRate],[TaskId],[MasterCompanyId],[CreatedBy],
   --                         [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LaborDirectRate],[DirectLaborRate],[OverHeadBurden],[OverHeadCost],[LaborOverHeadCost],[IsFromWorkFlow])
			--         SELECT @WorkOrderId,@WorkFlowWorkOrderId,[ExpertiseTypeId],[EstimatedHours],[StandardRate],[TaskId],@MasterCompanyId,@CreatedBy,
			--		        @CreatedBy,@CreatedDate,@CreatedDate,1,0,[LaborDirectRate],[DirectLaborRate],[OverheadBurden],[OverheadCost],[LaborOverheadCost],1
			--		  FROM [dbo].[WorkflowExpertiseList] WITH(NOLOCK) WHERE [WorkflowId] = @WorkflowId;	
			--END
			-- MaterialList
			--IF EXISTS(SELECT [WorkflowMaterialListId] FROM [dbo].[WorkflowMaterial] WITH(NOLOCK) WHERE [WorkflowId]=@WorkflowId)
			--BEGIN				
				--SELECT TOP 1 @ProvisionId = ProvisionId FROM Provision WHERE [StatusCode] = @ProvisionEnum AND IsActive = 1 AND IsDeleted = 0;
				--SELECT * FROM MaterialMandatories WHERE IsDeleted = 0;

				--INSERT INTO #tmprWorkOrderMaterialsForCreateWO([WorkOrderId],[WorkFlowWorkOrderId],[ItemMasterId],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
    --                        [IsActive],[IsDeleted],[TaskId],[ConditionCodeId],[ItemClassificationId],[Quantity],[UnitOfMeasureId],[UnitCost],[ExtendedCost],[Memo],[IsDeferred],
    --                        [QuantityReserved],[QuantityIssued],[IssuedDate],[ReservedDate],[IsAltPart],[AltPartMasterPartId],[IsFromWorkFlow],[PartStatusId],[UnReservedQty],
    --                        [UnIssuedQty],[IssuedById],[ReservedById],[IsEquPart],[ParentWorkOrderMaterialsId],[ItemMappingId],[TotalReserved],[TotalIssued],[TotalUnReserved],
				--			[TotalUnIssued],[ProvisionId],[MaterialMandatoriesId],[WOPartNoId],[TotalStocklineQtyReq],[QtyOnOrder],[QtyOnBkOrder],[POId],[PONum],[PONextDlvrDate],
    --                        [QtyToTurnIn],[Figure],[Item],[EquPartMasterPartId],[isfromsubWorkOrder],[ExpectedSerialNumber])

			--	PRINT 1
			--END

				IF(@WorkFlowWorkOrderId > 0)
				BEGIN				
					UPDATE [dbo].[WorkOrderWorkFlow]
					   SET [WorkflowDescription] = @WorkflowDescription
						  ,[Version] = @Version					  
						  ,[ItemMasterId] = @ItemMasterId
						  ,[CustomerId] = @CustomerId
						  ,[CurrencyId] = @CurrencyId
						  ,[WorkflowExpirationDate] = @WorkflowExpirationDate
						  ,[IsCalculatedBERThreshold] = @IsCalculatedBERThreshold
						  ,[IsFixedAmount] = @IsFixedAmount
						  ,[FixedAmount] = @FixedAmount
						  ,[IsPercentageOfNew] = @IsPercentageOfNew
						  ,[CostOfNew] = @CostOfNew
						  ,[PercentageOfNew] = @PercentageOfNew
						  ,[IsPercentageOfReplacement] = @IsPercentageOfReplacement
						  ,[CostOfReplacement] = @CostOfReplacement
						  ,[PercentageOfReplacement] = @PercentageOfReplacement
						  ,[Memo] = @Memo
						  ,[BERThresholdAmount] = @BERThresholdAmount					  
						  ,[OtherCost] = @OtherCost					  	 
						  ,[UpdatedBy] = @UpdatedBy
						  ,[UpdatedDate] = @UpdatedDate					  
						  ,[WorkflowCreateDate] = @WorkflowCreateDate
						  ,[WorkflowId] = @WorkflowId					  					  
					 WHERE [WorkFlowWorkOrderId]=@WorkFlowWorkOrderId;
				END
			ELSE
			BEGIN
				INSERT INTO [dbo].[WorkOrderWorkFlow]([WorkOrderId],[WorkflowDescription],[Version],[WorkScopeId],[ItemMasterId],[CustomerId],[CurrencyId],[WorkflowExpirationDate],
								[IsCalculatedBERThreshold],[IsFixedAmount],[FixedAmount],[IsPercentageOfNew],[CostOfNew],[PercentageOfNew],[IsPercentageOfReplacement],[CostOfReplacement],
								[PercentageOfReplacement],[Memo],[BERThresholdAmount],[WorkOrderNumber],[OtherCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
								[IsActive],[IsDeleted],[WorkflowCreateDate],[WorkflowId],[WorkFlowWorkOrderNo],[ChangedPartNumberId],[MaterilaCost],[ExpertiseCost],[ChargesCost],[Total],
								[PerOfBerThreshold],[WorkOrderPartNoId])
						 SELECT @WorkOrderId,@WorkflowDescription,@Version,NULL,@ItemMasterId,@CustomerId,@CurrencyId,@WorkflowExpirationDate,
								@IsCalculatedBERThreshold,@IsFixedAmount,@FixedAmount,@IsPercentageOfNew,@CostOfNew,@PercentageOfNew,@IsPercentageOfReplacement,@CostOfReplacement,
								@PercentageOfReplacement,@Memo,@BERThresholdAmount,NULL,@OtherCost,@MasterCompanyId,@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,
								1,0,@WorkflowCreateDate,@WorkflowId,'',NULL,NULL,NULL,NULL,NULL,
								NULL,@ID

					SET @WorkFlowWorkOrderId = SCOPE_IDENTITY();
			END

			UPDATE [dbo].[WorkOrderWorkFlow] SET  [WorkFlowWorkOrderNo] = 'WOWF' + CAST([WorkFlowWorkOrderId] AS NVARCHAR) WHERE [WorkFlowWorkOrderId]=@WorkFlowWorkOrderId;
		END
		ELSE
		BEGIN
			IF(@WorkFlowWorkOrderId > 0)
			BEGIN				
				UPDATE [dbo].[WorkOrderWorkFlow]
				   SET [WorkflowDescription] = @WorkflowDescription
					  ,[Version] = @Version					  
					  ,[ItemMasterId] = @ItemMasterId
					  ,[CustomerId] = @CustomerId
					  ,[CurrencyId] = @CurrencyId
					  ,[WorkflowExpirationDate] = @WorkflowExpirationDate
					  ,[IsCalculatedBERThreshold] = @IsCalculatedBERThreshold
					  ,[IsFixedAmount] = @IsFixedAmount
					  ,[FixedAmount] = @FixedAmount
					  ,[IsPercentageOfNew] = @IsPercentageOfNew
					  ,[CostOfNew] = @CostOfNew
					  ,[PercentageOfNew] = @PercentageOfNew
					  ,[IsPercentageOfReplacement] = @IsPercentageOfReplacement
					  ,[CostOfReplacement] = @CostOfReplacement
					  ,[PercentageOfReplacement] = @PercentageOfReplacement
					  ,[Memo] = @Memo
					  ,[BERThresholdAmount] = @BERThresholdAmount					  
					  ,[OtherCost] = @OtherCost					  	 
					  ,[UpdatedBy] = @UpdatedBy
					  ,[UpdatedDate] = @UpdatedDate					  
					  ,[WorkflowCreateDate] = @WorkflowCreateDate
					  ,[WorkflowId] = ISNULL(@WorkflowId,0)					  					  
				 WHERE [WorkFlowWorkOrderId]=@WorkFlowWorkOrderId;
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[WorkOrderWorkFlow]([WorkOrderId],[WorkflowDescription],[Version],[WorkScopeId],[ItemMasterId],[CustomerId],[CurrencyId],[WorkflowExpirationDate],
							[IsCalculatedBERThreshold],[IsFixedAmount],[FixedAmount],[IsPercentageOfNew],[CostOfNew],[PercentageOfNew],[IsPercentageOfReplacement],[CostOfReplacement],
							[PercentageOfReplacement],[Memo],[BERThresholdAmount],[WorkOrderNumber],[OtherCost],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],
							[IsActive],[IsDeleted],[WorkflowCreateDate],[WorkflowId],[WorkFlowWorkOrderNo],[ChangedPartNumberId],[MaterilaCost],[ExpertiseCost],[ChargesCost],[Total],
							[PerOfBerThreshold],[WorkOrderPartNoId])
					 SELECT @WorkOrderId,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
							NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
							NULL,NULL,NULL,NULL,NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,@CreatedDate,@CreatedDate,
							1,0,NULL,0,'',NULL,NULL,NULL,NULL,NULL,
							NULL,@ID

				 SET @WorkFlowWorkOrderId = SCOPE_IDENTITY();
			END

			UPDATE [dbo].[WorkOrderWorkFlow] SET  [WorkFlowWorkOrderNo] = 'WOWF' + CAST([WorkFlowWorkOrderId] AS NVARCHAR) WHERE [WorkFlowWorkOrderId]=@WorkFlowWorkOrderId;
		END

		SET @MinId = @MinId + 1
	END
	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateWorkFlowWorkOrderFromWorkFlow' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
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