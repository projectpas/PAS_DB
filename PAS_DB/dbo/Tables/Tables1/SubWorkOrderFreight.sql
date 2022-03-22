CREATE TABLE [dbo].[SubWorkOrderFreight] (
    [SubWorkOrderFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]           BIGINT          NOT NULL,
    [SubWorkOrderId]        BIGINT          NOT NULL,
    [SubWOPartNoId]         BIGINT          NOT NULL,
    [ShipViaId]             BIGINT          NOT NULL,
    [Weight]                VARCHAR (50)    NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [Amount]                DECIMAL (20, 3) NOT NULL,
    [TaskId]                BIGINT          NOT NULL,
    [Length]                DECIMAL (10, 2) NULL,
    [Width]                 DECIMAL (10, 2) NULL,
    [Height]                DECIMAL (10, 2) NULL,
    [UOMId]                 BIGINT          NULL,
    [DimensionUOMId]        BIGINT          NULL,
    [CurrencyId]            INT             NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [SubWorkOrderFreight_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [SubWorkOrderFreight_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderFreight] PRIMARY KEY CLUSTERED ([SubWorkOrderFreightId] ASC),
    CONSTRAINT [FK_SubWorkOrderFreight_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SubWorkOrderFreight_DimensionUOM] FOREIGN KEY ([DimensionUOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_SubWorkOrderFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderFreight_ShipVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_SubWorkOrderFreight_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderFreight_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderFreight_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_SubWorkOrderFreight_UOM] FOREIGN KEY ([UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_SubWorkOrderFreight_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderFreightAudit]

   ON  [dbo].[SubWorkOrderFreight]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderFreightAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END