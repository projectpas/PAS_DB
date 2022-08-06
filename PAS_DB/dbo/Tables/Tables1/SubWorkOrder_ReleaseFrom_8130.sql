﻿CREATE TABLE [dbo].[SubWorkOrder_ReleaseFrom_8130] (
    [SubReleaseFromId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkorderId]         BIGINT        NOT NULL,
    [SubWorkOrderId]      BIGINT        NOT NULL,
    [SubWOPartNoId]       BIGINT        NOT NULL,
    [Country]             VARCHAR (256) NULL,
    [OrganizationName]    VARCHAR (MAX) NULL,
    [InvoiceNo]           VARCHAR (256) NULL,
    [ItemName]            VARCHAR (256) NULL,
    [Description]         VARCHAR (500) NULL,
    [PartNumber]          VARCHAR (256) NULL,
    [Reference]           VARCHAR (256) NULL,
    [Quantity]            INT           NULL,
    [Batchnumber]         VARCHAR (256) NULL,
    [status]              VARCHAR (20)  NULL,
    [Remarks]             VARCHAR (MAX) NULL,
    [Certifies]           VARCHAR (256) NULL,
    [approved]            BIT           NULL,
    [Nonapproved]         BIT           NULL,
    [AuthorisedSign]      VARCHAR (256) NULL,
    [AuthorizationNo]     VARCHAR (256) NULL,
    [PrintedName]         VARCHAR (256) NULL,
    [Date]                DATETIME      NULL,
    [AuthorisedSign2]     VARCHAR (256) NULL,
    [ApprovalCertificate] VARCHAR (256) NULL,
    [PrintedName2]        VARCHAR (256) NULL,
    [Date2]               DATETIME      NULL,
    [CFR]                 BIT           NULL,
    [Otherregulation]     BIT           NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NOT NULL,
    [IsDeleted]           BIT           NOT NULL,
    [trackingNo]          VARCHAR (20)  NULL,
    [OrganizationAddress] VARCHAR (500) NULL,
    [is8130from]          BIT           NULL,
    [IsClosed]            BIT           DEFAULT ((0)) NOT NULL,
    [PDFPath]             VARCHAR (MAX) NULL,
    [IsEASALicense]       BIT           NULL,
    CONSTRAINT [PK_SubWorkOrder_ReleaseFrom_8130] PRIMARY KEY CLUSTERED ([SubReleaseFromId] ASC)
);






GO






Create TRIGGER [dbo].[Trg_SubWorkOrder_ReleaseFrom_8130Audit]

   ON  [dbo].[SubWorkOrder_ReleaseFrom_8130]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN





	INSERT INTO SubWorkOrder_ReleaseFrom_8130Audit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END