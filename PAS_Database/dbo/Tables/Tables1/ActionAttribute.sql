CREATE TABLE [dbo].[ActionAttribute] (
    [ActionAttributeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]       VARCHAR (100)  NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_ActionAttribute_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_ActionAttribute_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_ActionAttribute_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_ActionAttribute_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Sequence]          BIGINT         NOT NULL,
    CONSTRAINT [PK_ActionAttribute] PRIMARY KEY CLUSTERED ([ActionAttributeId] ASC),
    CONSTRAINT [FK_ActionAttribute_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_ActionAttribute_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ActionAttributeAudit] ON [dbo].[ActionAttribute]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[ActionAttributeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END