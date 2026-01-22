CREATE TABLE [dbo].[CycleCount] (
    [CycleCountId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [CycleCountNumber]      VARCHAR (50)   NOT NULL,
    [EntryDate]             DATETIME2 (7)  NOT NULL,
    [EntryTime]             TIME (7)       NOT NULL,
    [StatusId]              INT            NOT NULL,
    [ManagementStructureId] BIGINT         NOT NULL,
    [IsEnforce]             BIT            NULL,
    [RequestedById]         BIGINT         NULL,
    [ApproverId]            BIGINT         NULL,
    [ApprovedBy]            VARCHAR (100)  NULL,
    [DateApproved]          DATETIME2 (7)  NULL,
    [PostedDate]            DATETIME2 (7)  NULL,
    [BatchName]             VARCHAR (50)   NULL,
    [CountedById]           BIGINT         NULL,
    [CountMethodId]         INT            NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_CycleCount_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_CycleCount_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_CycleCount_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_CycleCount_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]               NVARCHAR (200) NULL,
    [IsQtyCounted]          INT            NULL,
    [IsQtyVariance]         INT            NULL,
    [IsUnitCoctAdj]         INT            NULL,
    CONSTRAINT [PK_CycleCount] PRIMARY KEY CLUSTERED ([CycleCountId] ASC),
    CONSTRAINT [FK_CycleCount_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
/*************************************************************             
 ** File:  Trg_CycleCountAudit      
 ** Author:   Moin Bloch
 ** Description: Trigger For Audit Table
 ** Purpose:           
 ** Date:   07/11/2024         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    07/11/2024   Moin Bloch    Created
**************************************************************/
CREATE   TRIGGER [dbo].[Trg_CycleCountAudit] ON [dbo].[CycleCount]
AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[CycleCountAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END