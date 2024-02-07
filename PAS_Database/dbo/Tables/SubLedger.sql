CREATE TABLE [dbo].[SubLedger] (
    [SubLedgerId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Code]            VARCHAR (50)  NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_SubLedger_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_SubLedger_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [SubLedger_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [SubLedger_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubLedger] PRIMARY KEY CLUSTERED ([SubLedgerId] ASC)
);

