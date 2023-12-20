CREATE TABLE [dbo].[AircraftType] (
    [AircraftTypeId]  INT            IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF__AircraftT__Creat__4580C68C] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_AircraftType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_AircraftType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_AircraftType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_Table_1] PRIMARY KEY CLUSTERED ([AircraftTypeId] ASC),
    CONSTRAINT [FK_AircraftType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AircraftType] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_AircraftType]

   ON  [dbo].[AircraftType]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO AircraftTypeAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END