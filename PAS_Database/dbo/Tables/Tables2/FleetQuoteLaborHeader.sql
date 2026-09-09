/*************************************************************           
 ** File:   [FleetQuoteLaborHeader.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Labor Header Info
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteLaborHeader] (
    [FleetQuoteLaborHeaderId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId]     BIGINT        NOT NULL,
    [DataEnteredBy]           BIGINT        NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_FleetQuoteLaborHeader_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_FleetQuoteLaborHeader_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_FleetQuoteLaborHeader_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_FleetQuoteLaborHeader_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MarkupFixedPrice]        VARCHAR (15)  NULL,
    [HeaderMarkupId]          BIGINT        NULL,
    CONSTRAINT [PK_FleetQuoteLaborHeader] PRIMARY KEY CLUSTERED ([FleetQuoteLaborHeaderId] ASC),
    CONSTRAINT [FK_FleetQuoteLaborHeader_DataEnteredBy] FOREIGN KEY ([DataEnteredBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_FleetQuoteLaborHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteLaborHeader_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteLaborHeaderAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteLaborHeaderAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteLaborHeaderAudit]
   ON [dbo].[FleetQuoteLaborHeader]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteLaborHeaderAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
