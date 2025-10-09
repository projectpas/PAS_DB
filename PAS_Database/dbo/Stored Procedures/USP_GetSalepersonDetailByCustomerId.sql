/***************************************************************  
 ** File:   [USP_GetSalepersonDetailByCustomerId]             
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to get salesperson revenue and margin percentage
 ** Date:   10/09/2025
            
  ** Change History             
 *************************************************************************
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------  
	1    10/09/2025   Vishal Suthar		Created

 EXEC USP_GetSalepersonDetailByCustomerId 74, 2
 ************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetSalepersonDetailByCustomerId]
	@CustomerId BIGINT,
	@ActivityTypeId BIGINT
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   

	BEGIN TRY

	SELECT 
	CASE WHEN @ActivityTypeId = 1 THEN PSP.EmployeeId
		 WHEN @ActivityTypeId = 2 THEN SSP.EmployeeId
		 WHEN @ActivityTypeId = 3 THEN AGENT.EmployeeId
		 WHEN @ActivityTypeId = 4 THEN CRS.EmployeeId
		 END AS EmployeeId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.MRORevenuePercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.MRORevenuePercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.MRORevenuePercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.MRORevenuePercentageId
		 END AS MRORevenuePercentageId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.BrokeringRevenuePercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.BrokeringRevenuePercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.BrokeringRevenuePercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.BrokeringRevenuePercentageId
		 END AS BrokeringRevenuePercentageId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.ManufacturingRevenuePercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.ManufacturingRevenuePercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.ManufacturingRevenuePercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.ManufacturingRevenuePercentageId
		 END AS ManufacturingRevenuePercentageId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.MROMarginPercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.MROMarginPercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.MROMarginPercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.MROMarginPercentageId
		 END AS MROMarginPercentageId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.BrokeringMarginPercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.BrokeringMarginPercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.BrokeringMarginPercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.BrokeringMarginPercentageId
		 END AS BrokeringMarginPercentageId,
	CASE WHEN @ActivityTypeId = 1 THEN PSP.ManufacturingMarginPercentageId
		 WHEN @ActivityTypeId = 2 THEN SSP.ManufacturingMarginPercentageId
		 WHEN @ActivityTypeId = 3 THEN AGENT.ManufacturingMarginPercentageId
		 WHEN @ActivityTypeId = 4 THEN CRS.ManufacturingMarginPercentageId
		 END AS ManufacturingMarginPercentageId
	FROM [dbo].[CustomerSales] CS WITH(NOLOCK)
	LEFT JOIN [DBO].[Employee] PSP WITH(NOLOCK) ON PSP.EmployeeId = CS.PrimarySalesPersonId
	LEFT JOIN [DBO].[Employee] SSP WITH(NOLOCK) ON SSP.EmployeeId = CS.SecondarySalesPersonId
	LEFT JOIN [DBO].[Employee] AGENT WITH(NOLOCK) ON AGENT.EmployeeId = CS.SaId
	LEFT JOIN [DBO].[Employee] CRS WITH(NOLOCK) ON SSP.EmployeeId = CS.CsrId
	WHERE CS.CustomerId = @CustomerId;
	END TRY    
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments     VARCHAR(150)    = 'USP_GetSalepersonDetailByCustomerId' 
        ,@ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CustomerId, '') as Varchar(100))  
        ,@ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        exec spLogException 
        @DatabaseName           = @DatabaseName
        ,@AdhocComments          = @AdhocComments
        ,@ProcedureParameters = @ProcedureParameters
        ,@ApplicationName        =  @ApplicationName
        ,@ErrorLogID                    = @ErrorLogID OUTPUT ;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
        RETURN(1);
	END CATCH
END