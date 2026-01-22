CREATE TABLE [dbo].[ManagementStructure] (
    [ManagementStructureId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Code]                  VARCHAR (30)   NOT NULL,
    [Name]                  VARCHAR (256)  NOT NULL,
    [Description]           VARCHAR (200)  NULL,
    [ParentId]              BIGINT         NULL,
    [IsLastChild]           BIT            NULL,
    [TagName]               VARCHAR (100)  NULL,
    [LegalEntityId]         BIGINT         NOT NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ManagementStructure_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ManagementStructure_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [ManagementStructure_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [ManagementStructure_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Ids]                   VARCHAR (2000) NULL,
    [Names]                 VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_ManagementStructure] PRIMARY KEY CLUSTERED ([ManagementStructureId] ASC),
    CONSTRAINT [FK_ManagementStructure_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_ManagementStructure_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ManagementStructure_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [UC_ManagementStructureCode] UNIQUE NONCLUSTERED ([Code] ASC, [ParentId] ASC, [MasterCompanyId] ASC)
);


GO


CREATE Trigger [dbo].[trg_ManagementStructure]

on [dbo].[ManagementStructure] 

 AFTER INSERT,UPDATE,Delete 

As  

Begin  



SET NOCOUNT ON





INSERT INTO [dbo].[ManagementStructureAudit]

           ([ManagementStructureId]

           ,[Code]

           ,[Name]

           ,[Description]

           ,[ParentId]

           ,[IsLastChild]

           ,[TagName]

           ,[LegalEntityId]

           ,[MasterCompanyId]

           ,[CreatedBy]

           ,[UpdatedBy]

           ,[CreatedDate]

           ,[UpdatedDate]

           ,[IsActive]

           ,[IsDeleted]

           ,[Ids]

           ,[Names])

		   SELECT * from dbo.ManagementStructure With (NOLOCK)

End