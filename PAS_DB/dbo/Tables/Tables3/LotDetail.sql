CREATE TABLE [dbo].[LotDetail] (
    [LotIDetaild]       BIGINT       IDENTITY (1, 1) NOT NULL,
    [LotId]             BIGINT       NOT NULL,
    [VendorCode]        VARCHAR (50) NULL,
    [VendorName]        VARCHAR (50) NULL,
    [LotStatusName]     VARCHAR (50) NULL,
    [ObtainFromName]    VARCHAR (50) NULL,
    [TraceableToName]   VARCHAR (50) NULL,
    [ConsignmentNumber] VARCHAR (50) NULL,
    [ConsigneeName]     VARCHAR (50) NULL,
    [EmployeeName]      VARCHAR (50) NULL,
    CONSTRAINT [PK_LotDetail] PRIMARY KEY CLUSTERED ([LotIDetaild] ASC),
    CONSTRAINT [FK_LotDetail_Lot] FOREIGN KEY ([LotId]) REFERENCES [dbo].[Lot] ([LotId])
);

