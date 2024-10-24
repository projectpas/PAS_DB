﻿CREATE TABLE [dbo].[AppSettings] (
    [AppSettingsId]                   INT             IDENTITY (1, 1) NOT NULL,
    [SettingEnvironment]              VARCHAR (50)    NULL,
    [S3BucketName]                    VARCHAR (100)   NULL,
    [S3UploadFilePath]                NVARCHAR (MAX)  NULL,
    [S3CustomUploadFilePath]          NVARCHAR (MAX)  NULL,
    [S3SampleUploadFilePath]          NVARCHAR (MAX)  NULL,
    [S3UploadFileSize]                DECIMAL (18, 2) NULL,
    [AWS_ACCESS_KEY_ID]               VARCHAR (50)    NULL,
    [AWS_SECRET_ACCESS_KEY]           VARCHAR (50)    NULL,
    [Environment]                     VARCHAR (50)    NULL,
    [AWS_Region]                      VARCHAR (50)    NULL,
    [SecretId]                        VARCHAR (50)    NULL,
    [UploadFileSize]                  DECIMAL (18, 2) NULL,
    [UploadFilePath]                  NVARCHAR (MAX)  NULL,
    [CustomUploadFilePath]            NVARCHAR (MAX)  NULL,
    [SampleUploadFilePath]            NVARCHAR (MAX)  NULL,
    [ConnectionString]                NVARCHAR (MAX)  NULL,
    [LogsConnectionString]            NVARCHAR (MAX)  NULL,
    [PurchaseOrderPdfPath]            NVARCHAR (MAX)  NULL,
    [RepairOrderPdfPath]              NVARCHAR (MAX)  NULL,
    [ReportsUsername]                 VARCHAR (100)   NULL,
    [ReportsPassword]                 VARCHAR (100)   NULL,
    [PDFPath]                         NVARCHAR (MAX)  NULL,
    [EmailTemplatePathSO]             NVARCHAR (MAX)  NULL,
    [EmailTemplatePathSOQ]            NVARCHAR (MAX)  NULL,
    [EmailTemplatePathExchangeQuote]  NVARCHAR (MAX)  NULL,
    [WorkOrderPDFPath]                NVARCHAR (MAX)  NULL,
    [WorkOrderPrintPDFPath]           NVARCHAR (MAX)  NULL,
    [EmailTemplatePathWOQ]            NVARCHAR (MAX)  NULL,
    [WebUrl]                          NVARCHAR (100)  NULL,
    [EmailTemplatePathSpeedQuote]     NVARCHAR (MAX)  NULL,
    [ReleaseQTYTimeInHours]           INT             NULL,
    [ApplicationURL]                  NVARCHAR (100)  NULL,
    [WorkOrderPartPDFPath]            NVARCHAR (MAX)  NULL,
    [SubWorkOrderPDFPath]             NVARCHAR (MAX)  NULL,
    [WorkOrderPickticketPDFPath]      NVARCHAR (MAX)  NULL,
    [WorkOrderQuotePrintPDFPath]      NVARCHAR (MAX)  NULL,
    [WorkOrdershippingPDFPath]        NVARCHAR (MAX)  NULL,
    [WorkOrderStocklinePrintPDFPath]  NVARCHAR (MAX)  NULL,
    [WorkOrderMPNPDFPath]             NVARCHAR (MAX)  NULL,
    [SOPrintFilePath]                 NVARCHAR (MAX)  NULL,
    [SOPickTicketFilePath]            NVARCHAR (MAX)  NULL,
    [SOInvoiceFilePath]               NVARCHAR (MAX)  NULL,
    [SOPackagingSlipFilePath]         NVARCHAR (MAX)  NULL,
    [SOShippingLabelFilePath]         NVARCHAR (MAX)  NULL,
    [SOQuotePrintFilePath]            NVARCHAR (MAX)  NULL,
    [POPrintFilePath]                 NVARCHAR (MAX)  NULL,
    [ROPrintFilePath]                 NVARCHAR (MAX)  NULL,
    [ExchangeSOPrintFilePath]         NVARCHAR (MAX)  NULL,
    [ExchangeSOPickTicketFilePath]    NVARCHAR (MAX)  NULL,
    [ExchangeSOInvoiceFilePath]       NVARCHAR (MAX)  NULL,
    [ExchangeSOPackagingSlipFilePath] NVARCHAR (MAX)  NULL,
    [ExchangeSOShippingLabelFilePath] NVARCHAR (MAX)  NULL,
    [ExchangeAggreementFilePath]      NVARCHAR (MAX)  NULL,
    [ExchangeQuotePrintFilePath]      NVARCHAR (MAX)  NULL,
    [SpeedQuotePrintPath]             NVARCHAR (MAX)  NULL,
    [UseS3]                           BIT             NULL,
    [S3BucketAccessUrl]               NVARCHAR (250)  NULL,
    [SiteLogo]                        NVARCHAR (250)  NULL,
    [ATA106]                          NVARCHAR (MAX)  NULL,
    [S3BucketUrl]                     NVARCHAR (250)  NULL,
    [WOInspectionChecklistPrint]      NVARCHAR (MAX)  NULL,
    [IronPDFLicenceKey]               NVARCHAR (MAX)  NULL,
    [ReceivingInspection]             NVARCHAR (MAX)  NULL,
    [WorkOrderExcelFile]              NVARCHAR (250)  NULL,
    [NonStockLabelPrintPDFPath]       NVARCHAR (MAX)  NULL,
    [AssetLabelPrintPDFPath]          NVARCHAR (MAX)  NULL,
    [CustomerStatementPDFPath]        NVARCHAR (MAX)  NULL,
    [CustomerPaymentPrintFilePath]    NVARCHAR (MAX)  NULL,
    [DownloadFiles]                   NVARCHAR (250)  NULL,
    [CompanyLogos]                    NVARCHAR (250)  NULL,
    [SignatureLogoPath]               NVARCHAR (MAX)  NULL,
    [CustomerRMAPDFPath]              NVARCHAR (MAX)  NULL,
    [CreditMemoPDFPrint]              NVARCHAR (MAX)  NULL,
    [BatchDetaiilsPrintFilePath]      NVARCHAR (MAX)  NULL,
    [ScrapCertificateFilePath]        NVARCHAR (MAX)  NULL,
    [FedexUrl]                        NVARCHAR (250)  NULL,
    [FedexAPIKey]                     NVARCHAR (250)  NULL,
    [FedexSecretKey]                  NVARCHAR (250)  NULL,
    [FedexShippingLocation]           NVARCHAR (250)  NULL,
    [FedexShippingAccount]            NVARCHAR (250)  NULL,
    [IsFedexStaticData]               BIT             NULL,
    [ReportUrl]                       NVARCHAR (250)  NULL,
    [ReportUser]                      NVARCHAR (100)  NULL,
    [ReportPass]                      NVARCHAR (100)  NULL,
    [ReportEnv]                       NVARCHAR (100)  NULL,
    [IsFedexImplement]                BIT             NULL,
    [ReportDomain]                    NVARCHAR (100)  NULL,
    [BaseReportingUrl]                NVARCHAR (100)  NULL,
    [ReportTokenKey]                  NVARCHAR (250)  NULL,
    [ReportTokenValidMinutes]         NVARCHAR (100)  NULL,
    [ParamsReportingUrl]              NVARCHAR (250)  NULL,
    [MaxReceivedMessageSize]          VARCHAR (150)   NULL,
    [AccountingIntegrationAPIUrl]     VARCHAR (1000)  NULL,
    [DBS3BucketName]                  VARCHAR (100)   NULL,
    CONSTRAINT [PK_AppSettings] PRIMARY KEY CLUSTERED ([AppSettingsId] ASC)
);







