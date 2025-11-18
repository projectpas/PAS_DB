CREATE TABLE [dbo].[AspNetUsers] (
    [Id]                        NVARCHAR (450)     NOT NULL,
    [AccessFailedCount]         INT                NOT NULL,
    [ConcurrencyStamp]          NVARCHAR (MAX)     NULL,
    [Configuration]             NVARCHAR (MAX)     NULL,
    [CreatedBy]                 NVARCHAR (MAX)     NULL,
    [CreatedDate]               DATETIME2 (7)      CONSTRAINT [DF_AspNetUsers_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [Email]                     NVARCHAR (256)     NULL,
    [EmailConfirmed]            BIT                NOT NULL,
    [FullName]                  NVARCHAR (MAX)     NULL,
    [IsEnabled]                 BIT                NOT NULL,
    [JobTitle]                  NVARCHAR (MAX)     NULL,
    [LockoutEnabled]            BIT                NOT NULL,
    [LockoutEnd]                DATETIMEOFFSET (7) NULL,
    [NormalizedEmail]           NVARCHAR (256)     NULL,
    [NormalizedUserName]        NVARCHAR (256)     NULL,
    [PasswordHash]              NVARCHAR (MAX)     NULL,
    [PhoneNumber]               NVARCHAR (MAX)     NULL,
    [PhoneNumberConfirmed]      BIT                NOT NULL,
    [SecurityStamp]             NVARCHAR (MAX)     NULL,
    [TwoFactorEnabled]          BIT                NOT NULL,
    [UpdatedBy]                 NVARCHAR (MAX)     NULL,
    [UpdatedDate]               DATETIME2 (7)      CONSTRAINT [DF_AspNetUsers_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UserName]                  NVARCHAR (256)     NULL,
    [EmployeeId]                BIGINT             NULL,
    [IsResetPassword]           BIT                NULL,
    [MasterCompanyId]           INT                NULL,
    [CountryPhoneCodeCountryId] BIGINT             CONSTRAINT [DF_AspNetUsers_CountryPhoneCodeCountryId] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_AspNetUsers] PRIMARY KEY CLUSTERED ([Id] ASC)
);






GO
CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex]
    ON [dbo].[AspNetUsers]([NormalizedUserName] ASC) WHERE ([NormalizedUserName] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [EmailIndex]
    ON [dbo].[AspNetUsers]([NormalizedEmail] ASC);


GO
--drop  trigger TR_AspNetUsers_To_MainDB
CREATE   TRIGGER [dbo].[TR_AspNetUsers_To_MainDB]
ON [dbo].[AspNetUsers]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

		-------------------------------------------
        -- 1. INSERT new users into PAS_UAT (Master)
        -------------------------------------------
        INSERT INTO MTI.dbo.AspNetUsers
        (
            Id,
			ConcurrencyStamp,
			UserName,
			NormalizedUserName,
			Email,
			NormalizedEmail,
			EmailConfirmed,
			PhoneNumberConfirmed,
			TwoFactorEnabled,
			LockoutEnabled,
			AccessFailedCount,
			EmployeeId,
			FullName,
			IsEnabled,
			MasterCompanyId,
			SecurityStamp,
			PasswordHash,
			CreatedDate,
			UpdatedDate
        )
        SELECT
            i.Id,
			i.ConcurrencyStamp,
			i.UserName,
			i.NormalizedUserName,
			i.Email,
			i.NormalizedEmail,
			i.EmailConfirmed,
			i.PhoneNumberConfirmed,
			i.TwoFactorEnabled,
			i.LockoutEnabled,
			i.AccessFailedCount,
			i.EmployeeId,
			i.FullName,
			i.IsEnabled,
			i.MasterCompanyId,
			i.SecurityStamp,
			i.PasswordHash,
			i.CreatedDate,
			i.UpdatedDate
        FROM inserted i
        WHERE NOT EXISTS (
				SELECT 1 
				FROM MTI.dbo.AspNetUsers u
				WHERE u.EmployeeId = i.EmployeeId 
				  AND u.MasterCompanyId = i.MasterCompanyId
		);

		-------------------------------------------
        -- 2. UPDATE existing users in PAS_UAT (Master)
        -------------------------------------------
        UPDATE u
        SET 
            u.ConcurrencyStamp    = i.ConcurrencyStamp,
            u.UserName            = i.UserName,
            u.NormalizedUserName  = i.NormalizedUserName,
            u.Email               = i.Email,
            u.NormalizedEmail     = i.NormalizedEmail,
            u.EmailConfirmed      = i.EmailConfirmed,
            u.PhoneNumberConfirmed= i.PhoneNumberConfirmed,
            u.TwoFactorEnabled    = i.TwoFactorEnabled,
            u.LockoutEnabled      = i.LockoutEnabled,
            u.AccessFailedCount   = i.AccessFailedCount,
            u.EmployeeId          = i.EmployeeId,
            u.FullName            = i.FullName,
            u.IsEnabled           = i.IsEnabled,
            u.MasterCompanyId     = i.MasterCompanyId,
            u.SecurityStamp       = i.SecurityStamp,
            u.PasswordHash        = i.PasswordHash,
            u.CreatedDate         = i.CreatedDate,
            u.UpdatedDate         = i.UpdatedDate
        FROM MTI.dbo.AspNetUsers u
        INNER JOIN inserted i ON u.Id = i.Id;

    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(MAX) = ERROR_MESSAGE();

    END CATCH
END