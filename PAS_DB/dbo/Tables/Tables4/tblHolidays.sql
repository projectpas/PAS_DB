CREATE TABLE [dbo].[tblHolidays] (
    [Id]              BIGINT       IDENTITY (1, 1) NOT NULL,
    [HolidayDate]     DATETIME     NULL,
    [CreatedDate]     DATETIME     NULL,
    [CreatedBy]       VARCHAR (50) NULL,
    [UpdatedDate]     DATETIME     NULL,
    [UpdatedBy]       VARCHAR (50) NULL,
    [IsActive]        BIT          NULL,
    [IsDeleted]       BIT          NULL,
    [MasterCompanyId] BIGINT       NULL
);

