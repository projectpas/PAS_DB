CREATE TABLE [dbo].[Nha_Tla_Alt_Equ_ItemMapping] (
    [ItemMappingId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]        BIGINT         NOT NULL,
    [MappingItemMasterId] BIGINT         NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MappingType]         INT            NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
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