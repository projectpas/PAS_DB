CREATE TABLE [dbo].[LotStatus] (
    [LotStatusId]     INT           IDENTITY (1, 1) NOT NULL,
    [StatusName]      VARCHAR (50)  NOT NULL,
    [Code]            VARCHAR (20)  NULL,
    [SequenceNo]      INT           NULL,
    [MasterCompanyId] INT           CONSTRAINT [DF_LotStatus_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_LotStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_LotStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LotStatus] PRIMARY KEY CLUSTERED ([LotStatusId] ASC)
);

