CREATE TABLE [dbo].[PreliminaryInspectionItemMaster] (
    [PreliminaryInspectionItemMasterId] BIGINT IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId] INT NOT NULL,
    [SectionCode] VARCHAR (20) NOT NULL,
    [ItemName] VARCHAR (200) NOT NULL,
    [SortOrder] INT CONSTRAINT [DF_PreliminaryInspectionItemMaster_SortOrder] DEFAULT (0) NOT NULL,
    [OptionLabel1] VARCHAR (100) NULL,
    [OptionLabel2] VARCHAR (100) NULL,
    [CreatedBy] VARCHAR (256) NOT NULL,
    [UpdatedBy] VARCHAR (256) NOT NULL,
    [CreatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionItemMaster_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate] DATETIME2 (7) CONSTRAINT [DF_PreliminaryInspectionItemMaster_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive] BIT CONSTRAINT [DF_PreliminaryInspectionItemMaster_IsActive] DEFAULT (1) NOT NULL,
    [IsDeleted] BIT CONSTRAINT [DF_PreliminaryInspectionItemMaster_IsDeleted] DEFAULT (0) NOT NULL,
    CONSTRAINT [PK_PreliminaryInspectionItemMaster] PRIMARY KEY CLUSTERED ([PreliminaryInspectionItemMasterId] ASC),
    CONSTRAINT [FK_PreliminaryInspectionItemMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [CK_PreliminaryInspectionItemMaster_Section] CHECK ([SectionCode] IN ('QEC', 'OTHERPARTS', 'COMPONENTS'))
);

GO
CREATE NONCLUSTERED INDEX [IX_PreliminaryInspectionItemMaster_Company_Section] ON [dbo].[PreliminaryInspectionItemMaster] ([MasterCompanyId], [SectionCode], [SortOrder]);
