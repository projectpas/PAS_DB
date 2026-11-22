CREATE TABLE [dbo].[SubComponent] (
    [SubComponentId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]          BIGINT         NOT NULL,
    [MappingItemMasterId]   BIGINT         NOT NULL,
    [Quantity]              BIGINT         NOT NULL,
    [ConditionId]           BIGINT         NULL,
    [WorkscopeId]           BIGINT         NOT NULL,
    [IsAutoCreateStockline] BIT            NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_SubComponent_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_SubComponent_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_SubComponent_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_SubComponent_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubComponent] PRIMARY KEY CLUSTERED ([SubComponentId] ASC),
    CONSTRAINT [FK_SubComponent_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubComponent_MappingItemMaster] FOREIGN KEY ([MappingItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubComponent_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_SubComponent_Item_Mapping_Condition_Workscope]
    ON [dbo].[SubComponent]([ItemMasterId] ASC, [MappingItemMasterId] ASC, [ConditionId] ASC, [WorkscopeId] ASC);


GO

-- CREATE OR ALTER : safe to run again
CREATE   TRIGGER [dbo].[Trg_SubComponentAudit]
   ON  [dbo].[SubComponent]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED) - the new values
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[SubComponentAudit] ([SubComponentId], [ItemMasterId], [MappingItemMasterId], [Quantity], [ConditionId], [WorkscopeId], [IsAutoCreateStockline], [Memo], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
		SELECT I.[SubComponentId], I.[ItemMasterId], I.[MappingItemMasterId], I.[Quantity], I.[ConditionId], I.[WorkscopeId], I.[IsAutoCreateStockline], I.[Memo], I.[MasterCompanyId], I.[CreatedBy], I.[CreatedDate], I.[UpdatedBy], I.[UpdatedDate], I.[IsActive], I.[IsDeleted] FROM INSERTED I
	END

	-- Handles DELETE (rows exist only in DELETED) - the old values
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[SubComponentAudit] ([SubComponentId], [ItemMasterId], [MappingItemMasterId], [Quantity], [ConditionId], [WorkscopeId], [IsAutoCreateStockline], [Memo], [MasterCompanyId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsActive], [IsDeleted])
		SELECT D.[SubComponentId], D.[ItemMasterId], D.[MappingItemMasterId], D.[Quantity], D.[ConditionId], D.[WorkscopeId], D.[IsAutoCreateStockline], D.[Memo], D.[MasterCompanyId], D.[CreatedBy], D.[CreatedDate], D.[UpdatedBy], D.[UpdatedDate], D.[IsActive], D.[IsDeleted] FROM DELETED D
	END
END