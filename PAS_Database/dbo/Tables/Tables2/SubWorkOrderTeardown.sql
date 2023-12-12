CREATE TABLE [dbo].[SubWorkOrderTeardown] (
    [SubWorkOrderTeardownId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderId]          BIGINT        NOT NULL,
    [WorkOrderId]             BIGINT        NOT NULL,
    [SubWOPartNoId]           BIGINT        NOT NULL,
    [IsAdditionalComments]    BIT           NULL,
    [IsBulletinsModification] BIT           NULL,
    [IsDiscovery]             BIT           NULL,
    [IsFinalInspection]       BIT           NULL,
    [IsFinalTest]             BIT           NULL,
    [IsPmaDerBulletins]       BIT           NULL,
    [IsPreAssemblyInspection] BIT           NULL,
    [IsPreAssmentResults]     BIT           NULL,
    [IsPreliinaryReview]      BIT           NULL,
    [IsRemovalReasons]        BIT           NULL,
    [IsTestDataUsed]          BIT           NULL,
    [IsWorkPerformed]         BIT           NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NULL,
    [UpdatedBy]               VARCHAR (256) NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderTeardown_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderTeardown_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderTeardowns] PRIMARY KEY CLUSTERED ([SubWorkOrderTeardownId] ASC),
    CONSTRAINT [FK_SubWorkOrderTeardown_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderTeardown_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderTeardown_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderTeardown_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderTeardownAudit]

   ON  [dbo].[SubWorkOrderTeardown]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderTeardownAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END