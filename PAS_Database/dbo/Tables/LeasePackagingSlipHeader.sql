CREATE TABLE [dbo].[LeasePackagingSlipHeader] (
    [PackagingSlipId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LeaseHeaderId]   BIGINT        NOT NULL,
    [PackagingSlipNo] VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    PRIMARY KEY CLUSTERED ([PackagingSlipId] ASC)
);

