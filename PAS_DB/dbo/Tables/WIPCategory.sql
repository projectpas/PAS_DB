CREATE TABLE [dbo].[WIPCategory] (
    [WIPCategoryId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [WIPCategory]     VARCHAR (256) NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL,
    [MasterCompanyId] INT           NULL,
    PRIMARY KEY CLUSTERED ([WIPCategoryId] ASC)
);

