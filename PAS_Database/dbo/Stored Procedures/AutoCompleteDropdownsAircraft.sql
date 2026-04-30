/*************************************************************           
 ** File:   [AutoCompleteDropdownsAircraft]           
 ** Author:   Amit Ghediya
 ** Description: This SP is used retrieve atachapter list based on part select
 ** Purpose:         
 ** Date:   04/09/2026     
          
 ** RETURN VALUE:           
  
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    04/09/2026   Amit Ghediya		Created
     
--EXEC [AutoCompleteDropdownsAircraft] '',1,20,'0',1,97669
**************************************************************/

CREATE    PROCEDURE [dbo].[AutoCompleteDropdownsAircraft]
	@StartWith VARCHAR(50),
	@IsActive BIT = TRUE,
	@Count VARCHAR(10) = '0',
	@Idlist VARCHAR(MAX) = '0',
	@MasterCompanyId INT,
	@ItemMasterId BIGINT = 0
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	

		SELECT DISTINCT TOP 20 
			   IMAM.ItemMasterAircraftMappingId AS Value, 
			   CONCAT_WS(' - ',
				   NULLIF(IMAM.Level1, ''),
				   NULLIF(IMAM.Level2, ''),
				   NULLIF(IMAM.Level3, '')
			   ) AS Label
		FROM dbo.ItemMasterAircraftMapping IMAM WITH(NOLOCK)
			 WHERE IMAM.MasterCompanyId = @MasterCompanyId AND IMAM.IsActive = 1 AND ISNULL(IMAM.IsDeleted,0) = 0 
			 AND (IMAM.Level1 LIKE @StartWith + '%') AND IMAM.ItemMasterId = @ItemMasterId
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsAircraft'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))		
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END