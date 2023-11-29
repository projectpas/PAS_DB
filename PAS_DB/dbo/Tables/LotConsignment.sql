CREATE TABLE [dbo].[LotConsignment] (
    [ConsignmentId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [ConsignmentNumber]  VARCHAR (100)   NULL,
    [ConsigneeName]      VARCHAR (256)   NULL,
    [MasterCompanyId]    INT             NULL,
    [CreatedBy]          VARCHAR (256)   NOT NULL,
    [UpdatedBy]          VARCHAR (256)   NULL,
    [CreatedDate]        DATETIME2 (7)   NOT NULL,
    [UpdatedDate]        DATETIME2 (7)   NULL,
    [IsActive]           BIT             NULL,
    [IsDeleted]          BIT             NULL,
    [ConsignmentName]    NVARCHAR (MAX)  NULL,
    [LotId]              BIGINT          NULL,
    [IsRevenue]          BIT             NULL,
    [IsMargin]           BIT             NULL,
    [IsFixedAmount]      BIT             NULL,
    [PercentId]          BIGINT          NULL,
    [PerAmount]          DECIMAL (18, 2) NULL,
    [ConsigneeTypeId]    INT             NULL,
    [ConsigneeId]        BIGINT          NULL,
    [IsRevenueSplit]     BIT             NULL,
    [ConsignorPercentId] BIGINT          NULL,
    CONSTRAINT [PK_LotConsignment] PRIMARY KEY CLUSTERED ([ConsignmentId] ASC)
);




GO
CREATE   TRIGGER [dbo].[Trg_LotConsignment]

   ON  [dbo].[LotConsignment]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO LotConsignmentAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END