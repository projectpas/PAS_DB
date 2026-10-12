CREATE TABLE [dbo].[CycleCountSettingPrintField] (
    [CycleCountSettingPrintFieldId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CycleCountSettingId]           BIGINT        NOT NULL,
    [CountMethodId]                 INT           NOT NULL,
    [FieldKey]                      VARCHAR (50)  NOT NULL,
    [IsSelected]                    BIT           CONSTRAINT [DF_CycleCountSettingPrintField_IsSelected] DEFAULT ((0)) NOT NULL,
    [SequenceNo]                    INT           NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingPrintField_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_CycleCountSettingPrintField_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF_CycleCountSettingPrintField_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT           CONSTRAINT [DF_CycleCountSettingPrintField_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCountSettingPrintField] PRIMARY KEY CLUSTERED ([CycleCountSettingPrintFieldId] ASC),
    CONSTRAINT [FK_CycleCountSettingPrintField_CycleCountSettingMaster] FOREIGN KEY ([CycleCountSettingId]) REFERENCES [dbo].[CycleCountSettingMaster] ([CycleCountSettingId]),
    CONSTRAINT [FK_CycleCountSettingPrintField_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_CycleCountSettingPrintField_Field] UNIQUE NONCLUSTERED ([CycleCountSettingId] ASC, [CountMethodId] ASC, [FieldKey] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_CycleCountSettingPrintFieldAudit] ON [dbo].[CycleCountSettingPrintField]
AFTER INSERT,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CycleCountSettingPrintFieldAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
