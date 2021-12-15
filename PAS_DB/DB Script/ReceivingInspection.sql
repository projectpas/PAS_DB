

CREATE TABLE [dbo].[ReceivingInspection](
	[ReceivingInspectionId] [bigint] IDENTITY(1,1) NOT NULL,
	[StockLineId] [bigint] NOT NULL,
	[CompanyName] [varchar](100) NOT NULL,
	[Address1] [nvarchar](250) NULL,
	[Address2] [nvarchar](250) NULL,
	[City] [varchar](50) NULL,
	[StateOrProvince] [varchar](50) NULL,
	[PostalCode] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Logo] [nvarchar](250) NULL,
	[PartCertificationNumber] [varchar](100) NULL,
	[PurchaseOrderNumber] [varchar](50) NULL,
	[RepairOrderNumber] [varchar](50) NULL,
	[PartNumber] [int] NOT NULL,
	[SerialNum] [int] NOT NULL,
	[Condition] [int] NOT NULL,
	[Qty] [int] NOT NULL,
	[ShelfLife] [int] NOT NULL,
	[LotBatchNum] [int] NOT NULL,
	[GeneralVisualInspection] [int] NOT NULL,
	[AppropriatePackaging] [int] NOT NULL,
	[ESDCapsandPackaging] [int] NOT NULL,
	[HazardousMaterial] [int] NOT NULL,
	[MeetsPORequirements] [int] NOT NULL,
	[CompletePaperwork] [int] NOT NULL,
	[Notes] [nvarchar](max) NULL,
	[Signature] [nvarchar](50) NULL,
	[ReceivedDate] [datetime2](7) NULL,
	[MasterCompanyId] [int] NOT NULL,
	[CreatedBy] [nvarchar](256) NOT NULL,
	[UpdatedBy] [nvarchar](256) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_ReceivingInspection] PRIMARY KEY CLUSTERED 
(
	[ReceivingInspectionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ReceivingInspection] ADD  CONSTRAINT [DF_ReceivingInspection_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[ReceivingInspection] ADD  CONSTRAINT [DF_ReceivingInspection_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
GO



CREATE TABLE [dbo].[ReceivingInspectionAudit](
	[ReceivingInspectionAuditId] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivingInspectionId] [bigint] NOT NULL,
	[StockLineId] [bigint] NOT NULL,
	[CompanyName] [varchar](100) NOT NULL,
	[Address1] [nvarchar](250) NULL,
	[Address2] [nvarchar](250) NULL,
	[City] [varchar](50) NULL,
	[StateOrProvince] [varchar](50) NULL,
	[PostalCode] [varchar](50) NULL,
	[Country] [varchar](50) NULL,
	[Logo] [nvarchar](250) NULL,
	[PartCertificationNumber] [varchar](100) NULL,
	[PurchaseOrderNumber] [varchar](50) NULL,
	[RepairOrderNumber] [varchar](50) NULL,
	[PartNumber] [int] NOT NULL,
	[SerialNum] [int] NOT NULL,
	[Condition] [int] NOT NULL,
	[Qty] [int] NOT NULL,
	[ShelfLife] [int] NOT NULL,
	[LotBatchNum] [int] NOT NULL,
	[GeneralVisualInspection] [int] NOT NULL,
	[AppropriatePackaging] [int] NOT NULL,
	[ESDCapsandPackaging] [int] NOT NULL,
	[HazardousMaterial] [int] NOT NULL,
	[MeetsPORequirements] [int] NOT NULL,
	[CompletePaperwork] [int] NOT NULL,
	[Notes] [nvarchar](max) NULL,
	[Signature] [nvarchar](50) NULL,
	[ReceivedDate] [datetime2](7) NULL,
	[MasterCompanyId] [int] NOT NULL,
	[CreatedBy] [nvarchar](256) NOT NULL,
	[UpdatedBy] [nvarchar](256) NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[UpdatedDate] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_ReceivingInspectionAudit] PRIMARY KEY CLUSTERED 
(
	[ReceivingInspectionAuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[ReceivingInspectionAudit] ADD  CONSTRAINT [DF_ReceivingInspectionAudit_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO

ALTER TABLE [dbo].[ReceivingInspectionAudit] ADD  CONSTRAINT [DF_ReceivingInspectionAudit_UpdatedDate]  DEFAULT (getdate()) FOR [UpdatedDate]
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