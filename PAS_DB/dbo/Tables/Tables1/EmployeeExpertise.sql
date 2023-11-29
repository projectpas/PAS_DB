CREATE TABLE [dbo].[EmployeeExpertise] (
    [EmployeeExpertiseId]     SMALLINT        IDENTITY (1, 1) NOT NULL,
    [Description]             VARCHAR (30)    NOT NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [EmployeeExpertise_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [EmployeeExpertise_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [EmployeeExpertise_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [EmployeeExpertise_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsWorksInShop]           BIT             CONSTRAINT [EmployeeExpertise_DC_IsWorksInShop] DEFAULT ((0)) NOT NULL,
    [EmpExpCode]              VARCHAR (50)    NULL,
    [Avglaborrate]            DECIMAL (18, 2) CONSTRAINT [DF_EmployeeExpertise_Avglaborrate] DEFAULT ((0)) NOT NULL,
    [Overheadburden]          DECIMAL (18, 2) CONSTRAINT [DF_EmployeeExpertise_Overheadburden] DEFAULT ((0)) NOT NULL,
    [OverheadburdenPercentId] BIGINT          NULL,
    [FlatAmount]              DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_EmployeeExpertise] PRIMARY KEY CLUSTERED ([EmployeeExpertiseId] ASC),
    CONSTRAINT [FK_EmployeeExpertise_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_EmployeeExpertiser_PercentId] FOREIGN KEY ([OverheadburdenPercentId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [Unique_EmployeeExpertise] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);




GO


CREATE TRIGGER [dbo].[Trg_EmployeeExpertiseAudit] ON [dbo].[EmployeeExpertise]

   AFTER INSERT,UPDATE,DELETE

AS   

BEGIN  



UPDATE EmployeeExpertise SET Overheadburden = ISNULL((Select PercentValue from [Percent] WHERE ex.OverheadburdenPercentId = [Percent].PercentId),0) 

FROM [dbo].[EmployeeExpertise] ex 

JOIN INSERTED ins ON ex.EmployeeExpertiseId = ins.EmployeeExpertiseId



 INSERT INTO [dbo].[EmployeeExpertiseAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END