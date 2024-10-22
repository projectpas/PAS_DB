CREATE TABLE [dbo].[WorkOrderPartNumber] (
    [ID]                         BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                BIGINT          NOT NULL,
    [WorkOrderScopeId]           BIGINT          NOT NULL,
    [EstimatedShipDate]          DATETIME2 (7)   NULL,
    [CustomerRequestDate]        DATETIME2 (7)   NOT NULL,
    [PromisedDate]               DATETIME2 (7)   NULL,
    [EstimatedCompletionDate]    DATETIME2 (7)   NULL,
    [NTE]                        VARCHAR (30)    NULL,
    [Quantity]                   INT             NOT NULL,
    [StockLineId]                BIGINT          NOT NULL,
    [CMMId]                      BIGINT          NULL,
    [WorkflowId]                 BIGINT          NULL,
    [WorkOrderStageId]           BIGINT          NOT NULL,
    [WorkOrderStatusId]          BIGINT          NOT NULL,
    [WorkOrderPriorityId]        BIGINT          NOT NULL,
    [IsPMA]                      BIT             NULL,
    [IsDER]                      BIT             NULL,
    [TechStationId]              BIGINT          NULL,
    [TATDaysStandard]            INT             NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderPartNumber_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_WorkOrderPartNumber_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [DF_WOP_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF_WOP_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ItemMasterId]               BIGINT          CONSTRAINT [DF__WorkOrder__ItemM__52B9FAC2] DEFAULT ((0)) NOT NULL,
    [TechnicianId]               BIGINT          CONSTRAINT [DF__WorkOrder__Techn__53AE1EFB] DEFAULT ((0)) NULL,
    [ConditionId]                BIGINT          NOT NULL,
    [TATDaysCurrent]             INT             NULL,
    [RevisedPartId]              BIGINT          NULL,
    [ManagementStructureId]      BIGINT          CONSTRAINT [DF__WorkOrder__Manag__54A24334] DEFAULT ((0)) NOT NULL,
    [IsMPNContract]              BIT             NULL,
    [ContractNo]                 VARCHAR (20)    NULL,
    [WorkScope]                  VARCHAR (200)   NULL,
    [isLocked]                   BIT             CONSTRAINT [DF__WorkOrder__isLoc__5596676D] DEFAULT ((0)) NOT NULL,
    [ReceivedDate]               DATETIME        NULL,
    [IsClosed]                   BIT             CONSTRAINT [DF__WorkOrder__IsClo__568A8BA6] DEFAULT ((0)) NULL,
    [ACTailNum]                  NVARCHAR (500)  NULL,
    [ClosedDate]                 DATETIME        NULL,
    [PDFPath]                    NVARCHAR (MAX)  NULL,
    [IsFinishGood]               BIT             CONSTRAINT [DF__WorkOrder__IsFin__577EAFDF] DEFAULT ((0)) NULL,
    [RevisedConditionId]         BIGINT          NULL,
    [CustomerReference]          VARCHAR (256)   NULL,
    [Level1]                     VARCHAR (200)   NULL,
    [Level2]                     VARCHAR (200)   NULL,
    [Level3]                     VARCHAR (200)   NULL,
    [Level4]                     VARCHAR (200)   NULL,
    [AssignDate]                 DATETIME2 (7)   NULL,
    [ReceivingCustomerWorkId]    BIGINT          NULL,
    [ExpertiseId]                SMALLINT        NULL,
    [RevisedItemmasterid]        BIGINT          NULL,
    [RevisedPartNumber]          VARCHAR (50)    NULL,
    [RevisedPartDescription]     VARCHAR (MAX)   NULL,
    [IsTraveler]                 BIT             NULL,
    [AllowInvoiceBeforeShipping] BIT             NULL,
    [WOFPrintDate]               DATETIME2 (7)   NULL,
    [CurrentSerialNumber]        VARCHAR (100)   NULL,
    [StocklineCost]              DECIMAL (18, 2) NULL,
    [TendorStocklineCost]        DECIMAL (18, 2) NULL,
    [RepairOrderId]              BIGINT          NULL,
    [RONumber]                   VARCHAR (50)    NULL,
    [RevisedSerialNumber]        VARCHAR (50)    NULL,
    [IsROCreated]                BIT             NULL,
    [PartNumber]                 VARCHAR (200)   NULL,
    [PartDescription]            NVARCHAR (MAX)  NULL,
    [WorkOrderStatus]            VARCHAR (MAX)   NULL,
    [Priority]                   VARCHAR (100)   NULL,
    [WorkOrderStage]             VARCHAR (150)   NULL,
    [ManufacturerName]           VARCHAR (250)   NULL,
    [TechName]                   VARCHAR (100)   NULL,
    [EmployeeStation]            VARCHAR (100)   NULL,
    CONSTRAINT [PK_WorkOrderPartNumber] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_WorkOrderPartNumber_CMMId] FOREIGN KEY ([CMMId]) REFERENCES [dbo].[Publication] ([PublicationRecordId]),
    CONSTRAINT [FK_WorkOrderPartNumber_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderPartNumber_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderPartNumber_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderPartNumber_RevisedConditionId] FOREIGN KEY ([RevisedConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderPartNumber_RevisedPart] FOREIGN KEY ([RevisedPartId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderPartNumber_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_WorkOrderPartNumber_Technician] FOREIGN KEY ([TechnicianId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderPartNumber_TechStation] FOREIGN KEY ([TechStationId]) REFERENCES [dbo].[EmployeeStation] ([EmployeeStationId]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkFlow] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkOrderPriority] FOREIGN KEY ([WorkOrderPriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkOrderStage] FOREIGN KEY ([WorkOrderStageId]) REFERENCES [dbo].[WorkOrderStage] ([WorkOrderStageId]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkOrderStatus] FOREIGN KEY ([WorkOrderStatusId]) REFERENCES [dbo].[WorkOrderStatus] ([Id]),
    CONSTRAINT [FK_WorkOrderPartNumber_WorkScope] FOREIGN KEY ([WorkOrderScopeId]) REFERENCES [dbo].[WorkScope] ([WorkScopeId])
);














GO
----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderPartNumAudit]

   ON  [dbo].[WorkOrderPartNumber]

   AFTER INSERT,UPDATE

AS 

BEGIN

	DECLARE @ItemMasterId BIGINT,@WorkScopeId BIGINT,@ManagementStructureId BIGINT,@ConditionId BIGINT,@StockLineId BIGINT,

	@PublicationId BIGINT,@WorkflowId BIGINT,@StageId BIGINT,@StatusId BIGINT,@PriorityId BIGINT,@TechId BIGINT,@TechStationId BIGINT

	
	DECLARE @PartNum VARCHAR(256),@PartDesc VARCHAR(256),@RevisedPartNum VARCHAR(256),@ItemGroup VARCHAR(256),@WorkScope VARCHAR(256),

	@CustRefNo VARCHAR(256),@MangLevel1  VARCHAR(256),@MangLevel2  VARCHAR(256),@MangLevel3  VARCHAR(256),@MangLevel4  VARCHAR(256),

	@Condition VARCHAR(256),@StockLineNum VARCHAR(256),@SerialNum VARCHAR(256),@PublicationNum VARCHAR(256),@WorkflowNum VARCHAR(256),

	@Stage VARCHAR(256),@Status VARCHAR(256),@Priority VARCHAR(256),@TechName VARCHAR(256),@TechStation VARCHAR(256)


	SELECT @ItemMasterId=ItemMasterId,@ManagementStructureId=ManagementStructureId,@ConditionId=ConditionId,

	@StockLineId=StockLineId,@PublicationId=CMMId,@WorkflowId=WorkflowId,@StageId=WorkOrderStageId,@StatusId=WorkOrderStatusId,

	@PriorityId=WorkOrderPriorityId,@TechId=TechnicianId,@TechStationId=TechStationId

	FROM INSERTED


	SELECT @PartNum=IM.partnumber,@PartDesc=IM.PartDescription,@RevisedPartNum=ISNULL(RP.partnumber,''),@ItemGroup=ISNULL(IG.Description,'')
	FROM dbo.ItemMaster IM WITH(NOLOCK)
		LEFT JOIN ItemMaster RP WITH(NOLOCK) ON IM.RevisedPartId=RP.ItemMasterId
		LEFT JOIN ItemGroup IG WITH(NOLOCK) ON IM.ItemGroupId=IG.ItemGroupId
	WHERE IM.ItemMasterId=@ItemMasterId

	SELECT @CustRefNo=Reference FROM dbo.ReceivingCustomerWork WITH(NOLOCK) WHERE StockLineId=@StockLineId

	 SELECT @MangLevel1= CASE WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL and level1.Name IS NOT NULL THEN level1.Name 

                         WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL THEN level2.Name 

                         WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL THEN level3.Name 

                         WHEN level4.Name IS NOT NULL THEN level4.Name ELSE '' END,

			@MangLevel2= CASE WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL and level1.Name IS NOT NULL THEN level2.Name 

                         WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL THEN level3.Name 

                         WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL THEN level4.Name ELSE '' END,

			@MangLevel3= CASE WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL and level1.Name IS NOT NULL THEN level3.Name

                         WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL THEN level4.Name ELSE '' END,

			@MangLevel4= CASE WHEN level4.Name IS NOT NULL and level3.Name IS NOT NULL and level2.Name IS NOT NULL and level1.Name IS NOT NULL THEN level4.Name ELSE '' END

		FROM WorkOrderPartNumber wop WITH(NOLOCK) 
			JOIN  ManagementStructure level4 WITH(NOLOCK)  ON wop.ManagementStructureId = level4.ManagementStructureId
			LEFT JOIN  ManagementStructure level3 WITH(NOLOCK)  ON level4.ParentId = level3.ManagementStructureId 
			LEFT JOIN  ManagementStructure level2 WITH(NOLOCK)  ON level3.ParentId = level2.ManagementStructureId 
			LEFT JOIN  ManagementStructure level1 WITH(NOLOCK)  ON level2.ParentId = level1.ManagementStructureId 
		WHERE wop.ManagementStructureId=@ManagementStructureId


	SELECT @Condition=Description FROM Condition WHERE ConditionId=@ConditionId

	SELECT @StockLineNum=StockLineNumber,@SerialNum=SerialNumber  FROM Stockline WHERE StockLineId=@StockLineId

	SELECT @PublicationNum=PublicationId FROM Publication WHERE PublicationRecordId=@PublicationId

	SELECT @WorkflowNum=WorkOrderNumber FROM Workflow WHERE WorkflowId=@WorkflowId

	SELECT @Stage=Stage FROM WorkOrderStage WHERE WorkOrderStageId=@StageId

	SELECT @Status=Status FROM WorkOrderStatus WHERE Id=@StatusId

	SELECT @Priority=Description FROM [Priority] WHERE PriorityId=@PriorityId

	SELECT @TechName=FirstName+' '+LastName FROM Employee WHERE EmployeeId=@TechId

	SELECT @TechStation=StationName FROM EmployeeStation WHERE EmployeeStationId=@TechStationId


	INSERT INTO [dbo].[WorkOrderPartNumberAudit] ([WOPartNoId]

      ,[WorkOrderId]

      ,[WorkOrderScopeId]

      ,[EstimatedShipDate]

      ,[CustomerRequestDate]

      ,[PromisedDate]

      ,[EstimatedCompletionDate]

      ,[NTE]

      ,[Quantity]

      ,[StockLineId]

      ,[CMMId]

      ,[WorkflowId]

      ,[WorkOrderStageId]

      ,[WorkOrderStatusId]

      ,[WorkOrderPriorityId]

      ,[IsPMA]

      ,[IsDER]

      ,[TechStationId]

      ,[TATDaysStandard]

      ,[MasterCompanyId]

      ,[CreatedBy]

      ,[UpdatedBy]

      ,[CreatedDate]

      ,[UpdatedDate]

      ,[IsActive]

      ,[IsDeleted]

      ,[ItemMasterId]

      ,[TechnicianId]

      ,[ConditionId]

      ,[TATDaysCurrent]

      ,[RevisedPartId]

      ,[ManagementStructureId]

      ,[IsMPNContract]

      ,[ContractNo]

      ,[WorkScope]

	  ,[isLocked]

	  ,[ReceivedDate]

	  ,[ACTailNum]

	  ,[IsFinishGood]

      ,[PartNo]

      ,[PartDescription]

      ,[RevisedPartNo]

      ,[ItemGroup]

      ,[CustRefNo]

      ,[MangLevel1]

      ,[MangLevel2]

      ,[MangLevel3]

      ,[MangLevel4]

      ,[Condition]

      ,[StockLineNum]

      ,[SerialNum]

      ,[PublicationNum]

      ,[WorkflowNum]

      ,[Stage]

      ,[Status]

      ,[Priority]

      ,[TechName]

      ,[TechStation])

    SELECT [ID],

		[WorkOrderId]

      ,[WorkOrderScopeId]

      ,[EstimatedShipDate]

      ,[CustomerRequestDate]

      ,[PromisedDate]

      ,[EstimatedCompletionDate]

      ,[NTE]

      ,[Quantity]

      ,[StockLineId]

      ,[CMMId]

      ,[WorkflowId]

      ,[WorkOrderStageId]

      ,[WorkOrderStatusId]

      ,[WorkOrderPriorityId]

      ,[IsPMA]

      ,[IsDER]

      ,[TechStationId]

      ,[TATDaysStandard]

      ,[MasterCompanyId]

      ,[CreatedBy]

      ,[UpdatedBy]

      ,GETUTCDATE()

      ,GETUTCDATE()

      ,[IsActive]

      ,[IsDeleted]

      ,[ItemMasterId]

      ,[TechnicianId]

      ,[ConditionId]

      ,[TATDaysCurrent]

      ,[RevisedPartId]

      ,[ManagementStructureId]

      ,[IsMPNContract]

      ,[ContractNo]

	  ,[WorkScope]

	  ,[isLocked]

	  ,[ReceivedDate]

	  ,[ACTailNum]

	  ,[IsFinishGood]

	,@PartNum,@PartDesc,@RevisedPartNum,@ItemGroup,@CustRefNo,@MangLevel1,@MangLevel2,@MangLevel3,@MangLevel4,

	@Condition,@StockLineNum,@SerialNum,@PublicationNum,@WorkflowNum,@Stage,@Status,@Priority,@TechName,@TechStation

	FROM INSERTED 

	SET NOCOUNT ON;



END