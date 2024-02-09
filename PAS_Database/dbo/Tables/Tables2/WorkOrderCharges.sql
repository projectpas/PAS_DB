CREATE TABLE [dbo].[WorkOrderCharges] (
    [WorkOrderChargesId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT          NOT NULL,
    [WorkFlowWorkOrderId] BIGINT          NOT NULL,
    [ChargesTypeId]       BIGINT          NOT NULL,
    [VendorId]            BIGINT          NULL,
    [Quantity]            INT             NOT NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [WorkOrderCharges_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [WorkOrderCharges_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TaskId]              BIGINT          NOT NULL,
    [Description]         VARCHAR (256)   NULL,
    [UnitCost]            DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]        DECIMAL (20, 2) NULL,
    [IsFromWorkFlow]      BIT             DEFAULT ((0)) NULL,
    [ReferenceNo]         VARCHAR (20)    NULL,
    [WOPartNoId]          BIGINT          DEFAULT ((0)) NOT NULL,
    [UOMId]               BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderCharges] PRIMARY KEY CLUSTERED ([WorkOrderChargesId] ASC),
    CONSTRAINT [FK_WorkOrderCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_WorkOrderCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderCharges_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderCharges_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_WorkOrderCharges_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderCharges_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);






GO

----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderChargesAudit]

   ON  [dbo].[WorkOrderCharges]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @TaskId BIGINT,@ChargeId BIGINT,@GLAccountId BIGINT,@VendorId BIGINT



	DECLARE @Task VARCHAR(256),@ChargeType VARCHAR(256),@GLAccount VARCHAR(256),@Vendor VARCHAR(256)

	



	SELECT @TaskId= TaskId,@ChargeId=ChargesTypeId,@VendorId=VendorId FROM INSERTED



	SELECT @Task=Description FROM Task WHERE TaskId=@TaskId

	SELECT @Vendor=VendorName FROM Vendor WHERE VendorId=@VendorId

	SELECT @ChargeType=ChargeType,@GLAccountId=GLAccountId FROM Charge WHERE ChargeId=@ChargeId

	SELECT @GLAccount=AccountName FROM GLAccount WHERE GLAccountId=@GLAccountId





 



	INSERT INTO [dbo].[WorkOrderChargesAudit]
           ([WorkOrderChargesId]
           ,[WorkOrderId]
           ,[WorkFlowWorkOrderId]
           ,[ChargesTypeId]
           ,[VendorId]
           ,[Quantity]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[TaskId]
           ,[Description]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[IsFromWorkFlow]
           ,[ReferenceNo]
           ,[WOPartNoId]
           ,[UOMId]
           ,[Task]
           ,[ChargeType]
           ,[GlAccount]
           ,[Vendor])

    SELECT [WorkOrderChargesId]
           ,[WorkOrderId]
           ,[WorkFlowWorkOrderId]
           ,[ChargesTypeId]
           ,[VendorId]
           ,[Quantity]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[TaskId]
           ,[Description]
           ,[UnitCost]
           ,[ExtendedCost]
           ,[IsFromWorkFlow]
           ,[ReferenceNo]
           ,[WOPartNoId]
           ,[UOMId] ,@Task,@ChargeType,@GLAccount,@Vendor

	FROM INSERTED 

	SET NOCOUNT ON;



END