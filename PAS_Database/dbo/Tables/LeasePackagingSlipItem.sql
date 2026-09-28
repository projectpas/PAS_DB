CREATE TABLE [dbo].[LeasePackagingSlipItem] (
    [PackagingSlipItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PackagingSlipId]     BIGINT         NOT NULL,
    [LeasePickTicketId]   BIGINT         NOT NULL,
    [LeaseStocklineId]    BIGINT         NOT NULL,
    [PDFPath]             NVARCHAR (500) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PackagingSlipItemId] ASC)
);

