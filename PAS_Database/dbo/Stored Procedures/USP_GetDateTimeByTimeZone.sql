/*********************           
 ** File:   [USP_GetDateTimeByTimeZone]           
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
	1	28-jan-2025		Ayushi Patel		Created 

--exec [USP_GetDateTimeByTimeZone] @DateTime='2025-01-28 20:57:19', @strTimeZoneName='New Zealand Standard Time'
**********************/

CREATE   PROCEDURE [dbo].[USP_GetDateTimeByTimeZone]
     @DateTime DATETIME,    
     @strTimeZoneName varchar(100)                       
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY

		DECLARE @TimeZoneDate as Datetime, @BaseUtcOffsetSec AS INT    
		SELECT @BaseUtcOffsetSec = BaseUtcOffsetSec FROM  dbo.Timezone WITH (NOLOCK) WHERE Description = @strTimeZoneName    
		select   @TimeZoneDate=DATEADD(SECOND, @BaseUtcOffsetSec, @DateTime) 

		SELECT  @TimeZoneDate As TimeZoneDate

END TRY

	BEGIN CATCH	

		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetDateTimeByTimeZone'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@DateTime, '') as Varchar(100))+'@Parameter2 = ''' + CAST(ISNULL(@strTimeZoneName, '') as Varchar(100))
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