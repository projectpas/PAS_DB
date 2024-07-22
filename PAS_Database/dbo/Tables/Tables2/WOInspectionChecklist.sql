CREATE TABLE [dbo].[WOInspectionChecklist] (
    [WOInspectionId]                       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReceivingCustomerWorkId]              BIGINT         NOT NULL,
    [CertNum]                              VARCHAR (200)  NULL,
    [CustomerName]                         VARCHAR (100)  NULL,
    [CustomerRef]                          NVARCHAR (250) NULL,
    [ACTailNum]                            NVARCHAR (250) NULL,
    [PartNumber]                           VARCHAR (200)  NULL,
    [PartDiscription]                      VARCHAR (MAX)  NULL,
    [Manufacturer]                         VARCHAR (200)  NULL,
    [SerialNumber]                         VARCHAR (200)  NULL,
    [IstheIDPlatemissing]                  INT            NULL,
    [DothePNsonunitID]                     INT            NULL,
    [IstheShippingContainerDamaged]        INT            NULL,
    [Doestheunithavephysicaldamage]        INT            NULL,
    [Doestheunithavelooseormissingparts]   INT            NULL,
    [Arethecapsshuntsorclipsmissing]       INT            NULL,
    [Aretheconnectorspinsdamaged]          INT            NULL,
    [Isthereaservicehistoryforthisunit]    INT            NULL,
    [AreXXXXXXwarrantysealstamperedwith]   INT            NULL,
    [Doestheunithaswarranty]               INT            NULL,
    [HavetheotherRSsseals]                 INT            NULL,
    [Notes]                                NVARCHAR (MAX) NULL,
    [WorkRequested]                        NVARCHAR (MAX) NULL,
    [SpecialInstructions]                  NVARCHAR (MAX) NULL,
    [TroubleReported]                      NVARCHAR (MAX) NULL,
    [ApplicableADs]                        NVARCHAR (MAX) NULL,
    [ShippingContainers]                   NVARCHAR (MAX) NULL,
    [Comments]                             NVARCHAR (MAX) NULL,
    [TechnicalDataIsitCurrentandAvailable] BIT            NULL,
    [ReceivedBy]                           NVARCHAR (256) NULL,
    [Date]                                 DATETIME2 (7)  NULL,
    [MasterCompanyId]                      INT            NOT NULL,
    [CreatedBy]                            NVARCHAR (256) NOT NULL,
    [UpdatedBy]                            NVARCHAR (256) NOT NULL,
    [CreatedDate]                          DATETIME2 (7)  CONSTRAINT [DF_WOInspectionChecklist_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7)  CONSTRAINT [DF_WOInspectionChecklist_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_WOInspectionChecklist] PRIMARY KEY CLUSTERED ([WOInspectionId] ASC),
    CONSTRAINT [FK_WOInspectionChecklist_ReceivingCustomerWorkId] FOREIGN KEY ([ReceivingCustomerWorkId]) REFERENCES [dbo].[ReceivingCustomerWork] ([ReceivingCustomerWorkId])
);




GO






---------------------------------------------------------------------------------------------------------------------------------------



CREATE TRIGGER [dbo].[Trg_WOInspectionChecklistAudit]

   ON  [dbo].[WOInspectionChecklist]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO [dbo].[WOInspectionChecklistAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END