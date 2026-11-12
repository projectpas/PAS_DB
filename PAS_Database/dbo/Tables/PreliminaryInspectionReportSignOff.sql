CREATE TABLE [dbo].[PreliminaryInspectionReportSignOff] (
    [PreliminaryInspectionReportSignOffId] BIGINT IDENTITY (1, 1) NOT NULL,
    [PreliminaryInspectionReportId] BIGINT NOT NULL,
    [MasterCompanyId] INT NOT NULL,
    [SectionCode] VARCHAR (20) NOT NULL,
    [IsSigned] BIT CONSTRAINT [DF_PreliminaryInspectionReportSignOff_IsSigned] DEFAULT (0) NOT NULL,
    [SignedBy] VARCHAR (256) NULL,
    [SignedByEmployeeId] BIGINT NULL,
    [SignedInitials] VARCHAR (20) NULL,
    [SignedDate] DATETIME2 (7) NULL,
    [ReopenedBy] VARCHAR (256) NULL,
    [ReopenedDate] DATETIME2 (7) NULL,
    [CreatedBy] VARCHAR (256) NOT NULL,
    [UpdatedBy] VARCHAR (256) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportSignOff_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportSignOff_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_PreliminaryInspectionReportSignOff_IsActive] DEFAULT (1) NOT NULL,
    [IsDeleted] BIT CONSTRAINT [DF_PreliminaryInspectionReportSignOff_IsDeleted] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportSignOff] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportSignOffId] ASC),
    CONSTRAINT [FK_PreliminaryInspectionReportSignOff_Report] FOREIGN KEY ([PreliminaryInspectionReportId]) REFERENCES [dbo].[PreliminaryInspectionReport] ([PreliminaryInspectionReportId]),
    CONSTRAINT [UQ_PreliminaryInspectionReportSignOff] UNIQUE NONCLUSTERED ([PreliminaryInspectionReportId], [SectionCode]),
    CONSTRAINT [CK_PreliminaryInspectionReportSignOff_Section] CHECK ([SectionCode] IN ('SHIPPING', 'ENGINE', 'PARTS', 'REVIEW'))
);

GO
CREATE TABLE [dbo].[PreliminaryInspectionReportSignOffAudit] (
    [PreliminaryInspectionReportSignOffAuditId] BIGINT IDENTITY (1, 1) NOT NULL,
    [AuditAction] CHAR (1) NOT NULL,
    [AuditDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportSignOffAudit_AuditDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [PreliminaryInspectionReportSignOffId] BIGINT NULL,
    [PreliminaryInspectionReportId] BIGINT NULL,
    [MasterCompanyId] INT NULL,
    [SectionCode] VARCHAR (20) NULL,
    [IsSigned] BIT NULL,
    [SignedBy] VARCHAR (256) NULL,
    [SignedByEmployeeId] BIGINT NULL,
    [SignedInitials] VARCHAR (20) NULL,
    [SignedDate] DATETIME2 (7) NULL,
    [ReopenedBy] VARCHAR (256) NULL,
    [ReopenedDate] DATETIME2 (7) NULL,
    [CreatedBy] VARCHAR (256) NULL,
    [UpdatedBy] VARCHAR (256) NULL,
    [CreatedDate] DATETIME2 (7) NULL,
    [UpdatedDate] DATETIME2 (7) NULL,
    [IsActive] BIT NULL,
    [IsDeleted] BIT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportSignOffAudit] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportSignOffAuditId] ASC)
);

GO
CREATE TRIGGER [dbo].[Trg_PreliminaryInspectionReportSignOffAudit]
   ON [dbo].[PreliminaryInspectionReportSignOff]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[PreliminaryInspectionReportSignOffAudit] ([AuditAction], [PreliminaryInspectionReportSignOffId], [PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [IsSigned], [SignedBy], [SignedByEmployeeId], [SignedInitials], [SignedDate], [ReopenedBy], [ReopenedDate], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT CASE WHEN EXISTS (SELECT 1 FROM deleted) THEN 'U' ELSE 'I' END, [PreliminaryInspectionReportSignOffId], [PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [IsSigned], [SignedBy], [SignedByEmployeeId], [SignedInitials], [SignedDate], [ReopenedBy], [ReopenedDate], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted]
    FROM inserted;

    INSERT INTO [dbo].[PreliminaryInspectionReportSignOffAudit] ([AuditAction], [PreliminaryInspectionReportSignOffId], [PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [IsSigned], [SignedBy], [SignedByEmployeeId], [SignedInitials], [SignedDate], [ReopenedBy], [ReopenedDate], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
    SELECT 'D', d.[PreliminaryInspectionReportSignOffId], d.[PreliminaryInspectionReportId], d.[MasterCompanyId], d.[SectionCode], d.[IsSigned], d.[SignedBy], d.[SignedByEmployeeId], d.[SignedInitials], d.[SignedDate], d.[ReopenedBy], d.[ReopenedDate], d.[CreatedBy], d.[UpdatedBy], d.[CreatedDate], d.[UpdatedDate], d.[IsActive], d.[IsDeleted]
    FROM deleted d
    WHERE NOT EXISTS (SELECT 1 FROM inserted);
END
