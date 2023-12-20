CREATE TABLE [dbo].[VendorClassification] (
    [VendorClassificationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ClassificationName]     VARCHAR (256)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [VendorClassification_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [VendorClassification_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [VendorClassification_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [VendorClassification_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorClassification] PRIMARY KEY CLUSTERED ([VendorClassificationId] ASC),
    CONSTRAINT [FK_VendorClassification_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_VendorClassification] UNIQUE NONCLUSTERED ([ClassificationName] ASC, [MasterCompanyId] ASC)
);


GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_VendorClassificationAudit]

   ON  [dbo].[VendorClassification]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO VendorClassificationAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END