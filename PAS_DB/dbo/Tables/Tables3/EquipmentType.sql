CREATE TABLE [dbo].[EquipmentType] (
    [EquipmentTypeId] SMALLINT     IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50) NOT NULL,
    [IsActive]        BIT          NULL,
    CONSTRAINT [PK_EquipmentType] PRIMARY KEY CLUSTERED ([EquipmentTypeId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_EquipmentTypeAudit]

   ON  [dbo].[EquipmentType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO EquipmentTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END