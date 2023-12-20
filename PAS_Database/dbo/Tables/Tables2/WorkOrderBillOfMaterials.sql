CREATE TABLE [dbo].[WorkOrderBillOfMaterials] (
    [WorkOrderBillOfMaterialsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                INT           NOT NULL,
    [PartNumber]                 INT           NOT NULL,
    [Quantity]                   SMALLINT      NOT NULL,
    [Condition]                  VARCHAR (20)  NULL,
    [ProvisionId]                TINYINT       NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_WorkOrderBillOfMaterials_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_WorkOrderBillOfMaterials_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_WorkOrderBillOfMaterials_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderBillOfMaterials] PRIMARY KEY CLUSTERED ([WorkOrderBillOfMaterialsId] ASC),
    CONSTRAINT [FK_WorkOrderBillOfMaterials_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderBillOfMaterials_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[WorkOrderProvision] ([WorkOrderProvisionId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderBillOfMaterialsAudit]

   ON  [dbo].[WorkOrderBillOfMaterials]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderBillOfMaterialsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END