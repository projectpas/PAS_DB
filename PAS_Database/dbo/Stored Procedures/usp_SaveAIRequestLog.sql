/*************************************************************           
 ** File:   [usp_SaveAIRequestLog]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used save OpenAI Request Logs
 ** Purpose:         
 ** Date:   11 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    11 Aug 2025	Devendra Shekh		Created

************************************************************************/
CREATE   PROCEDURE dbo.[usp_SaveAIRequestLog]
	@IntegrationEmailID BIGINT NULL,
    @RequestType NVARCHAR(50),
    @RequestUrl NVARCHAR(500),
    @RequestBody NVARCHAR(MAX) = NULL,
    @ResponseStatusCode VARCHAR(20) = NULL,
    @ResponseBody NVARCHAR(MAX) = NULL,
    @IsSuccess BIT
AS
BEGIN
    SET NOCOUNT ON;

	IF EXISTS(SELECT 1 FROM dbo.[OpenAIRequestLog] WITH (NOLOCK))
	BEGIN
		DELETE FROM dbo.[OpenAIRequestLog] WHERE LogId NOT IN (SELECT TOP 200 LogId FROM dbo.[OpenAIRequestLog] WITH (NOLOCK) ORDER BY LogId DESC)
	END

    INSERT INTO dbo.[OpenAIRequestLog] (IntegrationEmailID, RequestType, RequestUrl, RequestBody, ResponseStatusCode, ResponseBody, IsSuccess, CreatedDate)
    VALUES (@IntegrationEmailID, @RequestType, @RequestUrl, @RequestBody, @ResponseStatusCode, @ResponseBody, @IsSuccess, GETUTCDATE());
END;