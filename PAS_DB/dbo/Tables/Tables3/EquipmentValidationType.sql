CREATE TABLE [dbo].[EquipmentValidationType] (
    [EquipmentValidationTypeId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]               VARCHAR (100) NULL,
    [IsActive]                  BIT           NULL,
    CONSTRAINT [PK_EquipmentValidationType] PRIMARY KEY CLUSTERED ([EquipmentValidationTypeId] ASC)
);


GO












CREATE TRIGGER [dbo].[Trg_EquipmentValidationTypeAudit]

   ON  [dbo].[EquipmentValidationType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[EquipmentValidationTypeAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END