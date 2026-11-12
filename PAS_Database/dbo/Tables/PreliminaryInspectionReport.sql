CREATE TABLE [dbo].[PreliminaryInspectionReport] (
    [PreliminaryInspectionReportId] BIGINT IDENTITY (1, 1) NOT NULL,
    [WorkOrderId] BIGINT NOT NULL,
    [WorkOrderPartNumberId] BIGINT NULL,
    [MasterCompanyId] INT NOT NULL,
    [WorkScope] VARCHAR (200) NULL,
    [ReportStatus] VARCHAR (20) CONSTRAINT [DF_PreliminaryInspectionReport_ReportStatus] DEFAULT ('Draft') NOT NULL,
    [CompletedBy] VARCHAR (256) NULL,
    [CompletedDate] DATETIME2 (7) NULL,
    [ContainerIdAttached] BIT NULL,
    [ContainerCondition] VARCHAR (500) NULL,
    [ReplacementRequired] BIT NULL,
    [ShippingDamageAcknowledged] BIT NULL,
    [LogbookQuantity] INT NULL,
    [PicturesSavedInEngineFolder] BIT NULL,
    [EngineState] VARCHAR (20) NULL,
    [RotatingCondition] VARCHAR (20) NULL,
    [LinesCapped] BIT NULL,
    [InletDamage] VARCHAR (1000) NULL,
    [TurbineDamage] VARCHAR (1000) NULL,
    [OtherDamage] VARCHAR (1000) NULL,
    [ExternalDamage] VARCHAR (1000) NULL,
    [QecOther] VARCHAR (500) NULL,
    [RemoveBoxCustomerHardware] BIT NULL,
    [OtherPartsOther] VARCHAR (500) NULL,
    [Notes] NVARCHAR (MAX) NULL,
    [CreatedBy] VARCHAR (256) NOT NULL,
    [UpdatedBy] VARCHAR (256) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReport_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReport_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_PreliminaryInspectionReport_IsActive] DEFAULT (1) NOT NULL,
    [IsDeleted] BIT CONSTRAINT [DF_PreliminaryInspectionReport_IsDeleted] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReport] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportId] ASC),
    CONSTRAINT [FK_PreliminaryInspectionReport_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_PreliminaryInspectionReport_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [CK_PreliminaryInspectionReport_Status] CHECK ([ReportStatus] IN ('Draft', 'Completed'))
);

GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_PreliminaryInspectionReport_WorkOrderId] ON [dbo].[PreliminaryInspectionReport] ([WorkOrderId]) WHERE [IsDeleted] = 0;

GO
CREATE TABLE [dbo].[PreliminaryInspectionReportAudit] (
    [PreliminaryInspectionReportAuditId] BIGINT IDENTITY (1, 1) NOT NULL,
    [AuditAction] CHAR (1) NOT NULL,
    [AuditDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportAudit_AuditDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [PreliminaryInspectionReportId] BIGINT NULL,
    [WorkOrderId] BIGINT NULL,
    [WorkOrderPartNumberId] BIGINT NULL,
    [MasterCompanyId] INT NULL,
    [WorkScope] VARCHAR (200) NULL,
    [ReportStatus] VARCHAR (20) NULL,
    [CompletedBy] VARCHAR (256) NULL,
    [CompletedDate] DATETIME2 (7) NULL,
    [ContainerIdAttached] BIT NULL,
    [ContainerCondition] VARCHAR (500) NULL,
    [ReplacementRequired] BIT NULL,
    [ShippingDamageAcknowledged] BIT NULL,
    [LogbookQuantity] INT NULL,
    [PicturesSavedInEngineFolder] BIT NULL,
    [EngineState] VARCHAR (20) NULL,
    [RotatingCondition] VARCHAR (20) NULL,
    [LinesCapped] BIT NULL,
    [InletDamage] VARCHAR (1000) NULL,
    [TurbineDamage] VARCHAR (1000) NULL,
    [OtherDamage] VARCHAR (1000) NULL,
    [ExternalDamage] VARCHAR (1000) NULL,
    [QecOther] VARCHAR (500) NULL,
    [RemoveBoxCustomerHardware] BIT NULL,
    [OtherPartsOther] VARCHAR (500) NULL,
    [Notes] NVARCHAR (MAX) NULL,
    [CreatedBy] VARCHAR (256) NULL,
    [UpdatedBy] VARCHAR (256) NULL,
    [CreatedDate] DATETIME2 (7) NULL,
    [UpdatedDate] DATETIME2 (7) NULL,
    [IsActive] BIT NULL,
    [IsDeleted] BIT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportAudit] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportAuditId] ASC)
);

