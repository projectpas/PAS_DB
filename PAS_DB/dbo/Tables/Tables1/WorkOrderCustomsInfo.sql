CREATE TABLE [dbo].[WorkOrderCustomsInfo] (
    [WorkOrderCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderShippingId]    BIGINT          NOT NULL,
    [EntryType]              VARCHAR (100)   NULL,
    [EPU]                    VARCHAR (100)   NULL,
    [CustomsValue]           DECIMAL (20, 2) NULL,
    [NetMass]                DECIMAL (20, 2) NULL,
    [EntryStatus]            VARCHAR (100)   NULL,
    [EntryNumber]            VARCHAR (100)   NULL,
    [VATValue]               DECIMAL (20, 2) NULL,
    [UCR]                    VARCHAR (100)   NULL,
    [MasterUCR]              VARCHAR (100)   NULL,
    [MovementRefNo]          VARCHAR (100)   NULL,
    [CommodityCode]          VARCHAR (100)   NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCustomsInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCustomsInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF_WCI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_WCI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomCurrencyId]       INT             NULL,
    CONSTRAINT [PK_WorkOrderCustomsInfo] PRIMARY KEY CLUSTERED ([WorkOrderCustomsInfoId] ASC),
    CONSTRAINT [FK_WorkOrderCustomsInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderCustomsInfo_WorkOrderShipping] FOREIGN KEY ([WorkOrderShippingId]) REFERENCES [dbo].[WorkOrderShipping] ([WorkOrderShippingId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkOrderCustomsInfoAudit]

   ON  [dbo].[WorkOrderCustomsInfo]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderCustomsInfoAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END