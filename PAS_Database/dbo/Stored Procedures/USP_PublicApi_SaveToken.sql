
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
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

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

    BEGIN TRY
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
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            ROLLBACK TRAN;
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_SaveToken'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter3 = ''' + CAST(ISNULL(@ClientId, '') AS VARCHAR(100))
                                                   + '@Parameter4 = ''' + CAST(ISNULL(@TokenId, '') AS VARCHAR(100))
                                                   + '@Parameter5 = ''' + CAST(ISNULL(@IssuedDate, '') AS VARCHAR(100))
                                                   + '@Parameter6 = ''' + CAST(ISNULL(@ExpiryDate, '') AS VARCHAR(100))
                                                   + '@Parameter7 = ''' + CAST(ISNULL(@IpAddress, '') AS VARCHAR(100))
                                                   + '@Parameter8 = ''' + CAST(ISNULL(@UserAgent, '') AS VARCHAR(100))
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