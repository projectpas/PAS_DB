CREATE TABLE [dbo].[DealLossReasonMapping] (
    [DealLossReasonMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]                INT           NULL,
    [ReferenceId]             BIGINT        NULL,
    [DealLossReasonId]        BIGINT        NOT NULL,
    [CreatedDate]             DATETIME2 (7) NULL,
    [CreatedBy]               VARCHAR (256) NULL,
    [UpdatedDate]             DATETIME2 (7) NULL,
    [UpdatedBy]               VARCHAR (256) NULL,
    [IsActive]                BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DealLossReasonMapping] PRIMARY KEY CLUSTERED ([DealLossReasonMappingId] ASC)
);

