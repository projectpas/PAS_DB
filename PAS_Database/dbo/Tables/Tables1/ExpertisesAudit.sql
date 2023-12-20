CREATE TABLE [dbo].[ExpertisesAudit] (
    [ExpertisesAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                INT           NOT NULL,
    [CreatedBy]         VARCHAR (50)  NULL,
    [CreatedDate]       DATETIME      NOT NULL,
    [UpdatedBy]         VARCHAR (50)  NULL,
    [UpdatedDate]       DATETIME      NULL,
    [IsDeleted]         BIT           NULL,
    [ExpertiseType]     VARCHAR (256) NULL,
    [EstimatedHours]    VARCHAR (256) NULL,
    [LabourDirectRate]  VARCHAR (256) NULL,
    [LabourDirectCost]  VARCHAR (256) NULL,
    [OHeadBurden]       VARCHAR (256) NULL,
    [OHCost]            VARCHAR (256) NULL,
    [LabourAndOHCost]   VARCHAR (256) NULL,
    [ActionId]          BIGINT        NOT NULL,
    [WorkFlowId]        BIGINT        NOT NULL,
    CONSTRAINT [PK_ExpertisesAudit] PRIMARY KEY CLUSTERED ([ExpertisesAuditId] ASC)
);

