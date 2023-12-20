CREATE TABLE [dbo].[CommunicationText] (
    [CommunicationTextId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Mobile]              VARCHAR (20)   NOT NULL,
    [ContactById]         BIGINT         NOT NULL,
    [Notes]               NVARCHAR (MAX) NULL,
    [ModuleId]            INT            NOT NULL,
    [ReferenceId]         BIGINT         NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_CommunicationText_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_CommunicationText_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [CommunicationText_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [CommunicationText_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CustomerContactId]   BIGINT         DEFAULT ((0)) NOT NULL,
    [WorkOrderPartNo]     BIGINT         NULL,
    CONSTRAINT [PK_CommunicationText] PRIMARY KEY CLUSTERED ([CommunicationTextId] ASC),
    CONSTRAINT [FK_CommunicationText_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CommunicationText_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId])
);


GO


CREATE TRIGGER [dbo].[Trg_CommunicationTextAudit]

   ON  [dbo].[CommunicationText]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CommunicationTextAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END