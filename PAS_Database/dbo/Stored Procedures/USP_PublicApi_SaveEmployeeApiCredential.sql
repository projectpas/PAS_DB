
/*************************************************************
 ** File:   [USP_PublicApi_SaveEmployeeApiCredential]
 ** Author: Moin Bloch
 ** Description: 5.2 Create or regenerate credentials. Bumping CredentialVersion revokes every token issued
 **                  before. Returns no row when the employee is not an active employee of @MasterCompanyId.
 ** Purpose: PAS Employee screen - Public API popup (Generate / Regenerate)
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_SaveEmployeeApiCredential] @EmployeeId = 2, @MasterCompanyId = 1, @ClientId = 'pas_1_af6cc51954e814c2fc9426d6e667f913', @ClientSecretHash = 'PBKDF2-SHA256$100000$...', @UpdatedBy = 'ADMIN User'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_SaveEmployeeApiCredential]
    @EmployeeId       BIGINT,
    @MasterCompanyId  INT,
    @ClientId         VARCHAR(100),
    @ClientSecretHash VARCHAR(256),
    @UpdatedBy        VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Employee] WITH (NOLOCK)
                   WHERE [EmployeeId] = @EmployeeId AND [MasterCompanyId] = @MasterCompanyId
                     AND [IsActive] = 1 AND [IsDeleted] = 0)
        RETURN;

    IF EXISTS (SELECT 1 FROM [dbo].[EmployeeApiCredential] WHERE [EmployeeId] = @EmployeeId)
    BEGIN
        UPDATE [dbo].[EmployeeApiCredential]
        SET [ClientId]           = @ClientId,
            [ClientSecretHash]   = @ClientSecretHash,
            [IsApiAccessEnabled] = 1,
            [CredentialVersion]  = [CredentialVersion] + 1,
            [SecretRotatedDate]  = GETUTCDATE(),
            [UpdatedBy]          = @UpdatedBy,
            [UpdatedDate]        = GETUTCDATE()
        WHERE [EmployeeId] = @EmployeeId;
    END
    ELSE
    BEGIN
        INSERT INTO [dbo].[EmployeeApiCredential]
            ([EmployeeId], [MasterCompanyId], [ClientId], [ClientSecretHash], [IsApiAccessEnabled], [CreatedBy], [UpdatedBy])
        VALUES
            (@EmployeeId, @MasterCompanyId, @ClientId, @ClientSecretHash, 1, @UpdatedBy, @UpdatedBy);
    END

    UPDATE [dbo].[EmployeeApiToken]
    SET [IsRevoked] = 1, [RevokedDate] = GETUTCDATE(), [RevokedReason] = 'CredentialsRegenerated', [ExpiryDate] = GETUTCDATE()
    WHERE [EmployeeId] = @EmployeeId AND [IsRevoked] = 0 AND [ExpiryDate] > GETUTCDATE();

    SELECT [EmployeeId], [ClientId]
    FROM [dbo].[EmployeeApiCredential] WITH (NOLOCK)
    WHERE [EmployeeId] = @EmployeeId;
END