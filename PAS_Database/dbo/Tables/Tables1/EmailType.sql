CREATE TABLE [dbo].[EmailType] (
    [EmailTypeID]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256) NOT NULL,
    [Description]     VARCHAR (MAX) NULL,
    [Memo]            VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_EmailType_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_EmailType_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [EmailType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [EmailType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmailType] PRIMARY KEY CLUSTERED ([EmailTypeID] ASC)
);

