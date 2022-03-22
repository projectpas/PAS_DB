CREATE TABLE [dbo].[ItemClassification] (
    [ItemClassificationId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemClassificationCode] VARCHAR (30)   NOT NULL,
    [Description]            VARCHAR (100)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MastercompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [ItemClassification_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [ItemClassification_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    [ItemTypeId]             INT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemClassification] PRIMARY KEY CLUSTERED ([ItemClassificationId] ASC),
    CONSTRAINT [FK_ItemClassification_MasterCompany] FOREIGN KEY ([MastercompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ItemClassification] UNIQUE NONCLUSTERED ([Description] ASC, [MastercompanyId] ASC),
    CONSTRAINT [Unique_ItemClassificationCode] UNIQUE NONCLUSTERED ([ItemClassificationCode] ASC, [MastercompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ItemClassficationAudit]

   ON  [dbo].[ItemClassification]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



DECLARE @ItemTypeId INT

DECLARE @ItemType VARCHAR(20)



SELECT @ItemTypeId=ItemTypeId FROM INSERTED



SELECT @ItemType=Name FROM ItemType WHERE ItemTypeId=@ItemTypeId





INSERT INTO ItemClassificationAudit

SELECT *,@ItemType FROM INSERTED

SET NOCOUNT ON;

END