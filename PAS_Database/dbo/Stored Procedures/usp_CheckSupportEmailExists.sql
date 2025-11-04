/*************************************************************           
 ** File:   [usp_CheckSupportEmailExists]           
 ** Author:   Devendra Shekh
 ** Description: This SP is used To Check if the Given Mail Exists to Support Mail
 ** Purpose:         
 ** Date:   30-Oct-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    30-Oct-2025		Devendra Shekh		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[usp_CheckSupportEmailExists]
@MessageId		NVARCHAR(255) = NULL,
@Subject		VARCHAR(500),
@FromEmail		NVARCHAR(320),
@IsNewEmail		BIT OUTPUT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON  
	BEGIN TRY  
		
		SET @IsNewEmail = 1;

		IF EXISTS(SELECT 1 FROM [dbo].[SupportEmail] WITH(NOLOCK) WHERE [MessageId] = @MessageId)
		BEGIN
			SET @IsNewEmail = 0;
		END

	END TRY
	BEGIN CATCH	
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_CheckSupportEmailExists'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MessageId, '') as varchar(255))
			+ '@Parameter2 = ''' + CAST(ISNULL(@Subject, '') as varchar(255)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@IsNewEmail, '') as varchar(100)) 
		,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END