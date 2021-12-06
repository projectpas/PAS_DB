CREATE TABLE [dbo].[Action] (
    [ActionId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (200)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Action_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Action_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Action_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Action_IsDelete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Action] PRIMARY KEY CLUSTERED ([ActionId] ASC),
    CONSTRAINT [FK_Action_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_Action_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ActionAudit] ON [dbo].[Action]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[ActionAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END