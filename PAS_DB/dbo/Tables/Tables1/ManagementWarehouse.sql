CREATE TABLE [dbo].[ManagementWarehouse] (
    [ManagementWarehouseId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [WarehouseId]           BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementWarehouse_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementWarehouse_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [ManagementWarehouse_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [ManagementWarehouse_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementWarehouse] PRIMARY KEY CLUSTERED ([ManagementWarehouseId] ASC),
    CONSTRAINT [FK_ManagementWarehouse_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_ManagementWarehouse_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ManagementWarehouse_Warehouse] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouse] ([WarehouseId])
);


GO




CREATE TRIGGER [dbo].[Trg_ManagementWarehouseAudit]

   ON  [dbo].[ManagementWarehouse]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementWarehouseAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END