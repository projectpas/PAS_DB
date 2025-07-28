CREATE TABLE [dbo].[Years] (
    [YearId]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [YearName]        VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Years_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Years_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Years_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Years_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Years] PRIMARY KEY CLUSTERED ([YearId] ASC)
);

