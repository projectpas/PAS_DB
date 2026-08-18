CREATE TABLE [dbo].[Assemply] (
    [AssemplyId]             BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]           BIGINT        NOT NULL,
    [Quantity]               BIGINT        NOT NULL,
    [WorkscopeId]            BIGINT        NOT NULL,
    [ProvisionId]            BIGINT        NOT NULL,
    [PopulateWoMaterialList] BIT           NOT NULL,
    [Memo]                   VARCHAR (500) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (50)  NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_Assemply_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (50)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_Assemply_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF__Assemply__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF__Assemply__IsDeleted] DEFAULT ((0)) NOT NULL,
    [MappingItemMasterId]    BIGINT        NULL,
    CONSTRAINT [PK_Assemply] PRIMARY KEY CLUSTERED ([AssemplyId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_AssemplyAudit]

   ON  [dbo].[Assemply]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[AssemplyAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END
GO
CREATE NONCLUSTERED INDEX [IX_Assemply_ItemMasterId_PopulateWoMaterialList_Perf]
    ON [dbo].[Assemply]([ItemMasterId] ASC, [PopulateWoMaterialList] ASC)
    INCLUDE([AssemplyId]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
-- Added 2026-08-03: supports ProcItemMasterStockList's HasSubAssy check (see
-- UOM_ProcItemMasterStockList_Deploy.sql for the full review).