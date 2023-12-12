CREATE TABLE [dbo].[Equipment] (
    [EquipmentId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (200) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Equipment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Equipment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Equipment] PRIMARY KEY CLUSTERED ([EquipmentId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_EquipmentAudit]

   ON  [dbo].[Equipment]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO EquipmentAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END