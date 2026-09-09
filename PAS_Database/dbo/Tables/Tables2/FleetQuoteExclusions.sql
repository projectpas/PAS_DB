/*************************************************************           
 ** File:   [FleetQuoteExclusions.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Exclusions
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteExclusions] (
    [FleetQuoteExclusionsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId]    BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NULL,
    [ExstimtPercentOccuranceId]  INT             NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [Quantity]                   DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteExclusions_Quantity] DEFAULT ((0)) NULL,
    [UnitCost]                   DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteExclusions_UnitCost] DEFAULT ((0)) NULL,
    [ExtendedCost]               DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteExclusions_ExtendedCost] DEFAULT ((0)) NULL,
    [MarkUpPercentageId]         BIGINT          NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteExclusions_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteExclusions_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [DF_FleetQuoteExclusions_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF_FleetQuoteExclusions_IsDeleted] DEFAULT ((0)) NOT NULL,
    [TaskId]                     BIGINT          NULL,
    [MarkupFixedPrice]           VARCHAR (15)    NULL,
    [HeaderMarkupId]             BIGINT          NULL,
    [BillingMethodId]            INT             NULL,
    [BillingRate]                DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteExclusions_BillingRate] DEFAULT ((0)) NULL,
    [BillingAmount]              DECIMAL (18, 6) CONSTRAINT [DF_FleetQuoteExclusions_BillingAmount] DEFAULT ((0)) NULL,
    [ConditionId]                BIGINT          NULL,
    CONSTRAINT [PK_FleetQuoteExclusions] PRIMARY KEY CLUSTERED ([FleetQuoteExclusionsId] ASC),
    CONSTRAINT [FK_FleetQuoteExclusions_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_FleetQuoteExclusions_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_FleetQuoteExclusions_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteExclusions_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteExclusionsAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteExclusionsAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteExclusionsAudit]
   ON [dbo].[FleetQuoteExclusions]
   AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteExclusionsAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
