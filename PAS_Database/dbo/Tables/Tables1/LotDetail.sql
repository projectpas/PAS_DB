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


GO
-- [PN-18450] 29-Oct-2026 - Performance: dbo.USP_Lot_GetLotList (30+ sec) EXISTS (lot has detail) check
CREATE NONCLUSTERED INDEX [IX_LotDetail_LotId_Perf]
    ON [dbo].[LotDetail]([LotId] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
