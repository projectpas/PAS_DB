CREATE TABLE [dbo].[ScrapReason] (
    [Id]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Reason]          VARCHAR (1000) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ScrapReason_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ScrapReason_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ScrapReason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ScrapReason_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ScrapReason] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ScrapReason_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_ScrapReason] UNIQUE NONCLUSTERED ([Reason] ASC, [MasterCompanyId] ASC)
);


GO
CREATE   TRIGGER [dbo].[Trg_ScrapreasonAudit] ON [dbo].Scrapreason

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[ScrapreasonAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END