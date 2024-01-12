CREATE TABLE [dbo].[SubWorkOrderCharges] (
    [SubWorkOrderChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]           BIGINT          NOT NULL,
    [SubWorkOrderId]        BIGINT          NOT NULL,
    [SubWOPartNoId]         BIGINT          NOT NULL,
    [ChargesTypeId]         BIGINT          NOT NULL,
    [VendorId]              BIGINT          NULL,
    [Quantity]              INT             NOT NULL,
    [TaskId]                BIGINT          NOT NULL,
    [Description]           VARCHAR (256)   NULL,
    [UnitCost]              DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]          DECIMAL (20, 2) NULL,
    [IsFromWorkFlow]        BIT             DEFAULT ((0)) NULL,
    [ReferenceNo]           VARCHAR (20)    NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [SubWorkOrderCharges_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [SubWorkOrderCharges_DC_Delete] DEFAULT ((0)) NOT NULL,
    [UOMId]                 BIGINT          NULL,
    CONSTRAINT [PK_SubWorkOrderCharges] PRIMARY KEY CLUSTERED ([SubWorkOrderChargesId] ASC),
    CONSTRAINT [FK_SubWorkOrderCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_SubWorkOrderCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderCharges_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderCharges_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderCharges_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_SubWorkOrderCharges_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_SubWorkOrderCharges_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);




GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderChargesAudit]

   ON  [dbo].[SubWorkOrderCharges]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderChargesAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END