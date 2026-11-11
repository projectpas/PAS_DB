
/*************************************************************
 ** File:   [USP_PublicApi_SetEmployeeApiAccess]
 ** Author: Moin Bloch
 ** Description: 5.3 Enable / disable API access. Bumping CredentialVersion also revokes outstanding tokens,
 **                  so re-enabling never revives a token issued before the disable.
 ** Purpose: PAS Employee screen - Public API popup (Is API Access Enabled)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_SetEmployeeApiAccess] @EmployeeId = 2, @MasterCompanyId = 1, @IsApiAccessEnabled = 1, @UpdatedBy = 'ADMIN User'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_SetEmployeeApiAccess]
    @EmployeeId         BIGINT,
    @MasterCompanyId    INT,
    @IsApiAccessEnabled BIT,
    @UpdatedBy          VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[EmployeeApiCredential]
    SET [IsApiAccessEnabled] = @IsApiAccessEnabled,
        [CredentialVersion]  = [CredentialVersion] + 1,
        [UpdatedBy]          = @UpdatedBy,
        [UpdatedDate]        = GETUTCDATE()
    WHERE [EmployeeId] = @EmployeeId
      AND [MasterCompanyId] = @MasterCompanyId;

    DECLARE @RowsAffected INT = @@ROWCOUNT;

    IF @RowsAffected > 0
    BEGIN
        UPDATE [dbo].[EmployeeApiToken]
        SET [IsRevoked] = 1, [RevokedDate] = GETUTCDATE(),
            [RevokedReason] = CASE WHEN @IsApiAccessEnabled = 1 THEN 'AccessReEnabled' ELSE 'AccessDisabled' END,
            [ExpiryDate] = GETUTCDATE()
        WHERE [EmployeeId] = @EmployeeId AND [IsRevoked] = 0 AND [ExpiryDate] > GETUTCDATE();
    END

    SELECT @RowsAffected AS [RowsAffected];
END