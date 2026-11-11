
/*************************************************************
 ** File:   [USP_PublicApi_SaveToken]
 ** Author: Moin Bloch
 ** Description: 2.2 Save a newly issued token and expire the employee's previous active tokens.
 **                  The UPDLOCK on the credential row serializes parallel token requests of the same employee.
 ** Purpose: PAS_PUBLIC_API - POST /api/v1/auth/token
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_SaveToken] @EmployeeId = 2, @MasterCompanyId = 1, @ClientId = 'pas_1_af6cc51954e814c2fc9426d6e667f913', @TokenId = '0b6c1d2e3f4a5b6c7d8e9f0a1b2c3d4e', @IssuedDate = '2026-11-09 10:00', @ExpiryDate = '2026-11-09 11:00', @IpAddress = '', @UserAgent = ''
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_SaveToken]
    @EmployeeId      BIGINT,
    @MasterCompanyId INT,
    @ClientId        VARCHAR(100),
    @TokenId         VARCHAR(50),
    @IssuedDate      DATETIME2(7),
    @ExpiryDate      DATETIME2(7),
    @IpAddress       VARCHAR(50),
    @UserAgent       NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    DECLARE @Lock INT;
    SELECT @Lock = 1 FROM [dbo].[EmployeeApiCredential] WITH (UPDLOCK, HOLDLOCK) WHERE [EmployeeId] = @EmployeeId;

    UPDATE [dbo].[EmployeeApiToken]
    SET [IsRevoked] = 1, [RevokedDate] = GETUTCDATE(), [RevokedReason] = 'Regenerated', [ExpiryDate] = GETUTCDATE()
    WHERE [EmployeeId] = @EmployeeId AND [IsRevoked] = 0 AND [ExpiryDate] > GETUTCDATE();

    INSERT INTO [dbo].[EmployeeApiToken]
        ([EmployeeId], [MasterCompanyId], [ClientId], [TokenId], [IssuedDate], [ExpiryDate], [IpAddress], [UserAgent])
    VALUES
        (@EmployeeId, @MasterCompanyId, @ClientId, @TokenId, @IssuedDate, @ExpiryDate, @IpAddress, @UserAgent);

    COMMIT TRANSACTION;
END