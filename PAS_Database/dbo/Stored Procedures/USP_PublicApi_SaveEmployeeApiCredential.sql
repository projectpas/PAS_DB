
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
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

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

    BEGIN TRY
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
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_SaveEmployeeApiCredential'
              -- @ClientSecretHash is never logged
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@ClientId, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@UpdatedBy, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END