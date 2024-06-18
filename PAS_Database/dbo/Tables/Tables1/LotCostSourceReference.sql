CREATE TABLE [dbo].[LotCostSourceReference] (
    [LotSourceId]     INT           IDENTITY (1, 1) NOT NULL,
    [SourceName]      VARCHAR (50)  NOT NULL,
    [Code]            VARCHAR (20)  NULL,
    [SequenceNo]      INT           NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [LotCostSourceReference_CD_UDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [LotCostSourceReference_UD_UDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_LotCostSourceReference_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_LotCostSourceReference_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LotCostSourceReference] PRIMARY KEY CLUSTERED ([LotSourceId] ASC)
);



