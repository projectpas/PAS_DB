﻿CREATE TABLE [dbo].[RepairOrderApprovalAudit] (
    [RepairOrderApprovalAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderApprovalId]      BIGINT         NOT NULL,
    [RepairOrderId]              BIGINT         NOT NULL,
    [RepairOrderPartId]          BIGINT         NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [SentDate]                   DATETIME2 (7)  NULL,
    [ApprovedDate]               DATETIME2 (7)  NULL,
    [ApprovedById]               BIGINT         NULL,
    [RejectedDate]               DATETIME2 (7)  NULL,
    [RejectedBy]                 BIGINT         NULL,
    [StatusId]                   INT            NULL,
    [ActionId]                   INT            NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [DF_RepairOrderApprovalAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [DF_RepairOrderApprovalAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [DF_RepairOrderApprovalAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [DF_RepairOrderApprovalAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ApprovedByName]             VARCHAR (256)  NULL,
    [RejectedByName]             VARCHAR (256)  NULL,
    [StatusName]                 VARCHAR (50)   NULL,
    [InternalSentToId]           BIGINT         NULL,
    [InternalSentToName]         VARCHAR (100)  NULL,
    [InternalSentById]           BIGINT         NULL,
    CONSTRAINT [PK_RepairOrderApprovalAudit] PRIMARY KEY CLUSTERED ([RepairOrderApprovalAuditId] ASC)
);