GO
CREATE TRIGGER [dbo].[Trg_PreliminaryInspectionReportAudit]
   ON [dbo].[PreliminaryInspectionReport]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[PreliminaryInspectionReportAudit] ([AuditAction], [PreliminaryInspectionReportId], [WorkOrderId], [WorkOrderPartNumberId], [MasterCompanyId], [WorkScope], [ReportStatus], [CompletedBy], [CompletedDate], [ContainerIdAttached], [ContainerCondition], [ReplacementRequired], [ShippingDamageAcknowledged], [LogbookQuantity], [PicturesSavedInEngineFolder], [EngineState], [RotatingCondition], [LinesCapped], [InletDamage], [TurbineDamage], [OtherDamage], [ExternalDamage], [QecOther], [RemoveBoxCustomerHardware], [OtherPartsOther], [Notes], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN 'U' ELSE 'I' END, [PreliminaryInspectionReportId], [WorkOrderId], [WorkOrderPartNumberId], [MasterCompanyId], [WorkScope], [ReportStatus], [CompletedBy], [CompletedDate], [ContainerIdAttached], [ContainerCondition], [ReplacementRequired], [ShippingDamageAcknowledged], [LogbookQuantity], [PicturesSavedInEngineFolder], [EngineState], [RotatingCondition], [LinesCapped], [InletDamage], [TurbineDamage], [OtherDamage], [ExternalDamage], [QecOther], [RemoveBoxCustomerHardware], [OtherPartsOther], [Notes], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
    FROM inserted;

    INSERT INTO [dbo].[PreliminaryInspectionReportAudit] ([AuditAction], [PreliminaryInspectionReportId], [WorkOrderId], [WorkOrderPartNumberId], [MasterCompanyId], [WorkScope], [ReportStatus], [CompletedBy], [CompletedDate], [ContainerIdAttached], [ContainerCondition], [ReplacementRequired], [ShippingDamageAcknowledged], [LogbookQuantity], [PicturesSavedInEngineFolder], [EngineState], [RotatingCondition], [LinesCapped], [InletDamage], [TurbineDamage], [OtherDamage], [ExternalDamage], [QecOther], [RemoveBoxCustomerHardware], [OtherPartsOther], [Notes], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT 'D', d.[PreliminaryInspectionReportId], d.[WorkOrderId], d.[WorkOrderPartNumberId], d.[MasterCompanyId], d.[WorkScope], d.[ReportStatus], d.[CompletedBy], d.[CompletedDate], d.[ContainerIdAttached], d.[ContainerCondition], d.[ReplacementRequired], d.[ShippingDamageAcknowledged], d.[LogbookQuantity], d.[PicturesSavedInEngineFolder], d.[EngineState], d.[RotatingCondition], d.[LinesCapped], d.[InletDamage], d.[TurbineDamage], d.[OtherDamage], d.[ExternalDamage], d.[QecOther], d.[RemoveBoxCustomerHardware], d.[OtherPartsOther], d.[Notes], d.[CreatedBy], d.[UpdatedBy], d.[CreatedDate], d.[UpdatedDate], d.[IsActive], d.[IsDeleted]
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted);
END
