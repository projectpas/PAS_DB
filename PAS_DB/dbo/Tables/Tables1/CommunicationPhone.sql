CREATE TABLE [dbo].[CommunicationPhone] (
    [CommunicationPhoneId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PhoneNo]              VARCHAR (50)   NOT NULL,
    [ContactById]          BIGINT         NOT NULL,
    [Notes]                NVARCHAR (MAX) NULL,
    [ModuleId]             INT            NOT NULL,
    [ReferenceId]          BIGINT         NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [DF_CommunicationPhone_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [DF_CommunicationPhone_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [CommunicationPhone_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [CommunicationPhone_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CustomerContactId]    BIGINT         NOT NULL,
    [WorkOrderPartNo]      BIGINT         NULL,
    [PhoneType]            INT            CONSTRAINT [DF_CommunicationPhone_PhoneType] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_CommunicationPhone] PRIMARY KEY CLUSTERED ([CommunicationPhoneId] ASC),
    CONSTRAINT [FK_CommunicationPhone_ContactBy] FOREIGN KEY ([ContactById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CommunicationPhone_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CommunicationPhone_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId])
);


GO




CREATE TRIGGER [dbo].[Trg_CommunicationPhoneAudit]

   ON  [dbo].[CommunicationPhone]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CommunicationPhoneAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END