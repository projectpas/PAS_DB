/*************************************************************           
 ** File:   [usp_GetUOMConversion]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used get the UOMConversion Data
 ** Purpose:         
 ** Date:  21-Nov-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    21-Nov-2025		Devendra Shekh		Created

EXEC [dbo].[usp_GetUOMConversion]
**************************************************************/
CREATE     PROCEDURE [dbo].[usp_GetUOMConversion]
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		
		SELECT 
			[UOMConversionId],
			[FromUOM],
			[ToUOM],
			[Factor],
			[IsMultiply],
			[DecimalPlaces]
		FROM [dbo].[UOMConversion] WITH(NOLOCK)
			
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments			VARCHAR(150)    = 'usp_GetUOMConversion'
		,@ProcedureParameters	VARCHAR(3000)	= ''
		,@ApplicationName		VARCHAR(100)	= 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1); 
	END CATCH
END