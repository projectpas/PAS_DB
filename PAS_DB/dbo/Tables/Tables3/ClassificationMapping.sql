CREATE TABLE [dbo].[ClassificationMapping] (
    [ClassificationMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]                INT           NULL,
    [ReferenceId]             BIGINT        NULL,
    [ClasificationId]         BIGINT        NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_ClassificationMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_ClassificationMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_ClassificationMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_ClassificationMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ClassificationMapping] PRIMARY KEY CLUSTERED ([ClassificationMappingId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ClassificationMapping_ReferenceId_ModuleId_Perf]
    ON [dbo].[ClassificationMapping]([ReferenceId] ASC, [ModuleId] ASC)
    INCLUDE([ClasificationId]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
-- Added 2026-08-03: supports GetCustomerList's per-customer classification rollup (see
-- GetCustomerList_Performance_Recommendations.sql for the full review).


GO
CREATE NONCLUSTERED INDEX [IX_ClassificationMapping_ReferenceId_ModuleId]
    ON [dbo].[ClassificationMapping]([ReferenceId] ASC, [ModuleId] ASC)
    INCLUDE([ClasificationId]);

