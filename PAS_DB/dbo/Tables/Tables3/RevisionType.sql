CREATE TABLE [dbo].[RevisionType] (
    [RevisionTypeId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [RevisionTypeName] VARCHAR (256)  NOT NULL,
    [Description]      VARCHAR (256)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_RevisionType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_RevisionType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RevisionType] PRIMARY KEY CLUSTERED ([RevisionTypeId] ASC),
    CONSTRAINT [FK_RevisionType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_RevisionType] UNIQUE NONCLUSTERED ([RevisionTypeName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_RevisionTypeAudit] ON

[dbo].[RevisionType]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[RevisionTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END