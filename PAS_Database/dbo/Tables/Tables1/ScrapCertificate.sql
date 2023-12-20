CREATE TABLE [dbo].[ScrapCertificate] (
    [ScrapCertificateId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT        NOT NULL,
    [workOrderPartNoId]   BIGINT        NOT NULL,
    [IsExternal]          BIT           NULL,
    [ScrapedByEmployeeId] BIGINT        NULL,
    [ScrapedByVendorId]   BIGINT        NULL,
    [CertifiedById]       BIGINT        NULL,
    [ScrapReasonId]       BIGINT        NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [ScrapCertificate_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [ScrapCertificate_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [ScrapCertificate_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [ScrapCertificate_DC_Delete] DEFAULT ((0)) NOT NULL,
    [isSubWorkOrder]      BIT           NULL,
    CONSTRAINT [PK_ScrapCertificate] PRIMARY KEY CLUSTERED ([ScrapCertificateId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_ScrapCertificateAudit] ON [dbo].[ScrapCertificate]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

 INSERT INTO [dbo].[ScrapCertificateAudit]  

 SELECT * FROM INSERTED  

 SET NOCOUNT ON;  



END