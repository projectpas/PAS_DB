CREATE TABLE [dbo].[CustomerClassification] (
    [CustomerClassificationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]              NVARCHAR (500) NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_CustomerClassification_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_CustomerClassification_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [CustomerClassification_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [CustomerClassification_DC_Delete] DEFAULT ((0)) NOT NULL,
    [SequenceNo]               INT            NULL,
    CONSTRAINT [PK_CustomerClassification] PRIMARY KEY CLUSTERED ([CustomerClassificationId] ASC),
    CONSTRAINT [FK_CustomerClassification_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerClassificationAudit]

   ON  [dbo].[CustomerClassification]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerClassificationAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END