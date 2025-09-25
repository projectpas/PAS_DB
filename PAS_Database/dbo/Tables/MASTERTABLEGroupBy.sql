CREATE TABLE [dbo].[MASTERTABLEGroupBy] (
    [Id]              BIGINT         NOT NULL,
    [Value]           NVARCHAR (100) NOT NULL,
    [MasterCompanyId] INT            DEFAULT ((0)) NULL,
    [CreatedBy]       VARCHAR (250)  CONSTRAINT [DF_MASTERTABLEGroupBy_CreatedBy] DEFAULT ('Admin') NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_MASTERTABLEGroupBy_CreatedDate] DEFAULT (sysutcdatetime()) NOT NULL,
    [UpdatedBy]       VARCHAR (250)  CONSTRAINT [DF_MASTERTABLEGroupBy_UpdatedBy] DEFAULT ('Admin') NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_MASTERTABLEGroupBy_UpdatedDate] DEFAULT (sysutcdatetime()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_MASTERTABLEGroupBy_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_MASTERTABLEGroupBy_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MASTERTABLEGroupBy_ID] PRIMARY KEY CLUSTERED ([Id] ASC)
);

