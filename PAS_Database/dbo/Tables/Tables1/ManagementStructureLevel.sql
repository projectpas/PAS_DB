CREATE TABLE [dbo].[ManagementStructureLevel] (
    [ID]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Code]            VARCHAR (20)   NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [TypeID]          INT            NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureLevel_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ManagmentStructureLevel_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_ManagmentStructureLevel_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_ManagmentStructureLevel_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LegalEntityId]   BIGINT         NULL,
    CONSTRAINT [PK_ManagmentStructureLevel] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [FK_ManagmentStructureLevel_LegalEntityId] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId])
);


GO

CREATE TRIGGER [dbo].[Trg_ManagementStructureLevelAudit] ON [dbo].[ManagementStructureLevel]

   AFTER INSERT,UPDATE  

AS   

BEGIN  

	DECLARE @TypeId BIGINT 

	DECLARE @TypeName VARCHAR(256)

	SELECT  @TypeId=TypeID FROM INSERTED

	SELECT @TypeName=Description FROM ManagementStructureType WHERE TypeID=@TypeId

 INSERT INTO [dbo].[ManagementStructureLevelAudit]  
 ([ID], [Code], [Description], [TypeID], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [TypeName], [LegalEntityId])

 SELECT [ID], [Code], [Description], [TypeID], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], @TypeName, [LegalEntityId] FROM INSERTED  

 SET NOCOUNT ON;  

END