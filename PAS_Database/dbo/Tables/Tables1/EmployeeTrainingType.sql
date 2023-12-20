CREATE TABLE [dbo].[EmployeeTrainingType] (
    [EmployeeTrainingTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]            VARCHAR (MAX)  NULL,
    [TrainingType]           VARCHAR (256)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [EmployeeTrainingType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [EmployeeTrainingType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_EmployeeTrainingType] PRIMARY KEY CLUSTERED ([EmployeeTrainingTypeId] ASC),
    CONSTRAINT [FK_EmployeeTrainingType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_EmployeeTrainingType] UNIQUE NONCLUSTERED ([TrainingType] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_EmployeeTrainingTypeAudit] ON [dbo].[EmployeeTrainingType]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[EmployeeTrainingTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END