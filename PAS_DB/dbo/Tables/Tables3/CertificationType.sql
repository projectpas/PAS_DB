CREATE TABLE [dbo].[CertificationType] (
    [CertificationTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CertificationName]   VARCHAR (256) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedDate]         DATETIME      CONSTRAINT [CertificationType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME      CONSTRAINT [CertificationType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [CertificationType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [CertificationType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__Certific__D1A09641A5FBF39B] PRIMARY KEY CLUSTERED ([CertificationTypeId] ASC),
    CONSTRAINT [FK_CertificationType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CertificationType] UNIQUE NONCLUSTERED ([CertificationName] ASC, [MasterCompanyId] ASC)
);


GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_CertificationType]

   ON  [dbo].[CertificationType]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	 



	INSERT INTO CertificationTypeAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END