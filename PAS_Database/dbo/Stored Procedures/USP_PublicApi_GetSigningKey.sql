
/*=========================================================================================
  6. STORED PROCEDURES - PAS_PUBLIC_API APPLICATION SETTINGS
=========================================================================================*/

/*************************************************************
 ** File:   [USP_PublicApi_GetSigningKey]
 ** Author: Moin Bloch
 ** Description: 6.1 Signing key for the configured SettingEnvironment. Only this column is returned,
 **                  never the whole AppSettings row.
 ** Purpose: PAS_PUBLIC_API - JWT signing key at startup
 ** Date:   09/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetSigningKey] @SettingEnvironment = 'UAT'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSigningKey]
    @SettingEnvironment VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1) [PublicApiSigningKey]
    FROM [dbo].[AppSettings] WITH (NOLOCK)
    WHERE [SettingEnvironment] = @SettingEnvironment;
END