CREATE TABLE [dbo].[Nha_Tla_Alt_Equ_ItemMapping] (
    [ItemMappingId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]        BIGINT         NOT NULL,
    [MappingItemMasterId] BIGINT         NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MappingType]         INT            NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_Nha_Tla_Alt_Equ_ItemMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_Nha_Tla_Alt_Equ_ItemMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_Nha_Tla_Alt_Equ_ItemMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_Nha_Tla_Alt_Equ_ItemMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomerID]          BIGINT         NULL,
    CONSTRAINT [PK_Nha_Tla_Alt_Equ_ItemMapping] PRIMARY KEY CLUSTERED ([ItemMappingId] ASC),
    CONSTRAINT [FK_Nha_Tla_Alt_Equ_ItemMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_Nha_Tla_Alt_Equ_ItemMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_Nha_Tla_Alt_Equ_ItemMappingAudit]

   ON  [dbo].[Nha_Tla_Alt_Equ_ItemMapping]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[Nha_Tla_Alt_Equ_ItemMappingAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END
GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_NhaTlaAltEqu]

   ON  [dbo].[Nha_Tla_Alt_Equ_ItemMapping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



IF EXISTS (SELECT 1 FROM inserted)

	INSERT INTO NhaTlaAltEquAudit

	SELECT * FROM INSERTED

ELSE

	INSERT INTO NhaTlaAltEquAudit

	SELECT * FROM DELETED



	SET NOCOUNT ON;



END