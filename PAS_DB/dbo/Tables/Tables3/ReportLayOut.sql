CREATE TABLE [dbo].[ReportLayOut] (
    [ReportLayOutId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [ReportTypeId]     BIGINT        NOT NULL,
    [ReportLayOutName] VARCHAR (100) NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_ReportLayOut_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_ReportLayOut_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_ReportLayOut_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_ReportLayOut] PRIMARY KEY CLUSTERED ([ReportLayOutId] ASC)
);

