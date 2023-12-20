CREATE TABLE [dbo].[WorkOrderProvision] (
    [WorkOrderProvisionId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [ProvisionDescription] VARCHAR (30)  NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderProvision_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_WorkOrderProvision_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_WorkOrderProvision_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_WorkOrderProvision_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderProvision] PRIMARY KEY CLUSTERED ([WorkOrderProvisionId] ASC),
    CONSTRAINT [FK_WorkOrderProvision_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderProvisionAudit]

   ON  [dbo].[WorkOrderProvision]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderProvisionAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END