CREATE TABLE [dbo].[EmployeeExpertiseMapping] (
    [EmployeeExpertiseMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                 BIGINT        NOT NULL,
    [EmployeeExpertiseIds]       INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_EmployeeExpertiseMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_EmployeeExpertiseMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_EmployeeExpertiseMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_EmployeeExpertiseMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeExpertiseMapping] PRIMARY KEY CLUSTERED ([EmployeeExpertiseMappingId] ASC),
    CONSTRAINT [FK_EmployeeExpertiseMapping_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeExpertiseMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE TRIGGER [dbo].[Trg_EmployeeExpertiseMappingAudit]
   ON  [dbo].[EmployeeExpertiseMapping]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[EmployeeExpertiseMappingAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END