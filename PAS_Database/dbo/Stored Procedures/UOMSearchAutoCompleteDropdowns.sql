
/*************************************************************           
 ** File:   [UOMSearchAutoCompleteDropdowns]
 ** Author:   
 ** Description: This stored procedure is used to get UOM search data
 ** Purpose:         
 ** Date:    
          
 ** PARAMETERS: 
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			-------------------------------          
    1	 11/18/2025   Vishal Suthar		Created
    2	 08 DEC 2025  Rajesh Gami		Added DecimalPlaces 
EXEC [dbo].[UOMSearchAutoCompleteDropdowns] 1
************************************************************************/
CREATE   PROCEDURE [dbo].[UOMSearchAutoCompleteDropdowns]
  @MasterCompanyId INT = 1
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
		BEGIN
			DROP TABLE #TempTable 
		END
		CREATE TABLE #TempTable(      
					UOMId BIGINT,      
					[Description] VARCHAR(MAX),
					ShortName VARCHAR(Max),
					Class VARCHAR(MAX),DecimalPlaces INT)
					     

		IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
		BEGIN
			DROP TABLE #Result 
		END

		CREATE TABLE #Result(      
						UOMId BIGINT,      
						[Description] VARCHAR(MAX),
						ShortName VARCHAR(MAX),
						Class VARCHAR(MAX),DecimalPlaces INT)
	
		INSERT INTO #TempTable (UOMId, [Description],ShortName, Class,DecimalPlaces)
		SELECT DISTINCT 
			uom.UnitOfMeasureId AS UOMId,
			uom.Description AS Description,
			uom.ShortName AS ShortName,
			ISNULL(uom.Class,'Decimal') AS Class,
			ISNULL(uom.DecimalPlaces,2) AS DecimalPlaces
			FROM DBO.UnitOfMeasure uom WITH(NOLOCK)			
			WHERE ISNULL(uom.IsActive,0) = 1
			AND ISNULL(uom.IsDeleted,0) = 0
			AND uom.MasterCompanyId = @MasterCompanyId

		INSERT INTO #Result 
				SELECT 
				DISTINCT TOP 50 * 
				FROM #TempTable t
				ORDER BY t.ShortName

		SELECT DISTINCT TOP 50 r.UOMId,
			r.Description,
			r.ShortName,
			r.Class,
			r.DecimalPlaces
			FROM #Result r

		DROP Table #TempTable 
		DROP Table #Result
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UOMSearchAutoCompleteDropdowns' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter10 = ' + ISNULL(@MasterCompanyId,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END