
---------------------------------------------------------------------------------------------
-- 2.2 Save a newly issued token and expire the employee's previous active tokens.
--     The UPDLOCK on the credential row serializes parallel token requests of the same employee.
---------------------------------------------------------------------------------------------
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