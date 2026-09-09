/*************************************************************           
 ** File:   [FleetQuoteMaterial.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Material Items
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteMaterial] (
    [FleetQuoteMaterialId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId]  BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [ConditionCodeId]          BIGINT          NOT NULL,
    [ItemClassificationId]     BIGINT          NOT NULL,
    [Quantity]                 DECIMAL (18, 6) NULL,
    [UnitOfMeasureId]          BIGINT          NOT NULL,
    [UnitCost]                 DECIMAL (18, 6) NULL,
    [ExtendedCost]             DECIMAL (18, 6) NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [IsDefered]                BIT             NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteMaterial_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteMaterial_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_FleetQuoteMaterial_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_FleetQuoteMaterial_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [TaskId]                   BIGINT          NOT NULL,
    [MarkupFixedPrice]         VARCHAR (15)    NULL,
    [BillingAmount]            DECIMAL (18, 6) NULL,
    [BillingRate]              DECIMAL (18, 6) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [ProvisionId]              INT             NOT NULL,
    [MaterialMandatoriesId]    INT             CONSTRAINT [DF_FleetQuoteMaterial_Mandatories] DEFAULT ((0)) NULL,
    [BillingMethodId]          INT             NULL,
    [TaskName]                 VARCHAR (100)   NULL,
    [PartNumber]               VARCHAR (50)    NULL,
    [PartDescription]          VARCHAR (500)   NULL,
    [Provision]                VARCHAR (50)    NULL,
    [UomName]                  VARCHAR (100)   NULL,
    [Conditiontype]            VARCHAR (50)    NULL,
    [Stocktype]                VARCHAR (50)    NULL,
    [BillingName]              VARCHAR (50)    NULL,
    [MarkUp]                   VARCHAR (50)    NULL,
    [IsFromWorkFlow]           BIT             CONSTRAINT [DF_FleetQuoteMaterial_IsFromWorkFlow] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_FleetQuoteMaterial] PRIMARY KEY CLUSTERED ([FleetQuoteMaterialId] ASC),
    CONSTRAINT [FK_FleetQuoteMaterial_Condition] FOREIGN KEY ([ConditionCodeId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_FleetQuoteMaterial_ItemClassification] FOREIGN KEY ([ItemClassificationId]) REFERENCES [dbo].[ItemClassification] ([ItemClassificationId]),
    CONSTRAINT [FK_FleetQuoteMaterial_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_FleetQuoteMaterial_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_FleetQuoteMaterial_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteMaterial_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_FleetQuoteMaterial_UnitOfMeasure] FOREIGN KEY ([UnitOfMeasureId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_FleetQuoteMaterial_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteMaterialAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteMaterialAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteMaterialAudit]
   ON [dbo].[FleetQuoteMaterial]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteMaterialAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
