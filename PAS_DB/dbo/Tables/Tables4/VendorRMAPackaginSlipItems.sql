CREATE TABLE [dbo].[VendorRMAPackaginSlipItems] (
    [PackagingSlipItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PackagingSlipId]     BIGINT         NOT NULL,
    [RMAPickTicketId]     BIGINT         NOT NULL,
    [VendorRMADetailId]   BIGINT         NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [PDFPath]             NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_VendorRMAPackaginSlipItems] PRIMARY KEY CLUSTERED ([PackagingSlipItemId] ASC)
);

