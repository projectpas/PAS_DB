CREATE TABLE [dbo].[NachaFileIDDetails] (
    [NachaId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [FileId]          VARCHAR (10)  NOT NULL,
    [FieldNumber]     INT           NOT NULL,
    [LegalEntityId]   BIGINT        NOT NULL,
    [CalendarDay]     DATE          NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_NachaFileIDDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_NachaFileIDDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_NachaFileIDDetails] PRIMARY KEY CLUSTERED ([NachaId] ASC)
);

