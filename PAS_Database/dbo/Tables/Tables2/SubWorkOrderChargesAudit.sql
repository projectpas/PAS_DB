CREATE TABLE [dbo].[SubWorkOrderChargesAudit] (
    [SubWorkOrderChargesAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderChargesId]      BIGINT          NOT NULL,
    [WorkOrderId]                BIGINT          NOT NULL,
    [SubWorkOrderId]             BIGINT          NOT NULL,
    [SubWOPartNoId]              BIGINT          NOT NULL,
    [ChargesTypeId]              BIGINT          NOT NULL,
    [VendorId]                   BIGINT          NULL,
    [Quantity]                   INT             NOT NULL,
    [TaskId]                     BIGINT          NOT NULL,
    [Description]                VARCHAR (256)   NULL,
    [UnitCost]                   DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]               DECIMAL (20, 2) NULL,
    [IsFromWorkFlow]             BIT             NULL,
    [ReferenceNo]                VARCHAR (20)    NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NOT NULL,
    [IsActive]                   BIT             NOT NULL,
    [IsDeleted]                  BIT             NOT NULL,
    [UOMId]                      BIGINT          NULL,
    CONSTRAINT [PK_SubWorkOrderChargesAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderChargesAuditId] ASC)
);



