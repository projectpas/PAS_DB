CREATE TABLE [dbo].[Duration] (
    [DurationId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [DurationName]    VARCHAR (100)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Duration_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Duration_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Duration_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Duration_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Duration] PRIMARY KEY CLUSTERED ([DurationId] ASC),
    CONSTRAINT [FK_Duration_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Duration] UNIQUE NONCLUSTERED ([DurationName] ASC, [MasterCompanyId] ASC)
);

