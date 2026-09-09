/*************************************************************           
 ** File:   [FleetQuoteSettings.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Configuration Settings
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteSettings] (
    [FleetQuoteSettingId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTypeId]         BIGINT        NOT NULL,
    [Prefix]                  VARCHAR (10)  NOT NULL,
    [Sufix]                   VARCHAR (10)  NULL,
    [StartCode]               BIGINT        NOT NULL,
    [ValidDays]               INT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_FleetQuoteSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_FleetQuoteSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_FleetQuoteSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_FleetQuoteSettings_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CurrentNumber]           BIGINT        CONSTRAINT [DF_FleetQuoteSettings_CurrentNumber] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]          BIT           NULL,
    [EffectiveDate]           DATETIME      NULL,
    [TearDownTypes]           VARCHAR (50)  NULL,
    [IsFlatRate]              BIT           NULL,
    [IsPrintCorrectiveAction] BIT           NULL,
    CONSTRAINT [PK_FleetQuoteSettings] PRIMARY KEY CLUSTERED ([FleetQuoteSettingId] ASC),
    CONSTRAINT [FK_FleetQuoteSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteSettings_WorkOrderTypeId] FOREIGN KEY ([WorkOrderTypeId]) REFERENCES [dbo].[WorkOrderType] ([Id])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteSettingsAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteSettingsAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteSettingsAudit]
   ON [dbo].[FleetQuoteSettings]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteSettingsAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
