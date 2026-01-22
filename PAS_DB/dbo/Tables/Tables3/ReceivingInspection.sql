CREATE TABLE [dbo].[ReceivingInspection] (
    [ReceivingInspectionId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [StockLineId]             BIGINT         NOT NULL,
    [CompanyName]             VARCHAR (100)  NOT NULL,
    [Address1]                NVARCHAR (250) NULL,
    [Address2]                NVARCHAR (250) NULL,
    [City]                    VARCHAR (50)   NULL,
    [StateOrProvince]         VARCHAR (50)   NULL,
    [PostalCode]              VARCHAR (50)   NULL,
    [Country]                 VARCHAR (50)   NULL,
    [Logo]                    NVARCHAR (250) NULL,
    [PartCertificationNumber] VARCHAR (100)  NULL,
    [PurchaseOrderNumber]     VARCHAR (50)   NULL,
    [RepairOrderNumber]       VARCHAR (50)   NULL,
    [PartNumber]              INT            NOT NULL,
    [SerialNum]               INT            NOT NULL,
    [Condition]               INT            NOT NULL,
    [Qty]                     INT            NOT NULL,
    [ShelfLife]               INT            NOT NULL,
    [LotBatchNum]             INT            NOT NULL,
    [GeneralVisualInspection] INT            NOT NULL,
    [AppropriatePackaging]    INT            NOT NULL,
    [ESDCapsandPackaging]     INT            NOT NULL,
    [HazardousMaterial]       INT            NOT NULL,
    [MeetsPORequirements]     INT            NOT NULL,
    [CompletePaperwork]       INT            NOT NULL,
    [Notes]                   NVARCHAR (MAX) NULL,
    [Signature]               NVARCHAR (50)  NULL,
    [ReceivedDate]            DATETIME2 (7)  NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               NVARCHAR (256) NOT NULL,
    [UpdatedBy]               NVARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ReceivingInspection_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_ReceivingInspection_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_ReceivingInspection] PRIMARY KEY CLUSTERED ([ReceivingInspectionId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ReceivingInspectionAudit]
   ON  [dbo].[ReceivingInspection]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
		INSERT INTO [dbo].[ReceivingInspectionAudit]
		SELECT * FROM INSERTED
		SET NOCOUNT ON;
END