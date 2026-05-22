CREATE TABLE [dbo].[MaintenanceCategory] (
    [MtcCategoryId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [MtcCategory]     VARCHAR (256) NOT NULL,
    [Description]     VARCHAR (MAX) NULL,
    [MaintenanceCode] VARCHAR (256) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_MtcCategory_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_MtcCategory_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_MtcCategory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_MtcCategory_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_MtcCategory] PRIMARY KEY CLUSTERED ([MtcCategoryId] ASC)
);

