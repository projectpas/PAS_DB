/*********************           
 ** File:   [GetEmployeeTimeZone]           
 ** Author:  
 ** Description: 
 ** Purpose:         
 ** Date:  28 JAN 2025     
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
	1	28-jan-2025		Ayushi Patel		Created Storeprocedure

--exec GetEmployeeTimeZone @EmployeeId=157
**********************/

CREATE PROCEDURE [dbo].[GetEmployeeTimeZone]
    @EmployeeId bigint                      
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY

		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
    
    SELECT 
        @CurrntEmpTimeZoneDesc = COALESCE(
            ETZ.[Description],  
            LTZ.[Description]   
        )
    FROM 
        dbo.Employee E WITH (NOLOCK)
    LEFT JOIN 
        dbo.TimeZone ETZ WITH (NOLOCK)
        ON E.TimeZoneId = ETZ.TimeZoneId
    LEFT JOIN 
        dbo.LegalEntity LE WITH (NOLOCK)
        ON E.LegalEntityId = LE.LegalEntityId
    LEFT JOIN 
        dbo.TimeZone LTZ WITH (NOLOCK)
        ON LE.TimeZoneId = LTZ.TimeZoneId
    WHERE 
        E.EmployeeId = @EmployeeId; 

		SELECT  @CurrntEmpTimeZoneDesc As CurrntEmpTimeZoneDesc

END TRY

	BEGIN CATCH	

		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetEmployeeTimeZone'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@EmployeeId, '') as Varchar(100))
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);

	END CATCH
END