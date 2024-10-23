CREATE TABLE [dbo].[SalesOrderReserveParts] (
    [SalesOrderReservePartId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]            BIGINT        NULL,
    [StockLineId]             BIGINT        NOT NULL,
    [ItemMasterId]            BIGINT        NOT NULL,
    [PartStatusId]            INT           NOT NULL,
    [IsEquPart]               BIT           NOT NULL,
    [EquPartMasterPartId]     BIGINT        NULL,
    [IsAltPart]               BIT           NOT NULL,
    [AltPartMasterPartId]     BIGINT        NULL,
    [QtyToReserve]            INT           NULL,
    [QtyToIssued]             INT           NULL,
    [ReservedById]            BIGINT        NULL,
    [ReservedDate]            DATETIME2 (7) NULL,
    [IssuedById]              BIGINT        NULL,
    [IssuedDate]              DATETIME2 (7) NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_SalesOrderReserveParts_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_SalesOrderReserveParts_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_SalesOrderReserveParts_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_SalesOrderReserveParts_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SalesOrderPartId]        BIGINT        NOT NULL,
    [TotalReserved]           INT           NULL,
    [TotalIssued]             INT           NULL,
    [MasterCompanyId]         INT           NOT NULL,
    CONSTRAINT [PK_SalesOrderReserveParts] PRIMARY KEY CLUSTERED ([SalesOrderReservePartId] ASC),
    CONSTRAINT [FK_SalesOrderReserveParts_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderReserveParts_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderReserveParts_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderReservePartsAudit]

   ON  [dbo].[SalesOrderReserveParts]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderReservePartsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END