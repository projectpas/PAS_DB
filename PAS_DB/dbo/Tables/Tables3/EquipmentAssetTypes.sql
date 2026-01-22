CREATE TABLE [dbo].[EquipmentAssetTypes] (
    [Id]          INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50)  CONSTRAINT [DF__Equipment__Creat__5E40BC07] DEFAULT (NULL) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_EquipmentAssetTypes_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedBy]   VARCHAR (50)  CONSTRAINT [DF__Equipment__Updat__5F34E040] DEFAULT (NULL) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF__Equipment__Updat__60290479] DEFAULT (sysdatetime()) NOT NULL,
    [IsDeleted]   BIT           CONSTRAINT [DF__Equipment__IsDel__611D28B2] DEFAULT ((0)) NOT NULL,
    [Name]        VARCHAR (50)  CONSTRAINT [DF__EquipmentA__Name__62114CEB] DEFAULT (NULL) NOT NULL,
    [IsActive]    BIT           CONSTRAINT [DF_EquipmentAssetTypes_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK__Equipmen__3214EC076B24584F] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_EquipmentAssetTypesAudit]

   ON  [dbo].[EquipmentAssetTypes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO EquipmentAssetTypesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END