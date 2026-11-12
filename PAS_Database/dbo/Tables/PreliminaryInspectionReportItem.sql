CREATE TABLE [dbo].[PreliminaryInspectionReportItem] (
    [PreliminaryInspectionReportItemId] BIGINT IDENTITY (1, 1) NOT NULL,
    [PreliminaryInspectionReportId] BIGINT NOT NULL,
    [PreliminaryInspectionItemMasterId] BIGINT NOT NULL,
    [MasterCompanyId] INT NOT NULL,
    [SectionCode] VARCHAR (20) NOT NULL,
    [ItemName] VARCHAR (200) NOT NULL,
    [SortOrder] INT NULL,
    [Answer] VARCHAR (3) NULL,
    [Remarks] VARCHAR (500) NULL,
    [PartNumber] VARCHAR (100) NULL,
    [SerialNumber] VARCHAR (100) NULL,
    [SeriesNumber] VARCHAR (100) NULL,
    [SelectedOption] TINYINT NULL,
    [CreatedBy] VARCHAR (256) NOT NULL,
    [UpdatedBy] VARCHAR (256) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportItem_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportItem_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_PreliminaryInspectionReportItem_IsActive] DEFAULT (1) NOT NULL,
    [IsDeleted] BIT CONSTRAINT [DF_PreliminaryInspectionReportItem_IsDeleted] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportItem] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportItemId] ASC),
    CONSTRAINT [FK_PreliminaryInspectionReportItem_Report] FOREIGN KEY ([PreliminaryInspectionReportId]) REFERENCES [dbo].[PreliminaryInspectionReport] ([PreliminaryInspectionReportId]),
    CONSTRAINT [FK_PreliminaryInspectionReportItem_ItemMaster] FOREIGN KEY ([PreliminaryInspectionItemMasterId]) REFERENCES [dbo].[PreliminaryInspectionItemMaster] ([PreliminaryInspectionItemMasterId]),
    CONSTRAINT [UQ_PreliminaryInspectionReportItem] UNIQUE NONCLUSTERED ([PreliminaryInspectionReportId], [PreliminaryInspectionItemMasterId]),
    CONSTRAINT [CK_PreliminaryInspectionReportItem_Answer] CHECK ([Answer] IS NULL OR [Answer] IN ('Yes', 'No'))
);

GO
CREATE TABLE [dbo].[PreliminaryInspectionReportItemAudit] (
    [PreliminaryInspectionReportItemAuditId] BIGINT IDENTITY (1, 1) NOT NULL,
    [AuditAction] CHAR (1) NOT NULL,
    [AuditDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportItemAudit_AuditDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [PreliminaryInspectionReportItemId] BIGINT NULL,
    [PreliminaryInspectionReportId] BIGINT NULL,
    [PreliminaryInspectionItemMasterId] BIGINT NULL,
    [MasterCompanyId] INT NULL,
    [SectionCode] VARCHAR (20) NULL,
    [ItemName] VARCHAR (200) NULL,
    [SortOrder] INT NULL,
    [Answer] VARCHAR (3) NULL,
    [Remarks] VARCHAR (500) NULL,
    [PartNumber] VARCHAR (100) NULL,
    [SerialNumber] VARCHAR (100) NULL,
    [SeriesNumber] VARCHAR (100) NULL,
    [SelectedOption] TINYINT NULL,
    [CreatedBy] VARCHAR (256) NULL,
    [UpdatedBy] VARCHAR (256) NULL,
    [CreatedDate] DATETIME2 (7) NULL,
    [UpdatedDate] DATETIME2 (7) NULL,
    [IsActive] BIT NULL,
    [IsDeleted] BIT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportItemAudit] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportItemAuditId] ASC)
);

GO
CREATE TRIGGER [dbo].[Trg_PreliminaryInspectionReportItemAudit]
   ON [dbo].[PreliminaryInspectionReportItem]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[PreliminaryInspectionReportItemAudit] ([AuditAction], [PreliminaryInspectionReportItemId], [PreliminaryInspectionReportId], [PreliminaryInspectionItemMasterId], [MasterCompanyId], [SectionCode], [ItemName], [SortOrder], [Answer], [Remarks], [PartNumber], [SerialNumber], [SeriesNumber], [SelectedOption], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN 'U' ELSE 'I' END, [PreliminaryInspectionReportItemId], [PreliminaryInspectionReportId], [PreliminaryInspectionItemMasterId], [MasterCompanyId], [SectionCode], [ItemName], [SortOrder], [Answer], [Remarks], [PartNumber], [SerialNumber], [SeriesNumber], [SelectedOption], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
    FROM inserted;

    INSERT INTO [dbo].[PreliminaryInspectionReportItemAudit] ([AuditAction], [PreliminaryInspectionReportItemId], [PreliminaryInspectionReportId], [PreliminaryInspectionItemMasterId], [MasterCompanyId], [SectionCode], [ItemName], [SortOrder], [Answer], [Remarks], [PartNumber], [SerialNumber], [SeriesNumber], [SelectedOption], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT 'D', d.[PreliminaryInspectionReportItemId], d.[PreliminaryInspectionReportId], d.[PreliminaryInspectionItemMasterId], d.[MasterCompanyId], d.[SectionCode], d.[ItemName], d.[SortOrder], d.[Answer], d.[Remarks], d.[PartNumber], d.[SerialNumber], d.[SeriesNumber], d.[SelectedOption], d.[CreatedBy], d.[UpdatedBy], d.[CreatedDate], d.[UpdatedDate], d.[IsActive], d.[IsDeleted]
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted);
END
