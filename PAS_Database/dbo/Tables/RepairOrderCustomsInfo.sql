CREATE TABLE [dbo].[RepairOrderCustomsInfo] (
    [RepairOrderCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderShippingId]    BIGINT          NOT NULL,
    [EntryType]                VARCHAR (100)   NULL,
    [EPU]                      VARCHAR (100)   NULL,
    [CustomsValue]             DECIMAL (20, 2) NULL,
    [NetMass]                  DECIMAL (20, 2) NULL,
    [EntryStatus]              VARCHAR (100)   NULL,
    [EntryNumber]              VARCHAR (100)   NULL,
    [VATValue]                 DECIMAL (20, 2) NULL,
    [UCR]                      VARCHAR (100)   NULL,
    [MasterUCR]                VARCHAR (100)   NULL,
    [MovementRefNo]            VARCHAR (100)   NULL,
    [CommodityCode]            VARCHAR (100)   NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_RepairOrderCustomsInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_RepairOrderCustomsInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_RCI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_RCI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomCurrencyId]         INT             NULL,
    CONSTRAINT [PK_RepairOrderCustomsInfo] PRIMARY KEY CLUSTERED ([RepairOrderCustomsInfoId] ASC),
    CONSTRAINT [FK_RepairOrderCustomsInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RepairOrderCustomsInfo_RepairOrderShipping] FOREIGN KEY ([RepairOrderShippingId]) REFERENCES [dbo].[RepairOrderShipping] ([RepairOrderShippingId])
);


GO
CREATE   TRIGGER [dbo].[Trg_RepairOrderCustomsInfoAudit]
   ON  [dbo].[RepairOrderCustomsInfo]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO RepairOrderCustomsInfoAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END