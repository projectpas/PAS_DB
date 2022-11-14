/*************************************************************           
 ** File:   [GetRepairOrderPartById]           
 ** Author:  Deep Patel
 ** Description: This stored procedure is used to Get Repair Order Part Details
 ** Purpose:         
 ** Date:11/10/2022
 ** PARAMETERS: @RepairOrderId bigint
 ** RETURN VALUE:
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/10/2022  Deep Patel     Created
-- EXEC GetRepairOrderPartById 303
************************************************************************/
CREATE PROCEDURE [dbo].[GetRepairOrderPartById]
@RepairOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	SELECT pop.PartNumber,pop.ItemMasterId,pop.RepairOrderPartRecordId
      FROM [dbo].RepairOrderPart pop WITH (NOLOCK) 		
	  WHERE pop.RepairOrderId = @RepairOrderId and pop.isParent=1 AND pop.IsDeleted = 0 ;

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderPartById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100))			   
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