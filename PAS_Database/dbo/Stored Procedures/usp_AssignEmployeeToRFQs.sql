/*************************************************************           
 ** File:   [usp_AssignEmployeeToRFQs]           
 ** Author:  Devendra Shekh
 ** Description: This stored procedure is used to assign employee to selected RFQs
 ** Purpose:         
 ** Date:   04 Aug 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    04 Aug 2025	Devendra Shekh		Created
     
-- EXEC USP_SendOneFourtyFiveQuote
************************************************************************/
CREATE   PROCEDURE [dbo].[usp_AssignEmployeeToRFQs]
	@EmployeeId BIGINT = NULL,
	@CustomerRfqIds VARCHAR(MAX) = NULL
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		UPDATE CRQ
		SET
			CRQ.EmployeeId = @EmployeeId
		FROM [dbo].[CustomerRfq] CRQ WITH(NOLOCK)
		WHERE CRQ.CustomerRfqId IN (SELECT value FROM STRING_SPLIT(@CustomerRfqIds, ','));
	END			
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		, @AdhocComments     VARCHAR(150)    = 'usp_AssignEmployeeToRFQs' 
		, @ProcedureParameters VARCHAR(3000) = '@EmployeeId = ''' + CAST(ISNULL(@EmployeeId, '') as varchar(100))
		, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END