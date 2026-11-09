
/*=========================================================================================
  5. STORED PROCEDURES - PAS EMPLOYEE SCREEN (CREDENTIAL MANAGEMENT)
=========================================================================================*/

---------------------------------------------------------------------------------------------
-- 5.1 Credential details for the Employee screen popup. Never returns the secret hash.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetEmployeeApiCredential]
    @EmployeeId      BIGINT,
    @MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [EmployeeId], [ClientId], [IsApiAccessEnabled], [SecretRotatedDate], [UpdatedBy], [UpdatedDate]
    FROM [dbo].[EmployeeApiCredential] WITH (NOLOCK)
    WHERE [EmployeeId] = @EmployeeId
      AND [MasterCompanyId] = @MasterCompanyId;
END