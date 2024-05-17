CREATE TABLE [dbo].[ReportingStructure] (
    [ReportingStructureId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReportName]           VARCHAR (100) NOT NULL,
    [ReportDescription]    VARCHAR (256) NOT NULL,
    [IsVersionIncrease]    BIT           NOT NULL,
    [VersionNumber]        VARCHAR (20)  NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_ReportingStructure_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_ReportingStructure_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_ReportingStructure_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    [GlAccountClassId]     VARCHAR (MAX) NULL,
    [IsDefault]            BIT           NULL,
    [ReportTypeId]         BIGINT        NULL,
    CONSTRAINT [PK_ReportingStructure] PRIMARY KEY CLUSTERED ([ReportingStructureId] ASC),
    CONSTRAINT [FK_ReportingStructure_MasterCompnay] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



