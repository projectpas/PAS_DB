CREATE TABLE [dbo].[WorkOrderFreight] (
    [WorkOrderFreightId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT          NOT NULL,
    [WorkFlowWorkOrderId] BIGINT          NOT NULL,
    [ShipViaId]           BIGINT          NOT NULL,
    [Weight]              VARCHAR (50)    NULL,
    [Memo]                NVARCHAR (MAX)  NULL,
    [Amount]              DECIMAL (20, 3) NOT NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [DF_WorkOrderFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_WorkOrderFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [DF_WorkOrderFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [DF_WorkOrderFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [TaskId]              BIGINT          NOT NULL,
    [Length]              DECIMAL (10, 2) NULL,
    [Width]               DECIMAL (10, 2) NULL,
    [Height]              DECIMAL (10, 2) NULL,
    [UOMId]               BIGINT          NULL,
    [DimensionUOMId]      BIGINT          NULL,
    [CurrencyId]          INT             NULL,
    [WOPartNoId]          BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderFreight] PRIMARY KEY CLUSTERED ([WorkOrderFreightId] ASC),
    CONSTRAINT [FK_WorkOrderFreight_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_WorkOrderFreight_DimensionUOM] FOREIGN KEY ([DimensionUOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderFreight_ShipVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_WorkOrderFreight_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderFreight_UOM] FOREIGN KEY ([UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderFreight_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderFreight_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderFreightAudit]

   ON  [dbo].[WorkOrderFreight]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @TaskId BIGINT,@ShipViaId BIGINT,@UOMId BIGINT,@DimentionUOMId BIGINT,@CurrencyId BIGINT



	DECLARE @Task VARCHAR(256),@ShipVia VARCHAR(256),@UOM VARCHAR(256),@DimentionUOM VARCHAR(256),@Currency VARCHAR(256)

	



	SELECT @TaskId= TaskId,@ShipViaId=ShipViaId,@UOMId=UOMId,@DimentionUOMId=DimensionUOMId,@CurrencyId=CurrencyId FROM INSERTED



	SELECT @Task=Description FROM Task WHERE TaskId=@TaskId

	SELECT @ShipVia=Name FROM ShippingVia WHERE ShippingViaId=@ShipViaId

	SELECT @UOM=ShortName FROM UnitOfMeasure WHERE UnitOfMeasureId=@UOMId

	SELECT @DimentionUOM=Description FROM UnitOfMeasure WHERE UnitOfMeasureId=@DimentionUOMId

	SELECT @Currency=Code FROM Currency WHERE CurrencyId=@CurrencyId

	   

	INSERT INTO [dbo].[WorkOrderFreightAudit] 

    SELECT * ,@Task,@ShipVia,@UOM,@DimentionUOM,@Currency

	FROM INSERTED 

	SET NOCOUNT ON;



END