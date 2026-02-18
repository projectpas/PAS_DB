CREATE TABLE [dbo].[WIPGLAccountSetup] (
    [WIPGLAccountId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [WIPCategoryId]   BIGINT        NULL,
    [GLAccountId]     BIGINT        NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL,
    [MasterCompanyId] INT           NULL,
    PRIMARY KEY CLUSTERED ([WIPGLAccountId] ASC)
);


GO
/****** Object:  Trigger [dbo].[Trg_WIPGLAccountSetupAudit]]   Script Date: 27-01-2026 ******/
CREATE   TRIGGER [dbo].[Trg_WIPGLAccountSetupAudit] ON [dbo].[WIPGLAccountSetup]

   AFTER INSERT,UPDATE  

AS   

BEGIN  

 INSERT INTO [dbo].[WIPGLAccountSetupAudit]  
 SELECT * FROM INSERTED  
 SET NOCOUNT ON;  

END