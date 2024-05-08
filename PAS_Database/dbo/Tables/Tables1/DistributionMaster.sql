CREATE TABLE [dbo].[DistributionMaster] (
    [ID]               BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]             VARCHAR (200) NOT NULL,
    [DistributionCode] VARCHAR (200) NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    [IsAllowAddBatch]  BIT           NULL,
    [JournalTypeId]    BIGINT        NULL,
    CONSTRAINT [PK_DistributionMaster] PRIMARY KEY CLUSTERED ([ID] ASC)
);



