CREATE TABLE [dbo].[EquipmentValidationTypeAudit] (
    [EquipmentValidationTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EquipmentValidationTypeId]      TINYINT       NOT NULL,
    [Description]                    VARCHAR (100) NULL,
    [IsActive]                       BIT           NULL,
    CONSTRAINT [PK_EquipmentValidationTypeAudit] PRIMARY KEY CLUSTERED ([EquipmentValidationTypeAuditId] ASC)
);

