﻿CREATE TABLE [dbo].[CRMDealAudit] (
    [AuditCRMDealId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [CRMDealId]            BIGINT          NOT NULL,
    [PrimarySalesPersonId] BIGINT          NULL,
    [DealNumber]           VARCHAR (30)    NOT NULL,
    [DealName]             VARCHAR (50)    NOT NULL,
    [DealOwnerId]          BIGINT          NULL,
    [DealSource]           VARCHAR (50)    NULL,
    [OpenDate]             DATETIME2 (7)   NOT NULL,
    [ClosingDate]          DATETIME2 (7)   NULL,
    [ExpectedRevenue]      DECIMAL (18, 2) NULL,
    [Competitors]          VARCHAR (256)   NULL,
    [Probability]          NUMERIC (18)    NULL,
    [IsDealOutComeWon]     BIT             NOT NULL,
    [OutCome]              DECIMAL (18, 2) NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NOT NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    [DealStageId]          BIGINT          NOT NULL,
    [DealLossReasonId]     BIGINT          NULL,
    [CustomerId]           BIGINT          NULL,
    CONSTRAINT [PK_CRMDealAudit] PRIMARY KEY CLUSTERED ([AuditCRMDealId] ASC)
);

