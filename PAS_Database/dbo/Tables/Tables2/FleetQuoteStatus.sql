/*************************************************************
 ** File:   [FleetQuoteStatus.sql]
 ** Author:   Kishor Makwana
 ** Description: This Table is used to store the status lookup values for Fleet Quote (mirrors WorkOrderQuoteStatus)
 ** Date:   09/10/2026
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    09/10/2026   Kishor Makwana	Created [PN-17698]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteStatus] (
    [FleetQuoteStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]        VARCHAR (50)   NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_FleetQuoteStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_FleetQuoteStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_FleetQuoteStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_FleetQuoteStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FleetQuoteStatus] PRIMARY KEY CLUSTERED ([FleetQuoteStatusId] ASC)
);

GO

/*************************************************************
 ** File:   [Trg_FleetQuoteStatusAudit]
 ** Author:   Kishor Makwana
 ** Description: This Trigger is used to insert data into FleetQuoteStatusAudit
 ** Date:   09/10/2026
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    09/10/2026   Kishor Makwana	Created [PN-17698]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteStatusAudit]
   ON [dbo].[FleetQuoteStatus]
   AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteStatusAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
