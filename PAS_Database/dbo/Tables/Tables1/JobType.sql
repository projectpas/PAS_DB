CREATE TABLE [dbo].[JobType] (
    [JobTypeId]       SMALLINT       IDENTITY (1, 1) NOT NULL,
    [JobTypeName]     VARCHAR (30)   NOT NULL,
    [JobTypeMemo]     NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_JobType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_JobType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_JobType] PRIMARY KEY CLUSTERED ([JobTypeId] ASC),
    CONSTRAINT [FK_JobType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_JobType] UNIQUE NONCLUSTERED ([JobTypeName] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_JobTypeAudit] ON [dbo].[JobType]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[JobTypeAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END