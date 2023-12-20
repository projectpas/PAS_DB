CREATE TABLE [dbo].[ShippingContainer] (
    [ShippingContainerId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]         VARCHAR (50)   NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ShippingContainers_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_ShippingContainers_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [DF_ShippingContainers_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_ShippingContainers_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ShippingContainers] PRIMARY KEY CLUSTERED ([ShippingContainerId] ASC)
);


GO






---------------------------------------------------------------------------------------------------------------------------



CREATE TRIGGER [dbo].[Trg_ShippingContainerAudit]

   ON  [dbo].[ShippingContainer]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO [dbo].[ShippingContainerAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END