CREATE TABLE [dbo].[Evidence] (
    [EvidenceId]      INT           IDENTITY (1, 1) NOT NULL,
    [EvidenceName]    VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Evidence_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Evidence_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Evidence_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Evidence_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Evidence] PRIMARY KEY CLUSTERED ([EvidenceId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_EvidenceAudit] ON [dbo].[Evidence]
   AFTER INSERT,DELETE,UPDATE  
AS   
BEGIN    

	INSERT INTO [dbo].[EvidenceAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;  	  

END