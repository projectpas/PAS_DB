CREATE TABLE [dbo].[ReportType] (
    [ReportTypeId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReportTypeName]  VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_ReportType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_ReportType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_ReportType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_ReportType] PRIMARY KEY CLUSTERED ([ReportTypeId] ASC)
);

