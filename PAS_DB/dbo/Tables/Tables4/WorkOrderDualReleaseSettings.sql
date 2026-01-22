CREATE TABLE [dbo].[WorkOrderDualReleaseSettings] (
    [WorkOrderDualReleaseSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTypeId]               INT           NOT NULL,
    [CountriesId]                   BIGINT        NULL,
    [Dualreleaselanguage]           VARCHAR (MAX) NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           NOT NULL,
    [IsDeleted]                     BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderDualReleaseSettings] PRIMARY KEY CLUSTERED ([WorkOrderDualReleaseSettingId] ASC)
);

