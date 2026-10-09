CREATE TABLE [dbo].[LeaseCustomsInfo] (
    [LeaseCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseShippingId]    BIGINT          NOT NULL,
    [EntryType]          VARCHAR (100)   NULL,
    [EPU]                VARCHAR (100)   NULL,
    [CustomsValue]       DECIMAL (20, 6) NULL,
    [NetMass]            DECIMAL (20, 6) NULL,
    [EntryStatus]        VARCHAR (100)   NULL,
    [EntryNumber]        VARCHAR (100)   NULL,
    [VATValue]           DECIMAL (20, 6) NULL,
    [UCR]                VARCHAR (100)   NULL,
    [MasterUCR]          VARCHAR (100)   NULL,
    [MovementRefNo]      VARCHAR (100)   NULL,
    [CommodityCode]      VARCHAR (100)   NULL,
    [MasterCompanyId]    INT             NOT NULL,
    [CreatedBy]          VARCHAR (256)   NOT NULL,
    [UpdatedBy]          VARCHAR (256)   NOT NULL,
    [CreatedDate]        DATETIME2 (7)   CONSTRAINT [DF_LeaseCustomsInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)   CONSTRAINT [DF_LeaseCustomsInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT             CONSTRAINT [DF_LeaseCustomsInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT             CONSTRAINT [DF_LeaseCustomsInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomCurrencyId]   INT             NULL,
    CONSTRAINT [PK_LeaseCustomsInfo] PRIMARY KEY CLUSTERED ([LeaseCustomsInfoId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseCustomsInfoAudit]

   ON  dbo.LeaseCustomsInfo

   AFTER INSERT,UPDATE

AS 
BEGIN	   

	INSERT INTO [dbo].[LeaseCustomsInfoAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;

END