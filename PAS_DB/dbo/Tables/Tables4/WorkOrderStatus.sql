CREATE TABLE [dbo].[WorkOrderStatus] (
    [Id]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [WorkOrderStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [WorkOrderStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_WorkOrderStatus_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_WorkOrderStatus_Delete] DEFAULT ((0)) NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [StatusCode]      NVARCHAR (50)  NULL,
    CONSTRAINT [PK_WorkOrderStatus] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [Unique_WorkOrderStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_WorkOrderStatusAudit]

   ON  [dbo].[WorkOrderStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO WorkOrderStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END