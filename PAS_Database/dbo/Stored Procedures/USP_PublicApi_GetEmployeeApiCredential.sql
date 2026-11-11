
/*=========================================================================================
  5. STORED PROCEDURES - PAS EMPLOYEE SCREEN (CREDENTIAL MANAGEMENT)
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_GetEmployeeApiCredential]
 ** Author: Moin Bloch
 ** Description: 5.1 Credential details for the Employee screen popup. Never returns the secret hash.
 ** Purpose: PAS Employee screen - Public API popup
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetEmployeeApiCredential] @EmployeeId = 2, @MasterCompanyId = 1
************************************************************************/
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