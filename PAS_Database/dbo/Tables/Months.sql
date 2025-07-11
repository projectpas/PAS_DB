CREATE TABLE [dbo].[Months] (
    [MonthId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [MonthName]       VARCHAR (100) NOT NULL,
    [MonthShortName]  VARCHAR (50)  NOT NULL,
    [MonthNumber]     INT           NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Months_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Months_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Months_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Months_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Months] PRIMARY KEY CLUSTERED ([MonthId] ASC)
);

