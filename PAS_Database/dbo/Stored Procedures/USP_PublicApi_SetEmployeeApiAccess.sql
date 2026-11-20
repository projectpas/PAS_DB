
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
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

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

    BEGIN TRY
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
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_SetEmployeeApiAccess'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@IsApiAccessEnabled, '') AS VARCHAR(100))
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