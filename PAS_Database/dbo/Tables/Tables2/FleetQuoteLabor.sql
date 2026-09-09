/*************************************************************           
 ** File:   [FleetQuoteLabor.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Labor Entries
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteLabor] (
    [FleetQuoteLaborId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteLaborHeaderId] BIGINT          NOT NULL,
    [ExpertiseId]             SMALLINT        NOT NULL,
    [Hours]                   DECIMAL (10, 2) NOT NULL,
    [BillableId]              INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteLabor_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteLabor_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_FleetQuoteLabor_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_FleetQuoteLabor_IsDeleted] DEFAULT ((0)) NOT NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [DirectLaborOHCost]       DECIMAL (18, 6) NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [BurdenRateAmount]        DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteLabor_BurdenRateAmount] DEFAULT ((0)) NULL,
    [TotalCostPerHour]        DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteLabor_TotalCostPerHour] DEFAULT ((0)) NULL,
    [TotalCost]               DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteLabor_TotalCost] DEFAULT ((0)) NULL,
    [BillingRate]             DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteLabor_BillingRate] DEFAULT ((0)) NULL,
    [BillingAmount]           DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteLabor_BillingAmount] DEFAULT ((0)) NULL,
    [BurdaenRatePercentageId] BIGINT          NULL,
    [BillingMethodId]         INT             NULL,
    [MasterCompanyId]         INT             NULL,
    [TaskName]                VARCHAR (100)   NULL,
    [Expertise]               VARCHAR (50)    NULL,
    [Billabletype]            VARCHAR (50)    NULL,
    [BurdaenRatePercentage]   VARCHAR (50)    NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    [EmployeeId]              BIGINT          NULL,
    CONSTRAINT [PK_FleetQuoteLabor] PRIMARY KEY CLUSTERED ([FleetQuoteLaborId] ASC),
    CONSTRAINT [FK_FleetQuoteLabor_BurdaenRatePercentage] FOREIGN KEY ([BurdaenRatePercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_FleetQuoteLabor_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_FleetQuoteLabor_Expertise] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_FleetQuoteLabor_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_FleetQuoteLabor_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteLabor_FleetQuoteLaborHeader] FOREIGN KEY ([FleetQuoteLaborHeaderId]) REFERENCES [dbo].[FleetQuoteLaborHeader] ([FleetQuoteLaborHeaderId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteLaborAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteLaborAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteLaborAudit]
   ON [dbo].[FleetQuoteLabor]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteLaborAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
