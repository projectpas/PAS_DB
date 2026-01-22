CREATE TABLE [dbo].[SupportAssignmentMaster] (
    [SupportAssignmentMasterId] INT            IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                BIGINT         NOT NULL,
    [EmployeeEmail]             NVARCHAR (200) NULL,
    [CC]                        NVARCHAR (320) NULL,
    [BCC]                       NVARCHAR (320) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  CONSTRAINT [DF_SupportAssignmentMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  CONSTRAINT [DF_SupportAssignmentMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [DF_SupportAssignmentMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [DF_SupportAssignmentMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SupportAssignmentMaster] PRIMARY KEY CLUSTERED ([SupportAssignmentMasterId] ASC)
);

