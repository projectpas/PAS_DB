CREATE TABLE [dbo].[SOPartStatus] (
    [SOPartStatusId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [PartStatus]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [SOPartStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [SOPartStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [SOPartStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [SOPartStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SOPartStatus] PRIMARY KEY CLUSTERED ([SOPartStatusId] ASC),
    CONSTRAINT [Unique_SOPartStatus] UNIQUE NONCLUSTERED ([PartStatus] ASC, [MasterCompanyId] ASC)
);

