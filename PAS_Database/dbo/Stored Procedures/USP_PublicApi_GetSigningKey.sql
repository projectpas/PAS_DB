
/*=========================================================================================
  6. STORED PROCEDURES - PAS_PUBLIC_API APPLICATION SETTINGS
=========================================================================================*/

---------------------------------------------------------------------------------------------
-- 6.1 Signing key for the configured SettingEnvironment. Only this column is returned,
--     never the whole AppSettings row.
---------------------------------------------------------------------------------------------
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetSigningKey]
    @SettingEnvironment VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (1) [PublicApiSigningKey]
    FROM [dbo].[AppSettings] WITH (NOLOCK)
    WHERE [SettingEnvironment] = @SettingEnvironment;
END