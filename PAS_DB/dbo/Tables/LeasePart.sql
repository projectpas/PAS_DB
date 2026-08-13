CREATE TABLE [dbo].[LeasePart] (
    [LeasePartId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [LeaseHeaderId]     BIGINT         NOT NULL,
    [ItemMasterId]      BIGINT         NOT NULL,
    [PN]                NVARCHAR (100) NULL,
    [PNDescription]     NVARCHAR (500) NULL,
    [UOM]               NVARCHAR (50)  NULL,
    [QtyRequested]      INT            NOT NULL,
    [QtyOrder]          INT            NOT NULL,
    [QtyReserved]       INT            NOT NULL,
    [ConditionId]       BIGINT         NOT NULL,
    [OEMPMA]            NVARCHAR (100) NULL,
    [AircraftSectionId] BIGINT         NULL,
    [StartDate]         DATE           NULL,
    [EndDate]           DATE           NULL,
    [POId]              BIGINT         NULL,
    [PONumber]          VARCHAR (256)  NULL,
    [StatusId]          INT            NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_LeasePart_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_LeasePart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         BIGINT         NULL,
    [CreatedDate]       DATETIME       CONSTRAINT [DF_LeasePart_CreatedDate] DEFAULT (sysdatetime()) NULL,
    [UpdatedBy]         BIGINT         NULL,
    [UpdatedDate]       DATETIME       CONSTRAINT [DF_LeasePart_UpdatedDate] DEFAULT (sysdatetime()) NULL,
    CONSTRAINT [PK_LeasePart] PRIMARY KEY CLUSTERED ([LeasePartId] ASC),
    CONSTRAINT [FK_LeasePart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO

CREATE TRIGGER [dbo].[Trg_LeasePartAudit]

   ON  [dbo].[LeasePart]

   AFTER INSERT,UPDATE

AS

BEGIN

	INSERT INTO [dbo].[LeasePartAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END