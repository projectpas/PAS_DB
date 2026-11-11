CREATE TYPE [dbo].[POSubComponentTimeCycle] AS TABLE (
	[PurchaseOrderPartRecordId] BIGINT          NULL,
	[SubItemMasterId]           BIGINT          NULL,
	[ConditionId]               BIGINT          NULL,
	[TSNHrs]                    DECIMAL (18, 6) NULL,
	[TSNMin]                    DECIMAL (18, 6) NULL,
	[CSN]                       DECIMAL (18, 6) NULL,
	[TSOHrs]                    DECIMAL (18, 6) NULL,
	[TSOMin]                    DECIMAL (18, 6) NULL,
	[CSO]                       DECIMAL (18, 6) NULL);
