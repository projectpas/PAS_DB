CREATE TABLE [dbo].[EquipmentTypeAudit] (
    [EquipmentTypeAuditId] SMALLINT     IDENTITY (1, 1) NOT NULL,
    [EquipmentTypeId]      SMALLINT     NOT NULL,
    [Description]          VARCHAR (50) NOT NULL,
    [IsActive]             BIT          NULL,
    CONSTRAINT [PK_EquipmentTypeAudit] PRIMARY KEY CLUSTERED ([EquipmentTypeAuditId] ASC)
);

