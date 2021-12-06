CREATE TABLE [dbo].[ExchangeSalesOrderReserveParts] (
    [ExchangeSalesOrderReservePartId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]            BIGINT        NULL,
    [StockLineId]                     BIGINT        NOT NULL,
    [ItemMasterId]                    BIGINT        NOT NULL,
    [PartStatusId]                    INT           NOT NULL,
    [IsEquPart]                       BIT           NOT NULL,
    [EquPartMasterPartId]             BIGINT        NULL,
    [IsAltPart]                       BIT           NOT NULL,
    [AltPartMasterPartId]             BIGINT        NULL,
    [QtyToReserve]                    INT           NULL,
    [QtyToIssued]                     INT           NULL,
    [ReservedById]                    BIGINT        NULL,
    [ReservedDate]                    DATETIME2 (7) NULL,
    [IssuedById]                      BIGINT        NULL,
    [IssuedDate]                      DATETIME2 (7) NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderReserveParts_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderReserveParts_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_ExchangeSalesOrderReserveParts_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_ExchangeSalesOrderReserveParts_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ExchangeSalesOrderPartId]        BIGINT        NOT NULL,
    [TotalReserved]                   INT           NULL,
    [TotalIssued]                     INT           NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderReserveParts] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderReservePartId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderReserveParts_Employee] FOREIGN KEY ([ReservedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrderReserveParts_ExchangeSalesOrderPart] FOREIGN KEY ([ExchangeSalesOrderPartId]) REFERENCES [dbo].[ExchangeSalesOrderPart] ([ExchangeSalesOrderPartId]),
    CONSTRAINT [FK_ExchangeSalesOrderReserveParts_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeSalesOrderReserveParts_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderReserveParts_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderReservePartsAudit]

   ON  [dbo].[ExchangeSalesOrderReserveParts]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderReservePartsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END