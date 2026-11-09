
---------------------------------------------------------------------------------------------
-- 5.2 Create or regenerate credentials. Bumping CredentialVersion revokes every token issued
--     before. Returns no row when the employee is not an active employee of @MasterCompanyId.
---------------------------------------------------------------------------------------------
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