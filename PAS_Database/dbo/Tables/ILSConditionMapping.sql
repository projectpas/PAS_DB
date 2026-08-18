CREATE TABLE [dbo].[ILSConditionMapping] (
    [ILSConditionMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ConditionId]           BIGINT        NOT NULL,
    [ILSConditionId]        BIGINT        NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ILSConditionMappingId] ASC)
);

