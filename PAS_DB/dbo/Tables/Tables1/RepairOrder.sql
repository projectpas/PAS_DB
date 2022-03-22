CREATE TABLE [dbo].[RepairOrder] (
    [RepairOrderId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderNumber]      VARCHAR (50)    NULL,
    [OpenDate]               DATETIME2 (7)   NOT NULL,
    [ClosedDate]             DATETIME2 (7)   NULL,
    [NeedByDate]             DATETIME2 (7)   NOT NULL,
    [PriorityId]             BIGINT          NOT NULL,
    [Priority]               VARCHAR (100)   NULL,
    [VendorId]               BIGINT          NOT NULL,
    [VendorName]             VARCHAR (100)   NULL,
    [VendorCode]             VARCHAR (100)   NULL,
    [VendorContactId]        BIGINT          NOT NULL,
    [VendorContact]          VARCHAR (100)   NULL,
    [VendorContactPhone]     VARCHAR (100)   NULL,
    [CreditTermsId]          INT             NULL,
    [Terms]                  VARCHAR (100)   NULL,
    [CreditLimit]            DECIMAL (18, 2) NULL,
    [RequisitionerId]        BIGINT          NOT NULL,
    [Requisitioner]          VARCHAR (100)   NULL,
    [StatusId]               BIGINT          NOT NULL,
    [Status]                 VARCHAR (100)   NULL,
    [StatusChangeDate]       DATETIME2 (7)   NULL,
    [Resale]                 BIT             NULL,
    [DeferredReceiver]       BIT             NULL,
    [RoMemo]                 NVARCHAR (MAX)  NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [ApproverId]             BIGINT          NULL,
    [ApprovedBy]             VARCHAR (100)   NULL,
    [ApprovedDate]           DATETIME2 (7)   NULL,
    [ManagementStructureId]  BIGINT          NOT NULL,
    [Level1]                 VARCHAR (200)   NULL,
    [Level2]                 VARCHAR (200)   NULL,
    [Level3]                 VARCHAR (200)   NULL,
    [Level4]                 VARCHAR (200)   NULL,
    [MasterCompanyId]        INT             CONSTRAINT [DF__RepairOrd__Maste__70429E0D] DEFAULT ((1)) NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NULL,
    [IsActive]               BIT             CONSTRAINT [RepairOrder_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF__RepairOrd__IsDel__7FD5EEA5] DEFAULT ((0)) NOT NULL,
    [IsEnforce]              BIT             NULL,
    [PDFPath]                NVARCHAR (100)  NULL,
    [VendorRFQRepairOrderId] BIGINT          NULL,
    CONSTRAINT [PK_RepairOrder] PRIMARY KEY CLUSTERED ([RepairOrderId] ASC),
    CONSTRAINT [FK_RepairOrder_ApproverId] FOREIGN KEY ([ApproverId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_RepairOrder_CreditTermsId] FOREIGN KEY ([CreditTermsId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_RepairOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RepairOrder_PriorityId] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_RepairOrder_RequisitionerId] FOREIGN KEY ([RequisitionerId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_RepairOrder_ROStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[ROStatus] ([ROStatusId]),
    CONSTRAINT [FK_RepairOrder_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId]),
    CONSTRAINT [FK_RepairOrder_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_RepairOrderAudit]

   ON  [dbo].[RepairOrder]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO RepairOrderAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END