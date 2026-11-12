CREATE TABLE [dbo].[PreliminaryInspectionReportPhoto] (
    [PreliminaryInspectionReportPhotoId] BIGINT IDENTITY (1, 1) NOT NULL,
    [PreliminaryInspectionReportId] BIGINT NOT NULL,
    [MasterCompanyId] INT NOT NULL,
    [SectionCode] VARCHAR (20) NOT NULL,
    [FileName] VARCHAR (500) NOT NULL,
    [FilePath] VARCHAR (1000) NOT NULL,
    [FileType] VARCHAR (200) NULL,
    [FileSize] DECIMAL (18, 2) NULL,
    [CreatedBy] VARCHAR (256) NOT NULL,
    [UpdatedBy] VARCHAR (256) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportPhoto_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionReportPhoto_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_PreliminaryInspectionReportPhoto_IsActive] DEFAULT (1) NOT NULL,
    [IsDeleted] BIT CONSTRAINT [DF_PreliminaryInspectionReportPhoto_IsDeleted] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_PreliminaryInspectionReportPhoto] PRIMARY KEY CLUSTERED ([PreliminaryInspectionReportPhotoId] ASC),
    CONSTRAINT [FK_PreliminaryInspectionReportPhoto_Report] FOREIGN KEY ([PreliminaryInspectionReportId]) REFERENCES [dbo].[PreliminaryInspectionReport] ([PreliminaryInspectionReportId]),
    CONSTRAINT [CK_PreliminaryInspectionReportPhoto_Section] CHECK ([SectionCode] IN ('SHIPPING', 'ENGINE'))
);

GO
CREATE NONCLUSTERED INDEX [IX_PreliminaryInspectionReportPhoto_Report] ON [dbo].[PreliminaryInspectionReportPhoto] ([PreliminaryInspectionReportId]);
