CREATE TABLE [dbo].[CRM] (
    [CRMId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]      BIGINT          NOT NULL,
    [ReportId]        BIGINT          NULL,
    [YTDRevenueTY]    DECIMAL (18, 2) NULL,
    [YTDRevenueLY]    DECIMAL (18, 2) NULL,
    [CreditLimit]     DECIMAL (18, 2) NULL,
    [CreditTermsId]   INT             NULL,
    [DSO]             VARCHAR (256)   NULL,
    [Warnings]        VARCHAR (256)   NULL,
    [MasterCompanyId] INT             CONSTRAINT [CRM_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]       VARCHAR (256)   CONSTRAINT [CRM_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]       VARCHAR (256)   CONSTRAINT [CRM_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [CRM_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [CRM_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [CRM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [CRM_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CRM] PRIMARY KEY CLUSTERED ([CRMId] ASC),
    CONSTRAINT [FK_CRM_CreditTerms] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_CRM_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CRM_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CRM_Report] FOREIGN KEY ([ReportId]) REFERENCES [dbo].[Report] ([ReportId])
);


GO


CREATE TRIGGER [dbo].[Trg_CRMAudit]

   ON  [dbo].[CRM]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO CRMAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END