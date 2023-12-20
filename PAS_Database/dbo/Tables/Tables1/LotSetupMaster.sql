CREATE TABLE [dbo].[LotSetupMaster] (
    [LotSetupId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [LotId]              BIGINT          NULL,
    [IsUseMargin]        BIT             NULL,
    [MarginPercentageId] BIGINT          NULL,
    [IsOverallLotCost]   BIT             NULL,
    [IsCostToPN]         BIT             NULL,
    [IsReturnCoreToLot]  BIT             NULL,
    [IsMaintainStkLine]  BIT             NULL,
    [CommissionCost]     DECIMAL (18, 2) NULL,
    [MasterCompanyId]    INT             CONSTRAINT [DF_LotSetupMaster_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]          VARCHAR (256)   NOT NULL,
    [UpdatedBy]          VARCHAR (256)   NOT NULL,
    [CreatedDate]        DATETIME2 (7)   NOT NULL,
    [UpdatedDate]        DATETIME2 (7)   NULL,
    [IsActive]           BIT             CONSTRAINT [DF_LotSetupMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT             CONSTRAINT [DF_LotSetupMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LotSetupMaster] PRIMARY KEY CLUSTERED ([LotSetupId] ASC),
    CONSTRAINT [FK_LotSetupMaster_Lot] FOREIGN KEY ([LotId]) REFERENCES [dbo].[Lot] ([LotId])
);

