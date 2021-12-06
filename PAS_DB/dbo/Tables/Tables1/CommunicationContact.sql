CREATE TABLE [dbo].[CommunicationContact] (
    [ContactId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [ContactNo]       VARCHAR (20)   NOT NULL,
    [ContactTypeId]   INT            NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [ContactById]     BIGINT         NOT NULL,
    [ContactDate]     DATETIME2 (7)  NOT NULL,
    [ModuleId]        INT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CommunicationContact_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [CommunicationContact_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CommunicationContact] PRIMARY KEY CLUSTERED ([ContactId] ASC),
    CONSTRAINT [FK_CommunicationContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_CommunicationContactAudit]

   ON  [dbo].[CommunicationContact]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CommunicationContactAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END