CREATE TABLE [dbo].[AllShipVia] (
    [AllShipViaId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReferenceId]       BIGINT          NOT NULL,
    [ModuleId]          BIGINT          NOT NULL,
    [UserType]          INT             NOT NULL,
    [ShipViaId]         BIGINT          NOT NULL,
    [ShippingCost]      DECIMAL (20, 3) NOT NULL,
    [HandlingCost]      DECIMAL (20, 3) NOT NULL,
    [IsModuleShipVia]   BIT             NULL,
    [ShippingAccountNo] VARCHAR (100)   NULL,
    [ShipVia]           VARCHAR (100)   NULL,
    [ShippingViaId]     BIGINT          NULL,
    [MasterCompanyId]   INT             NOT NULL,
    [CreatedBy]         VARCHAR (256)   NOT NULL,
    [UpdatedBy]         VARCHAR (256)   NOT NULL,
    [CreatedDate]       DATETIME2 (7)   CONSTRAINT [DF_AllShipVia_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)   CONSTRAINT [DF_AllShipVia_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT             CONSTRAINT [DF_AllShipVia_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT             CONSTRAINT [DF_AllShipVia_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AllShipVia] PRIMARY KEY CLUSTERED ([AllShipViaId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_AllShipViaAudit]

   ON  [dbo].[AllShipVia]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO AllShipViaAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;

END