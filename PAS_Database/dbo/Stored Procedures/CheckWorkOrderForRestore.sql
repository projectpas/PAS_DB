/*************************************************************               
 ** File:   [CheckWorkOrderForRestore]               
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to check work order before restoring
 ** Purpose:             
 ** Date:   08/22/2025
 ** PARAMETERS:               
 ** RETURN VALUE:             
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------			--------------------------------               
	1    08/22/2025   Vishal Suthar		Created
	2    11/25/2026   Vishal Suthar		Blank serial number is not a duplicate, check all part lines, return a single result

-- EXEC [dbo].[CheckWorkOrderForRestore] 4724
**************************************************************/ 
CREATE   PROCEDURE [dbo].[CheckWorkOrderForRestore]
	@ReferenceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON   
	BEGIN TRY
		
	DECLARE @ClosedWorkOrderStatusId BIGINT;

	SELECT @ClosedWorkOrderStatusId = Id FROM DBO.WorkOrderStatus WITH (NOLOCK) WHERE StatusCode = 'CLOSED';

	-- Revised SN is checked when it has a value, otherwise Current SN. A blank serial number is never a duplicate.
	IF EXISTS (SELECT 1
			   FROM DBO.WorkOrderPartNumber CUR WITH (NOLOCK)
			   INNER JOIN DBO.WorkOrderPartNumber WOP WITH (NOLOCK) ON WOP.MasterCompanyId = CUR.MasterCompanyId
					AND WOP.WorkOrderId <> CUR.WorkOrderId AND WOP.IsDeleted = 0 AND WOP.WorkOrderStatusId <> @ClosedWorkOrderStatusId
			   WHERE CUR.WorkOrderId = @ReferenceId
				 AND ((NULLIF(LTRIM(RTRIM(CUR.RevisedSerialNumber)), '') IS NOT NULL
						AND UPPER(LTRIM(RTRIM(WOP.RevisedSerialNumber))) = UPPER(LTRIM(RTRIM(CUR.RevisedSerialNumber))))
				   OR (NULLIF(LTRIM(RTRIM(CUR.RevisedSerialNumber)), '') IS NULL
						AND NULLIF(LTRIM(RTRIM(CUR.CurrentSerialNumber)), '') IS NOT NULL
						AND UPPER(LTRIM(RTRIM(WOP.CurrentSerialNumber))) = UPPER(LTRIM(RTRIM(CUR.CurrentSerialNumber))))))
	BEGIN
		SELECT 1 AS ReferenceId; -- Duplicate found
	END
	ELSE
	BEGIN
		SELECT 0 AS ReferenceId; -- No duplicates found
	END

	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0
		PRINT 'ROLLBACK'
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	  , @AdhocComments     VARCHAR(150)    = 'CheckWorkOrderForRestore' 
	  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100)) 
	  , @ApplicationName VARCHAR(100) = 'PAS'
	-----------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	  exec spLogException 
			   @DatabaseName           = @DatabaseName
			 , @AdhocComments          = @AdhocComments
			 , @ProcedureParameters    = @ProcedureParameters
			 , @ApplicationName        =  @ApplicationName
			 , @ErrorLogID             = @ErrorLogID OUTPUT ;
	  RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
	  RETURN(1);
	END CATCH
END